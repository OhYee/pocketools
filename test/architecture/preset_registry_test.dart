import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/presets/preset.dart';
import 'package:pocketools/core/presets/preset_capabilities.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';

void main() {
  test(
    'a fake preset provider is aggregated without management-page branches',
    () {
      final registry = ToolRegistry(<ToolModule>[_FakePresetModule()]);
      final preset = registry.systemPresets.single;
      final request = registry.launchRequestForPreset(preset);

      expect(registry.presetProviders, hasLength(1));
      expect(preset.toolId, 'fake');
      expect(request.toolId, 'fake');
      expect(request.initialConfig, const _FakeConfig(value: 7));
      expect(() => registry.systemPresets.clear(), throwsUnsupportedError);

      final source = File('lib/app/presentation/preset_management_page.dart')
          .readAsStringSync();
      for (final toolId in <String>[
        'tarot',
        'liuyao',
        'd20',
        'coin',
        'cards',
      ]) {
        expect(source, isNot(contains("'$toolId'")), reason: toolId);
      }
    },
  );

  test('registry rejects invalid system preset metadata and configuration', () {
    final cases = <_ConfigurablePresetModule>[
      _ConfigurablePresetModule(
        id: 'wrong-kind',
        presets: <ToolPreset>[
          _preset(
            id: 'wrong-kind.default',
            toolId: 'wrong-kind',
            type: PresetType.user,
            source: PresetSource.local,
          ),
        ],
      ),
      _ConfigurablePresetModule(
        id: 'wrong-tool',
        presets: <ToolPreset>[
          _preset(id: 'wrong-tool.default', toolId: 'another-tool'),
        ],
      ),
      _ConfigurablePresetModule(
        id: 'invalid-metadata',
        presets: <ToolPreset>[
          _preset(
            id: 'invalid-metadata.default',
            toolId: 'invalid-metadata',
            displayName: 'bad\u0000name',
          ),
        ],
      ),
      _ConfigurablePresetModule(
        id: 'malformed-config',
        presets: <ToolPreset>[
          _preset(
            id: 'malformed-config.default',
            toolId: 'malformed-config',
            value: 'not-an-int',
          ),
        ],
      ),
    ];

    for (final module in cases) {
      expect(
        () => ToolRegistry(<ToolModule>[module]),
        throwsArgumentError,
        reason: module.descriptor.id,
      );
    }
  });

  test('registry rejects globally duplicate system preset IDs', () {
    expect(
      () => ToolRegistry(<ToolModule>[
        _ConfigurablePresetModule(
          id: 'first',
          presets: <ToolPreset>[_preset(id: 'shared.default', toolId: 'first')],
        ),
        _ConfigurablePresetModule(
          id: 'second',
          presets: <ToolPreset>[
            _preset(id: 'shared.default', toolId: 'second'),
          ],
        ),
      ]),
      throwsArgumentError,
    );
  });

  test('registry snapshots provider presets at construction', () {
    final module = _ConfigurablePresetModule(
      id: 'snapshot',
      presets: <ToolPreset>[
        _preset(id: 'snapshot.default', toolId: 'snapshot'),
      ],
    );
    final registry = ToolRegistry(<ToolModule>[module]);

    module.presets.add(
      _preset(id: 'snapshot.late', toolId: 'snapshot', value: 8),
    );

    expect(registry.systemPresets, hasLength(1));
    expect(registry.systemPresets.single.id, 'snapshot.default');
  });

  test('preset tiles receive explicit action callbacks', () {
    final source = File('lib/app/presentation/preset_management_page.dart')
        .readAsStringSync();

    expect(source, isNot(contains('findAncestorStateOfType')));
    for (final callback in <String>['onCopy', 'onRename', 'onDelete']) {
      expect(source, contains('required this.$callback'), reason: callback);
    }
  });
}

ToolPreset _preset({
  required String id,
  required String toolId,
  String displayName = 'Fake 默认',
  Object value = 7,
  PresetType type = PresetType.system,
  PresetSource source = PresetSource.bundled,
}) => ToolPreset(
  id: id,
  toolId: toolId,
  displayName: displayName,
  ruleVersion: 'fake/1.0.0',
  type: type,
  source: source,
  configuration: <String, Object?>{'value': value},
);

final class _FakeConfig {
  const _FakeConfig({required this.value});

  final int value;

  @override
  bool operator ==(Object other) =>
      other is _FakeConfig && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

final class _FakePresetModule implements ToolModule, ToolPresetProvider {
  static const _descriptor = ToolDescriptor(
    id: 'fake',
    name: 'Fake 工具',
    description: '能力注册测试工具',
    route: '/tools/fake',
    icon: Icons.extension_outlined,
    accent: ToolAccent.neutral,
  );

  static final _preset = ToolPreset(
    id: 'fake.default',
    toolId: 'fake',
    displayName: 'Fake 默认',
    ruleVersion: 'fake/1.0.0',
    type: PresetType.system,
    source: PresetSource.bundled,
    configuration: const <String, Object?>{'value': 7},
  );

  @override
  ToolDescriptor get descriptor => _descriptor;

  @override
  ToolSessionCodec get sessionCodec => const _FakeCodec();

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      const SizedBox.shrink();

  @override
  String get toolId => descriptor.id;

  @override
  List<ToolPreset> get systemPresets => <ToolPreset>[_preset];

  @override
  Object decodePresetConfiguration(Map<String, Object?> configuration) =>
      _FakeConfig(value: configuration['value']! as int);

  @override
  Map<String, Object?> encodePresetConfiguration(Object configuration) =>
      <String, Object?>{'value': (configuration as _FakeConfig).value};
}

final class _FakeCodec implements ToolSessionCodec {
  const _FakeCodec();

  @override
  String get toolId => 'fake';

  @override
  Map<String, Object?> encodeInput(Object input) => <String, Object?>{};

  @override
  Object decodeInput(Map<String, Object?> input) => const _FakeConfig(value: 0);

  @override
  Map<String, Object?> encodeOutcome(Object outcome) => <String, Object?>{};

  @override
  Object decodeOutcome(Map<String, Object?> outcome, Object input) =>
      const _FakeConfig(value: 0);

  @override
  String summarize(SessionRecord session) => 'fake';
}

final class _ConfigurablePresetModule
    implements ToolModule, ToolPresetProvider {
  _ConfigurablePresetModule({required String id, required this.presets})
    : descriptor = ToolDescriptor(
        id: id,
        name: 'Fake $id',
        description: '可配置预设能力测试工具',
        route: '/tools/$id',
        icon: Icons.extension_outlined,
        accent: ToolAccent.neutral,
      ),
      _codec = _ConfigurableCodec(id);

  @override
  final ToolDescriptor descriptor;

  final _ConfigurableCodec _codec;
  final List<ToolPreset> presets;

  @override
  ToolSessionCodec get sessionCodec => _codec;

  @override
  String get toolId => descriptor.id;

  @override
  List<ToolPreset> get systemPresets => presets;

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      const SizedBox.shrink();

  @override
  Object decodePresetConfiguration(Map<String, Object?> configuration) {
    if (configuration.length != 1 || configuration['value'] is! int) {
      throw const PresetConfigurationException('Fake 预设配置无效。');
    }
    return _FakeConfig(value: configuration['value']! as int);
  }

  @override
  Map<String, Object?> encodePresetConfiguration(Object configuration) =>
      <String, Object?>{'value': (configuration as _FakeConfig).value};
}

final class _ConfigurableCodec implements ToolSessionCodec {
  const _ConfigurableCodec(this.toolId);

  @override
  final String toolId;

  @override
  Map<String, Object?> encodeInput(Object input) => <String, Object?>{};

  @override
  Object decodeInput(Map<String, Object?> input) => const _FakeConfig(value: 0);

  @override
  Map<String, Object?> encodeOutcome(Object outcome) => <String, Object?>{};

  @override
  Object decodeOutcome(Map<String, Object?> outcome, Object input) =>
      const _FakeConfig(value: 0);

  @override
  String summarize(SessionRecord session) => 'fake';
}
