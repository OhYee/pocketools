import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/registry/default_tool_registry.dart';
import 'package:pocketools/core/presets/preset.dart';
import 'package:pocketools/core/presets/preset_capabilities.dart';
import 'package:pocketools/core/presets/preset_configuration_policy.dart';
import 'package:pocketools/core/presets/preset_controller.dart';
import 'package:pocketools/core/presets/preset_id_source.dart';
import 'package:pocketools/core/presets/preset_repository.dart';
import 'package:pocketools/core/session/local_string_store.dart';
import 'package:pocketools/features/dice/domain/dice_models.dart';

void main() {
  group('independent preset policy attacks', () {
    test('display names use trimmed Unicode scalar and control boundaries', () {
      expect(ToolPreset.validateDisplayName('   '), isNotNull);
      expect(ToolPreset.validateDisplayName('  骰子 🎲  '), isNull);
      expect(ToolPreset.validateDisplayName('valid\u0000name'), isNotNull);
      expect(ToolPreset.validateDisplayName('🎲' * 80), isNull);
      expect(ToolPreset.validateDisplayName('🎲' * 81), isNotNull);
    });

    test('lowercase concatenated private field aliases are rejected', () {
      final accepted = <String>[];
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
        try {
          ToolPresetConfigurationPolicy.validate(<String, Object?>{
            'value': 7,
            key: 'secret',
          });
          accepted.add(key);
        } on PresetConfigurationException {
          // Expected fail-closed outcome.
        }
      }
      expect(accepted, isEmpty, reason: 'accepted private aliases: $accepted');
    });

    test('copy rejects a safe-key configuration the provider cannot decode', () async {
      final repository = InMemoryPresetRepository();
      final ids = _FixedPresetIdSource();
      final registry = buildDefaultToolRegistry();
      final controller = PresetController(
        registry: registry,
        repository: repository,
        idSource: ids,
      );
      final malformed = ToolPreset(
        id: 'external-malformed-d20',
        toolId: 'd20',
        displayName: 'Malformed D20',
        ruleVersion: 'dice/1.0.0',
        type: PresetType.system,
        source: PresetSource.bundled,
        configuration: const <String, Object?>{
          'diceCount': 2,
          'diceSides': 20,
          'aggregation': 'keepHighest',
          'keepCount': 3,
          'modifier': 0,
        },
      );

      ToolPreset? emitted;
      Object? rejection;
      try {
        emitted = await controller.copyAsUser(
          malformed,
          displayName: 'Should not persist',
        );
      } on Object catch (error) {
        rejection = error;
      }
      expect(
        rejection,
        isA<ArgumentError>(),
        reason:
            'accepted=${emitted?.id}, saved=${repository.values.map((value) => value.id).toList()}, ids=${ids.consumed}',
      );
      expect(repository.values, isEmpty);
      expect(ids.consumed, 0);
    });

    for (final fixture in <String, String>{
      'corrupt': '{corrupt-preset-marker',
      'unknown-version': jsonEncode(<String, Object?>{
        'storageSchemaVersion': 99,
        'documents': <Object?>[
          <String, Object?>{'unknown-preset-marker': true},
        ],
      }),
    }.entries) {
      test('${fixture.key} snapshot survives a later legal copy', () async {
        final raw = fixture.value;
        final backend = MemoryLocalStringStore(<String, String>{
          PersistentPresetRepository.activeStorageKey: raw,
        });
        final controller = PresetController(
          registry: buildDefaultToolRegistry(),
          repository: PersistentPresetRepository(store: backend),
          idSource: _FixedPresetIdSource(),
        );
        await controller.load();
        final system = controller.systemPresets.firstWhere(
          (preset) => preset.id == 'd20.normal',
        );

        await controller.copyAsUser(
          system,
          displayName: 'Legal copy ${fixture.key}',
        );

        expect(
          backend.values.values,
          contains(raw),
          reason: 'raw ${fixture.key} snapshot must remain recoverable',
        );
      });
    }

    test('pending snapshot never replaces the active user preset', () async {
      final backend = MemoryLocalStringStore();
      final active = _userPreset('active-user', 'Active');
      await PersistentPresetRepository(store: backend)
          .saveAll(<ToolPreset>[active]);
      final activeRaw =
          backend.values[PersistentPresetRepository.activeStorageKey]!;
      final pendingRaw = jsonEncode(<String, Object?>{
        'storageSchemaVersion': 1,
        'documents': <Object?>[
          _presetDocument(_userPreset('pending-user', 'Pending')),
        ],
      });
      await backend.writeString(
        PersistentPresetRepository.pendingStorageKey,
        pendingRaw,
      );

      final result = await PersistentPresetRepository(store: backend).load();

      expect(result.presets.map((preset) => preset.id), <String>[active.id]);
      expect(result.issue?.code, PresetLoadIssueCode.pendingSnapshotIgnored);
      expect(
        backend.values[PersistentPresetRepository.activeStorageKey],
        activeRaw,
      );
      expect(
        backend.values[PersistentPresetRepository.pendingStorageKey],
        pendingRaw,
      );
    });

    test(
      'write failure falls back to transient presets with one warning',
      () async {
        final warnings = <String>[];
        final transient = InMemoryPresetRepository();
        final resilient = ResilientPresetRepository(
          persistentRepository: PersistentPresetRepository(
            store: _WriteFailingStore(),
          ),
          transientRepository: transient,
          onWarning: warnings.add,
        );
        await resilient.load();
        final preset = _userPreset('transient-user', 'Transient');

        await resilient.saveAll(<ToolPreset>[preset]);

        expect(transient.values.map((value) => value.id), <String>[preset.id]);
        expect(warnings, hasLength(1));
        expect(warnings.single, contains('当前会话'));
      },
    );

    test('D20 provider codec rejects exact-key but invalid configurations', () {
      final registry = buildDefaultToolRegistry();
      final base = registry.systemPresets.firstWhere(
        (preset) => preset.id == 'd20.normal',
      );
      final cases = <Map<String, Object?>>[
        <String, Object?>{
          'diceCount': 0,
          'diceSides': 20,
          'aggregation': 'sum',
          'keepCount': null,
          'modifier': 0,
        },
        <String, Object?>{
          'diceCount': 2,
          'diceSides': 20,
          'aggregation': 'keepHighest',
          'keepCount': 3,
          'modifier': 0,
        },
        <String, Object?>{
          'diceCount': 1,
          'diceSides': 20,
          'aggregation': 'sum',
          'keepCount': null,
          'modifier': 10000,
        },
        <String, Object?>{
          'diceCount': 1,
          'diceSides': 20,
          'aggregation': 'unknown',
          'keepCount': null,
          'modifier': 0,
        },
      ];

      for (var index = 0; index < cases.length; index++) {
        final preset = ToolPreset(
          id: 'invalid-d20-$index',
          toolId: base.toolId,
          displayName: 'Invalid $index',
          ruleVersion: base.ruleVersion,
          type: PresetType.user,
          source: PresetSource.local,
          configuration: cases[index],
        );
        expect(
          () => registry.launchRequestForPreset(preset),
          throwsA(anything),
          reason: '$index',
        );
      }
    });

    test(
      'frozen copy rename and delete never mutate the system definition',
      () async {
        final repository = InMemoryPresetRepository();
        final controller = PresetController(
          registry: buildDefaultToolRegistry(),
          repository: repository,
          idSource: _FixedPresetIdSource(),
        );
        final system = controller.systemPresets.firstWhere(
          (preset) => preset.id == 'd20.advantage',
        );
        final originalConfiguration = Map<String, Object?>.of(
          system.configuration,
        );

        final copy = await controller.copyAsUser(
          system,
          displayName: ' Advantage copy ',
        );
        final request = controller.launchRequestFor(copy);
        final draft = request.initialConfig! as DicePoolConfig;
        expect(draft.mode, DiceMode.advantage);
        final renamed = await controller.renameUser(
          copy.id,
          displayName: 'Renamed copy',
        );

        expect(renamed.configuration, originalConfiguration);
        expect(system.configuration, originalConfiguration);
        expect(system.displayName, '优势');
        await controller.deleteUser(copy.id);
        expect(controller.userPresets, isEmpty);
        expect(controller.systemPresets, contains(same(system)));
      },
    );
  });
}

ToolPreset _userPreset(String id, String name) => ToolPreset(
  id: id,
  toolId: 'd20',
  displayName: name,
  ruleVersion: 'dice/1.0.0',
  type: PresetType.user,
  source: PresetSource.local,
  configuration: const <String, Object?>{
    'diceCount': 1,
    'diceSides': 20,
    'aggregation': 'sum',
    'keepCount': null,
    'modifier': 0,
  },
);

Map<String, Object?> _presetDocument(ToolPreset preset) => <String, Object?>{
  'presetSchemaVersion': preset.schemaVersion,
  'id': preset.id,
  'toolId': preset.toolId,
  'displayName': preset.displayName,
  'ruleVersion': preset.ruleVersion,
  'type': preset.type.name,
  'source': preset.source.name,
  'configuration': preset.configuration,
};

final class _FixedPresetIdSource implements PresetIdSource {
  var consumed = 0;

  @override
  String next() => 'qa-preset-${++consumed}';
}

final class _WriteFailingStore implements LocalStringStore {
  @override
  Future<void> clearOwned(Set<String> allowList) async {}

  @override
  Future<String?> readString(String key) async => null;

  @override
  Future<void> remove(String key) async {}

  @override
  Future<void> writeString(String key, String value) =>
      Future<void>.error(StateError('write blocked'));
}
