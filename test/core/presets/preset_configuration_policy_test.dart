import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/presets/preset.dart';
import 'package:pocketools/core/presets/preset_capabilities.dart';
import 'package:pocketools/core/presets/preset_configuration_policy.dart';
import 'package:pocketools/core/presets/preset_controller.dart';
import 'package:pocketools/core/presets/preset_id_source.dart';
import 'package:pocketools/core/presets/preset_repository.dart';
import 'package:pocketools/core/session/local_string_store.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';

void main() {
  test('registry rejects case, separator, and CJK sensitive keys', () {
    for (final key in <String>[
      'Private_Note',
      'PROMPT',
      'question-text',
      'session id',
      '父会话标识',
      '私密备注',
      '会话ID',
      'randomSeed',
      'random_seed',
      'random-seed',
      'random seed',
      'timestamp',
      'createdAt',
      'created_at',
      'created-at',
      'created at',
      'updatedAt',
      'updated_at',
      'updated-at',
      'updated at',
      'history',
    ]) {
      expect(
        () => ToolRegistry(<ToolModule>[_PolicyModule(key: key)]),
        throwsArgumentError,
        reason: key,
      );
    }
  });

  test('registry recursively reviews maps and lists', () {
    expect(
      () => ToolRegistry(<ToolModule>[
        _PolicyModule(
          value: <String, Object?>{
            'rules': <Object?>[
              <String, Object?>{'diceSides': 20},
              <Object?>[
                true,
                null,
                <String, Object?>{'headsLabel': 'H'},
              ],
            ],
          },
        ),
      ]),
      returnsNormally,
    );
    expect(
      () => ToolRegistry(<ToolModule>[
        _PolicyModule(
          value: <String, Object?>{
            'rules': <Object?>[
              <String, Object?>{'nested_session_id': 'secret'},
            ],
          },
        ),
      ]),
      throwsArgumentError,
    );
  });

  test('registry rejects oversized, deep, control, and non-finite values', () {
    Object deep = 'leaf';
    for (var index = 0; index < 20; index++) {
      deep = <String, Object?>{'level': deep};
    }

    for (final value in <Object?>[
      'x' * 10000,
      deep,
      List<Object?>.generate(400, (index) => index),
      'line\nfeed',
      double.infinity,
      <String, Object?>{
        'unsupportedSet': <Object?>{1, 2},
      },
    ]) {
      expect(
        () => ToolRegistry(<ToolModule>[_PolicyModule(value: value)]),
        throwsArgumentError,
      );
    }
  });

  test('registry keeps legal key boundaries and CJK rule labels', () {
    expect(
      () => ToolRegistry(<ToolModule>[
        _PolicyModule(
          value: <String, Object?>{
            'diceSides': 20,
            'useReversals': true,
            'headsLabel': '正面',
            'candidate': 'safe',
            'video': 'safe',
            'seededValue': 1,
            'timestamped': true,
            'createdValue': 'safe',
            'updatedValue': 'safe',
            '点数': 20,
          },
        ),
      ]),
      returnsNormally,
    );
  });

  test('compact sensitive sequences require complete token boundaries', () {
    for (final key in <String>[
      'sessionid',
      'parentsessionid',
      'privatenote',
      'deviceid',
      'analyticsid',
      'historyid',
      'questiontext',
      'intentiontext',
      'resultvalue',
    ]) {
      expect(
        () => ToolPresetConfigurationPolicy.validate(<String, Object?>{
          key: 'secret',
        }),
        throwsA(isA<PresetConfigurationException>()),
        reason: key,
      );
    }

    for (final key in <String>[
      'diceSides',
      'candidate',
      'video',
      'seededValue',
      'createdValue',
      'value',
    ]) {
      expect(
        () => ToolPresetConfigurationPolicy.validate(<String, Object?>{
          key: 'safe',
        }),
        returnsNormally,
        reason: key,
      );
    }
  });

  test(
    'user pollution is isolated and preserved across a later copy',
    () async {
      final module = _PolicyModule(value: const <String, Object?>{'value': 7});
      final system = module.systemPresets.single;
      final polluted = ToolPreset(
        id: 'polluted',
        toolId: system.toolId,
        displayName: '污染记录',
        ruleVersion: system.ruleVersion,
        type: PresetType.user,
        source: PresetSource.local,
        configuration: const <String, Object?>{
          'value': 7,
          'privateNote': 'must stay isolated',
        },
      );
      final legal = system.asUserCopy(newId: 'legal', newName: '合法记录');
      final repository = InMemoryPresetRepository(<ToolPreset>[
        polluted,
        legal,
      ]);
      final warnings = <String>[];
      final controller = PresetController(
        registry: ToolRegistry(<ToolModule>[module]),
        repository: repository,
        idSource: _FixedIdSource(),
        onWarning: warnings.add,
      );

      await controller.load();
      final copy = await controller.copyAsUser(
        controller.userPresets.single,
        displayName: '再次复制',
      );

      expect(controller.userPresets.map((preset) => preset.id), <String>[
        legal.id,
        copy.id,
      ]);
      expect(warnings, hasLength(1));
      expect(warnings.single, contains('隔离'));
      expect(repository.values.map((preset) => preset.id), <String>[
        legal.id,
        copy.id,
        polluted.id,
      ]);
    },
  );

  test(
    'copy rejects a polluted source before creating a local record',
    () async {
      final module = _PolicyModule();
      final polluted = ToolPreset(
        id: 'polluted-source',
        toolId: module.toolId,
        displayName: '污染来源',
        ruleVersion: 'policy/1',
        type: PresetType.system,
        source: PresetSource.bundled,
        configuration: const <String, Object?>{
          'value': 7,
          'sessionId': 'secret',
        },
      );
      final controller = PresetController(
        registry: ToolRegistry(<ToolModule>[module]),
        repository: InMemoryPresetRepository(),
        idSource: _FixedIdSource(),
      );

      await expectLater(
        controller.copyAsUser(polluted, displayName: '副本'),
        throwsArgumentError,
      );
    },
  );

  test(
    'persistent repository rejects unsafe direct saves atomically',
    () async {
      final backend = MemoryLocalStringStore();
      final repository = PersistentPresetRepository(store: backend);
      final unsafe = ToolPreset(
        id: 'unsafe-direct',
        toolId: 'test',
        displayName: '不安全直写',
        ruleVersion: 'test/1',
        type: PresetType.user,
        source: PresetSource.local,
        configuration: const <String, Object?>{
          'value': 7,
          'parent_session_id': 'secret',
        },
      );

      await expectLater(
        repository.saveAll(<ToolPreset>[unsafe]),
        throwsA(isA<PresetStorageException>()),
      );
      expect(backend.values, isEmpty);
    },
  );
}

final class _PolicyModule implements ToolModule, ToolPresetProvider {
  _PolicyModule({this.key, Object? value})
    : _value = value ?? const <String, Object?>{'value': 7},
      descriptor = ToolDescriptor(
        id: 'policy-${_nextId++}',
        name: 'Policy test',
        description: 'Preset policy test module',
        route: '/tools/policy-$_nextId',
        icon: Icons.extension_outlined,
        accent: ToolAccent.neutral,
      );

  static var _nextId = 0;

  final String? key;
  final Object _value;
  @override
  final ToolDescriptor descriptor;

  @override
  ToolSessionCodec get sessionCodec => _PolicyCodec(descriptor.id);

  @override
  String get toolId => descriptor.id;

  @override
  List<ToolPreset> get systemPresets => <ToolPreset>[
    ToolPreset(
      id: '${descriptor.id}.default',
      toolId: descriptor.id,
      displayName: '测试预设',
      ruleVersion: 'policy/1',
      type: PresetType.system,
      source: PresetSource.bundled,
      configuration: key == null
          ? _value is Map<String, Object?>
                ? _value
                : <String, Object?>{'payload': _value}
          : <String, Object?>{'value': 7, key!: 'secret'},
    ),
  ];

  @override
  Object decodePresetConfiguration(Map<String, Object?> configuration) =>
      configuration;

  @override
  Map<String, Object?> encodePresetConfiguration(Object configuration) =>
      <String, Object?>{'value': configuration};

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      const SizedBox.shrink();
}

final class _PolicyCodec implements ToolSessionCodec {
  const _PolicyCodec(this.toolId);

  @override
  final String toolId;

  @override
  Object decodeInput(Map<String, Object?> input) => input;

  @override
  Object decodeOutcome(Map<String, Object?> outcome, Object input) => outcome;

  @override
  Map<String, Object?> encodeInput(Object input) => <String, Object?>{};

  @override
  Map<String, Object?> encodeOutcome(Object outcome) => <String, Object?>{};

  @override
  String summarize(SessionRecord session) => 'policy';
}

final class _FixedIdSource implements PresetIdSource {
  var _index = 0;

  @override
  String next() => 'copy-${_index++}';
}
