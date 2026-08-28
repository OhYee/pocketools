import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/registry/default_tool_registry.dart';
import 'package:pocketools/core/presets/preset.dart';
import 'package:pocketools/core/presets/preset_controller.dart';
import 'package:pocketools/core/presets/preset_id_source.dart';
import 'package:pocketools/core/presets/preset_repository.dart';
import 'package:pocketools/core/session/local_string_store.dart';
import 'package:pocketools/core/session/persistent_session_repository.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/features/coin/domain/coin_models.dart';
import 'package:pocketools/features/dice/domain/dice_models.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';

void main() {
  test(
    'system and user presets stay isolated across copy and rename',
    () async {
      final controller = _controller();
      await controller.load();
      final system = controller.systemPresets.firstWhere(
        (preset) => preset.id == 'tarot.daily-card',
      );

      final copy = await controller.copyAsUser(system, displayName: '我的今日一牌');
      final renamed = await controller.renameUser(
        copy.id,
        displayName: '我的每日反思',
      );

      expect(system.type, PresetType.system);
      expect(system.source, PresetSource.bundled);
      expect(system.displayName, '今日一牌');
      expect(copy.type, PresetType.user);
      expect(copy.source, PresetSource.local);
      expect(copy.id, isNot(system.id));
      expect(copy.configuration, isNot(same(system.configuration)));
      expect(renamed.id, copy.id);
      expect(renamed.displayName, '我的每日反思');
      expect(
        controller.systemPresets
            .firstWhere((preset) => preset.id == system.id)
            .displayName,
        '今日一牌',
      );
    },
  );

  test(
    'only user presets can be deleted and history remains independent',
    () async {
      final backend = MemoryLocalStringStore();
      final history = PersistentSessionRepository(store: backend);
      final session = SessionRecord(
        id: 'history-1',
        toolId: 'd20',
        schemaVersion: 1,
        ruleVersion: 'dice/1.0.0',
        algorithmVersion: 'random-unbiased-u32/1',
        status: SessionStatus.completed,
        input: const <String, Object?>{
          'diceCount': 1,
          'diceSides': 20,
          'aggregation': 'sum',
          'modifier': 0,
        },
        outcome: const <String, Object?>{'total': 7},
      );
      await history.save(session);

      final controller = _controller(repository: InMemoryPresetRepository());
      final system = controller.systemPresets.firstWhere(
        (preset) => preset.id == 'd20.normal',
      );
      final copy = await controller.copyAsUser(system, displayName: '自定义普通');

      await expectLater(controller.deleteUser(system.id), throwsArgumentError);
      await controller.deleteUser(copy.id);

      expect(await history.findById(session.id), same(session));
      expect(controller.userPresets, isEmpty);
    },
  );

  test(
    'persistent presets restore with schema and deep-freeze validation',
    () async {
      final backend = MemoryLocalStringStore();
      final first = PersistentPresetRepository(store: backend);
      final source = _controller().systemPresets.first;
      final user = source.asUserCopy(newId: 'preset-user-1', newName: '本地副本');

      await first.saveAll(<ToolPreset>[user]);
      final second = PersistentPresetRepository(store: backend);
      final result = await second.load();

      expect(result.issue, isNull);
      expect(result.presets, hasLength(1));
      expect(result.presets.single.id, 'preset-user-1');
      expect(result.presets.single.ruleVersion, source.ruleVersion);
      expect(
        () => result.presets.single.configuration['spread'] = 'changed',
        throwsUnsupportedError,
      );
    },
  );

  test(
    'corrupt preset storage is isolated without blocking system presets',
    () async {
      final backend = MemoryLocalStringStore(<String, String>{
        PersistentPresetRepository.activeStorageKey: '{',
      });
      final repository = PersistentPresetRepository(store: backend);
      final result = await repository.load();

      expect(result.presets, isEmpty);
      expect(result.issue?.code, PresetLoadIssueCode.corruptJson);
      expect(_controller(repository: repository).systemPresets, isNotEmpty);
    },
  );

  test(
    'quarantine raw active data survives a legal write and reload',
    () async {
      const raw = '{corrupt-preset-for-reload';
      final backend = MemoryLocalStringStore(<String, String>{
        PersistentPresetRepository.activeStorageKey: raw,
      });
      final repository = PersistentPresetRepository(store: backend);
      await repository.load();
      final source = _controller().systemPresets.first;
      final user = source.asUserCopy(
        newId: 'quarantined-copy',
        newName: '保全副本',
      );

      await repository.saveAll(<ToolPreset>[user]);

      expect(
        PersistentPresetRepository.ownedKeys,
        contains(PersistentPresetRepository.quarantineStorageKey),
      );
      expect(
        backend.values[PersistentPresetRepository.quarantineStorageKey],
        raw,
      );
      expect(backend.values.values, contains(raw));

      final reloaded = PersistentPresetRepository(store: backend);
      final result = await reloaded.load();
      expect(result.issue, isNull);
      expect(result.presets.single.id, user.id);
      expect(
        backend.values[PersistentPresetRepository.quarantineStorageKey],
        raw,
      );
    },
  );

  test(
    'quarantine write precedes active write and preserves failed state',
    () async {
      const raw = '{corrupt-preset-for-atomicity';
      final backend = _ActiveWriteFailingStore(<String, String>{
        PersistentPresetRepository.activeStorageKey: raw,
      });
      final repository = PersistentPresetRepository(store: backend);
      await repository.load();
      final source = _controller().systemPresets.first;
      final user = source.asUserCopy(newId: 'failed-copy', newName: '失败副本');

      await expectLater(
        repository.saveAll(<ToolPreset>[user]),
        throwsA(
          isA<PresetStorageException>().having(
            (error) => error.code,
            'code',
            'write_failed',
          ),
        ),
      );

      expect(backend.values[PersistentPresetRepository.activeStorageKey], raw);
      expect(
        backend.values[PersistentPresetRepository.quarantineStorageKey],
        raw,
      );
      expect(
        backend.values[PersistentPresetRepository.pendingStorageKey],
        isNotNull,
      );
      expect((await repository.load()).presets, isEmpty);
    },
  );

  test('load isolates unknown and malformed provider configurations with one warning', () async {
    final warnings = <String>[];
    final d20System = _controller().systemPresets.firstWhere(
      (preset) => preset.id == 'd20.normal',
    );
    final controller = _controller(
      repository: InMemoryPresetRepository(<ToolPreset>[
        ToolPreset(
          id: 'user-unknown-tool',
          toolId: 'unknown-tool',
          displayName: '未知工具预设',
          ruleVersion: 'unknown/1',
          type: PresetType.user,
          source: PresetSource.local,
          configuration: const <String, Object?>{'value': 1},
        ),
        ToolPreset(
          id: 'user-malformed-d20',
          toolId: 'd20',
          displayName: '损坏的 D20 预设',
          ruleVersion: d20System.ruleVersion,
          type: PresetType.user,
          source: PresetSource.local,
          configuration: const <String, Object?>{'diceCount': 1},
        ),
      ]),
      onWarning: warnings.add,
    );

    await controller.load();
    await controller.load();

    expect(controller.userPresets, isEmpty);
    expect(warnings, hasLength(1));
    expect(warnings.single, contains('隔离'));
  });

  test('a new system ID quarantines only its collision and preserves the raw record', () async {
    final backend = MemoryLocalStringStore();
    final system = _controller().systemPresets.firstWhere(
      (preset) => preset.id == 'd20.normal',
    );
    final collision = system.asUserCopy(
      newId: system.id,
      newName: '升级前的同名用户预设',
    );
    final legal = system.asUserCopy(
      newId: 'user-d20-preserved',
      newName: '应保留的用户副本',
    );
    await PersistentPresetRepository(store: backend)
        .saveAll(<ToolPreset>[collision, legal]);
    final originalActive =
        backend.values[PersistentPresetRepository.activeStorageKey];
    final warnings = <String>[];
    final controller = _controller(
      repository: PersistentPresetRepository(store: backend),
      onWarning: warnings.add,
    );

    await controller.load();

    expect(controller.userPresets.map((preset) => preset.id), <String>[
      legal.id,
    ]);
    expect(warnings, hasLength(1));
    expect(
      backend.values[PersistentPresetRepository.activeStorageKey],
      originalActive,
    );

    await controller.renameUser(legal.id, displayName: '升级后仍可修改');
    final persisted = await PersistentPresetRepository(store: backend).load();
    expect(persisted.presets.map((preset) => preset.id).toSet(), <String>{
      collision.id,
      legal.id,
    });
    expect(
      persisted.presets
          .firstWhere((preset) => preset.id == legal.id)
          .displayName,
      '升级后仍可修改',
    );
  });

  test(
    'unavailable storage falls back to an offline in-memory repository',
    () async {
      final warnings = <String>[];
      final fallback = InMemoryPresetRepository();
      final resilient = ResilientPresetRepository(
        persistentRepository: PersistentPresetRepository(
          store: _FailingStore(),
        ),
        transientRepository: fallback,
        onWarning: warnings.add,
      );
      final system = _controller().systemPresets.first;
      final user = system.asUserCopy(newId: 'preset-fallback', newName: '离线副本');

      final loaded = await resilient.load();
      await resilient.saveAll(<ToolPreset>[user]);

      expect(loaded.presets, isEmpty);
      expect(fallback.values.single.id, user.id);
      expect(warnings, isNotEmpty);
    },
  );

  test(
    'three first-party providers apply through the unified launch request',
    () {
      final registry = buildDefaultToolRegistry();

      final tarot = registry.systemPresets.firstWhere(
        (preset) => preset.id == 'tarot.past-present-future',
      );
      final dice = registry.systemPresets.firstWhere(
        (preset) => preset.id == 'd20.advantage',
      );
      final coin = registry.systemPresets.firstWhere(
        (preset) => preset.id == 'coin.batch-5',
      );

      final tarotConfig = registry.launchRequestForPreset(tarot).initialConfig;
      final diceConfig = registry.launchRequestForPreset(dice).initialConfig;
      final coinConfig = registry.launchRequestForPreset(coin).initialConfig;

      expect(tarotConfig, isA<TarotReadingConfig>());
      expect((tarotConfig! as TarotReadingConfig).intention, isNull);
      expect((diceConfig! as DicePoolConfig).mode, DiceMode.advantage);
      expect((coinConfig! as CoinTossConfig).batchCount, 5);
    },
  );
}

PresetController _controller({
  PresetRepository? repository,
  PresetWarningSink? onWarning,
}) => PresetController(
  registry: buildDefaultToolRegistry(),
  repository: repository ?? InMemoryPresetRepository(),
  idSource: _FixedPresetIdSource(),
  onWarning: onWarning,
);

final class _FixedPresetIdSource implements PresetIdSource {
  var _index = 0;

  @override
  String next() => 'preset-test-${_index++}';
}

final class _FailingStore implements LocalStringStore {
  @override
  Future<void> clearOwned(Set<String> allowList) async {}

  @override
  Future<String?> readString(String key) =>
      Future<String?>.error(StateError('storage unavailable'));

  @override
  Future<void> remove(String key) async {}

  @override
  Future<void> writeString(String key, String value) async {}
}

final class _ActiveWriteFailingStore implements LocalStringStore {
  _ActiveWriteFailingStore(Map<String, String> initialValues)
    : values = <String, String>{...initialValues};

  final Map<String, String> values;

  @override
  Future<void> clearOwned(Set<String> allowList) async {
    for (final key in allowList) {
      values.remove(key);
    }
  }

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Future<void> writeString(String key, String value) async {
    if (key == PersistentPresetRepository.activeStorageKey) {
      throw StateError('active write blocked');
    }
    values[key] = value;
  }
}
