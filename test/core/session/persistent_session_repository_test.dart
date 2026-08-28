import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/session/local_string_store.dart';
import 'package:pocketools/core/session/persistent_session_repository.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_envelope.dart';
import 'package:pocketools/core/session/session_history.dart';

void main() {
  test(
    'completed history is newest first while drafts remain restorable',
    () async {
      var second = 0;
      final repository = PersistentSessionRepository(
        store: MemoryLocalStringStore(),
        clock: () => DateTime.utc(2026, 8, 23, 0, 0, second++),
      );

      await repository.save(_session('complete-a', toolId: 'cards'));
      await repository.save(
        _session('draft', toolId: 'coin', status: SessionStatus.draft),
      );
      await repository.save(_session('complete-b', toolId: 'coin'));

      expect(
        (await repository.listHistory()).map((entry) => entry.session.id),
        <String>['complete-b', 'complete-a'],
      );
      expect(await repository.findById('draft'), isNotNull);
      expect(await repository.findAll(), hasLength(3));
      expect(
        (await repository.listHistory(toolId: 'coin')).single.session.id,
        'complete-b',
      );
    },
  );

  test('annotation update cannot rewrite frozen session fields', () async {
    final repository = PersistentSessionRepository(
      store: MemoryLocalStringStore(),
      clock: () => DateTime.utc(2026),
    );
    final session = _session('annotated');
    await repository.save(session);

    await repository.updateAnnotation(
      session.id,
      SessionAnnotation(favorite: true, privateNote: 'private'),
    );

    final entry = await repository.findHistoryEntry(session.id);
    expect(entry!.annotation.favorite, isTrue);
    expect(entry.annotation.privateNote, 'private');
    expect(entry.session.outcome, session.outcome);
    expect(entry.session.ruleVersion, session.ruleVersion);
    expect(entry.savedAtUtc, DateTime.utc(2026));
  });

  test(
    'failed active write preserves prior snapshot and repository view',
    () async {
      final store = _ControlledStore();
      final repository = PersistentSessionRepository(
        store: store,
        clock: () => DateTime.utc(2026),
      );
      await repository.save(_session('old'));
      final oldActive =
          store.values[PersistentSessionRepository.activeStorageKey];
      store.failActiveWrites = true;

      await expectLater(
        repository.save(_session('new')),
        throwsA(
          isA<SessionStorageException>().having(
            (error) => error.code,
            'code',
            'write_failed',
          ),
        ),
      );

      expect(
        store.values[PersistentSessionRepository.activeStorageKey],
        oldActive,
      );
      expect(await repository.findById('new'), isNull);
      expect(await repository.findById('old'), isNotNull);
    },
  );

  test('concurrent saves are serialized without lost updates', () async {
    final store = _ControlledStore(writeDelay: const Duration(milliseconds: 1));
    var second = 0;
    final repository = PersistentSessionRepository(
      store: store,
      clock: () => DateTime.utc(2026, 8, 23, 0, 0, second++),
    );

    await Future.wait(<Future<void>>[
      repository.save(_session('one')),
      repository.save(_session('two')),
      repository.save(_session('three')),
    ]);

    expect(await repository.findAll(), hasLength(3));
    expect(store.maximumConcurrentWrites, 1);
    final reloaded = PersistentSessionRepository(store: store);
    expect(await reloaded.findAll(), hasLength(3));
  });

  test('delete scopes and clear never touch foreign keys', () async {
    final store = _ControlledStore(
      initialValues: <String, String>{'foreign.key': 'keep'},
    );
    final repository = PersistentSessionRepository(
      store: store,
      clock: () => DateTime.utc(2026),
    );
    await repository.save(_session('cards-1', toolId: 'cards'));
    await repository.save(_session('cards-2', toolId: 'cards'));
    await repository.save(_session('coin-1', toolId: 'coin'));

    await repository.deleteById('cards-1');
    expect(await repository.findById('cards-1'), isNull);
    await repository.deleteByTool('cards');
    expect((await repository.findAll()).single.id, 'coin-1');
    await repository.clearHistory();

    expect(await repository.findAll(), isEmpty);
    expect(store.values['foreign.key'], 'keep');
    expect(
      store.clearedKeys.every(PersistentSessionRepository.ownedKeys.contains),
      isTrue,
    );
  });

  test('pending data is never promoted over the active snapshot', () async {
    final activeCodec = SessionSnapshotJsonCodec();
    String snapshotFor(String id) => activeCodec.encode(
      entries: <HistoryEntry>[
        HistoryEntry(session: _session(id), savedAtUtc: DateTime.utc(2026)),
      ],
    );
    final store = MemoryLocalStringStore(<String, String>{
      PersistentSessionRepository.activeStorageKey: snapshotFor('active'),
      PersistentSessionRepository.pendingStorageKey: snapshotFor('pending'),
    });
    final repository = PersistentSessionRepository(store: store);

    expect((await repository.findAll()).single.id, 'active');
    final report = await repository.loadReport();
    expect(
      report.issues.map((issue) => issue.code),
      contains(SessionLoadIssueCode.pendingSnapshotIgnored),
    );
    expect(report.quarantined.single.rawText, snapshotFor('pending'));
  });

  test('configured entry limit is enforced before storage mutation', () async {
    final store = MemoryLocalStringStore();
    final repository = PersistentSessionRepository(
      store: store,
      limits: const SessionStorageLimits(
        maximumEntries: 1,
        maximumSnapshotBytes: 4096,
      ),
      clock: () => DateTime.utc(2026),
    );
    await repository.save(_session('one'));
    final active = store.values[PersistentSessionRepository.activeStorageKey];

    await expectLater(
      repository.save(_session('two')),
      throwsA(isA<SessionStorageException>()),
    );
    expect(store.values[PersistentSessionRepository.activeStorageKey], active);
  });
}

SessionRecord _session(
  String id, {
  String toolId = 'fake',
  SessionStatus status = SessionStatus.completed,
}) => SessionRecord(
  id: id,
  toolId: toolId,
  schemaVersion: 1,
  ruleVersion: '$toolId/rule-1',
  algorithmVersion: 'random/v1',
  status: status,
  input: const <String, Object?>{'count': 1},
  outcome: <String, Object?>{'id': id},
);

final class _ControlledStore implements LocalStringStore {
  _ControlledStore({
    Map<String, String>? initialValues,
    this.writeDelay = Duration.zero,
  }) : values = <String, String>{...?initialValues};

  final Map<String, String> values;
  final Duration writeDelay;
  final List<String> clearedKeys = <String>[];
  bool failActiveWrites = false;
  int concurrentWrites = 0;
  int maximumConcurrentWrites = 0;

  @override
  Future<void> clearOwned(Set<String> allowList) async {
    clearedKeys.addAll(allowList);
    for (final key in allowList) {
      values.remove(key);
    }
  }

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    concurrentWrites++;
    maximumConcurrentWrites = maximumConcurrentWrites < concurrentWrites
        ? concurrentWrites
        : maximumConcurrentWrites;
    try {
      if (writeDelay > Duration.zero) await Future<void>.delayed(writeDelay);
      if (failActiveWrites &&
          key == PersistentSessionRepository.activeStorageKey) {
        throw StateError('controlled failure');
      }
      values[key] = value;
    } finally {
      concurrentWrites--;
    }
  }
}
