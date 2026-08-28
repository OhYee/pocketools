import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/session/local_string_store.dart';
import 'package:pocketools/core/session/persistent_session_repository.dart';
import 'package:pocketools/core/session/resilient_session_repository.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_envelope.dart';
import 'package:pocketools/core/session/session_history.dart';

void main() {
  group('Stage 2C independent persistence transactions', () {
    test(
      'pending and active failures never replace the last active snapshot',
      () async {
        final store = _FaultStore();
        var tick = 0;
        final repository = PersistentSessionRepository(
          store: store,
          clock: () => DateTime.utc(2026, 8, 23, 10, 0, tick++),
        );
        await repository.save(_session('old'));
        final oldActive =
            store.values[PersistentSessionRepository.activeStorageKey];

        store.failWrites.add(PersistentSessionRepository.pendingStorageKey);
        await expectLater(
          repository.save(_session('pending-failure')),
          throwsA(_storageCode('write_failed')),
        );
        expect(
          store.values[PersistentSessionRepository.activeStorageKey],
          oldActive,
        );
        expect(await repository.findById('pending-failure'), isNull);

        store.failWrites
          ..clear()
          ..add(PersistentSessionRepository.activeStorageKey);
        await expectLater(
          repository.save(_session('active-failure')),
          throwsA(_storageCode('write_failed')),
        );
        expect(
          store.values[PersistentSessionRepository.activeStorageKey],
          oldActive,
        );
        expect(await repository.findById('active-failure'), isNull);
        expect(
          store.values[PersistentSessionRepository.pendingStorageKey],
          isNotNull,
        );

        final reloaded = PersistentSessionRepository(store: store);
        expect((await reloaded.findAll()).single.id, 'old');
        final report = await reloaded.loadReport();
        expect(
          report.issues.map((issue) => issue.code),
          contains(SessionLoadIssueCode.pendingSnapshotIgnored),
        );
        expect(report.quarantined.single.rawText, isNotEmpty);
      },
    );

    test(
      'cleanup failure keeps committed active data and remains diagnosable',
      () async {
        final store = _FaultStore()..failCleanup = true;
        final repository = PersistentSessionRepository(
          store: store,
          clock: () => DateTime.utc(2026, 8, 23),
        );

        await repository.save(_session('committed'));

        expect((await repository.findAll()).single.id, 'committed');
        expect(
          (await repository.loadReport()).issues.map((issue) => issue.code),
          contains(SessionLoadIssueCode.pendingCleanupFailed),
        );
        final reloaded = PersistentSessionRepository(store: store);
        expect((await reloaded.findAll()).single.id, 'committed');
        expect(
          (await reloaded.loadReport()).issues.map((issue) => issue.code),
          contains(SessionLoadIssueCode.pendingSnapshotIgnored),
        );
      },
    );

    test(
      'corrupt unknown and duplicate data retain raw quarantine after save',
      () async {
        final codec = SessionSnapshotJsonCodec();
        final validRoot =
            jsonDecode(
                  codec.encode(
                    entries: <HistoryEntry>[
                      HistoryEntry(
                        session: _session('duplicate'),
                        savedAtUtc: DateTime.utc(2026, 8, 23),
                      ),
                    ],
                  ),
                )!
                as Map<String, Object?>;
        final documents = validRoot['documents']! as List<Object?>;
        documents.add(jsonDecode(jsonEncode(documents.single)));
        final duplicateRaw = jsonEncode(validRoot);
        final duplicateDocumentRaw = jsonEncode(documents.last);

        final cases = <({String name, String raw, String expectedRaw})>[
          (name: 'corrupt', raw: '{broken-json', expectedRaw: '{broken-json'),
          (
            name: 'unknown',
            raw: '{"storageSchemaVersion":99,"documents":[]}',
            expectedRaw: '{"storageSchemaVersion":99,"documents":[]}',
          ),
          (
            name: 'duplicate',
            raw: duplicateRaw,
            expectedRaw: duplicateDocumentRaw,
          ),
        ];

        for (final testCase in cases) {
          final store = MemoryLocalStringStore(<String, String>{
            PersistentSessionRepository.activeStorageKey: testCase.raw,
          });
          final repository = PersistentSessionRepository(
            store: store,
            clock: () => DateTime.utc(2026, 8, 24),
          );
          await repository.findAll();
          expect(
            (await repository.loadReport()).quarantined.map(
              (item) => item.rawText,
            ),
            contains(testCase.expectedRaw),
            reason: testCase.name,
          );

          await repository.save(_session('new-${testCase.name}'));
          final reloaded = PersistentSessionRepository(store: store);
          expect(
            (await reloaded.loadReport()).quarantined.map(
              (item) => item.rawText,
            ),
            contains(testCase.expectedRaw),
            reason: '${testCase.name} after a later commit',
          );
        }
      },
    );

    test(
      'draft stays hidden then completion freezes result and savedAt UTC',
      () async {
        var tick = 0;
        final repository = PersistentSessionRepository(
          store: MemoryLocalStringStore(),
          clock: () => DateTime.utc(2026, 8, 23, 12, tick++),
        );
        final draft = _session(
          'lifecycle',
          status: SessionStatus.draft,
          outcomeValue: 'partial',
        );
        await repository.save(draft);
        expect(await repository.listHistory(), isEmpty);
        expect((await repository.findAll()).single.id, draft.id);

        final completed = _session(
          draft.id,
          status: SessionStatus.completed,
          outcomeValue: 'frozen',
        );
        await repository.save(completed);
        final entry = (await repository.listHistory()).single;
        expect(entry.session.outcome['value'], 'frozen');
        expect(entry.savedAtUtc.isUtc, isTrue);

        await expectLater(
          repository.save(
            _session(
              completed.id,
              status: SessionStatus.completed,
              outcomeValue: 'rewritten',
            ),
          ),
          throwsA(_storageCode('completed_session_changed')),
        );
        expect(
          (await repository.findById(completed.id))!.outcome['value'],
          'frozen',
        );
      },
    );

    test(
      'parallel saves are serialized and reload in UTC saved order',
      () async {
        final store = _FaultStore(writeDelay: const Duration(milliseconds: 1));
        var tick = 0;
        final repository = PersistentSessionRepository(
          store: store,
          clock: () => DateTime.utc(2026, 8, 23, 0, 0, tick++),
        );

        await Future.wait(
          List<Future<void>>.generate(
            20,
            (index) => repository.save(_session('parallel-$index')),
          ),
        );

        expect(store.maximumConcurrentWrites, 1);
        final reloaded = PersistentSessionRepository(store: store);
        final history = await reloaded.listHistory();
        expect(history, hasLength(20));
        expect(history.first.session.id, 'parallel-19');
        expect(history.last.session.id, 'parallel-0');
        expect(history.every((entry) => entry.savedAtUtc.isUtc), isTrue);
      },
    );

    test(
      'read failure and entry limit fail without storage mutation',
      () async {
        final readFailure = _FaultStore()
          ..failReads.add(PersistentSessionRepository.activeStorageKey);
        final unreadable = PersistentSessionRepository(store: readFailure);
        await expectLater(
          unreadable.findAll(),
          throwsA(_storageCode('read_failed')),
        );

        final limitedStore = MemoryLocalStringStore();
        final limited = PersistentSessionRepository(
          store: limitedStore,
          limits: const SessionStorageLimits(
            maximumEntries: 1,
            maximumSnapshotBytes: 4096,
          ),
          clock: () => DateTime.utc(2026),
        );
        await limited.save(_session('only'));
        final active =
            limitedStore.values[PersistentSessionRepository.activeStorageKey];
        await expectLater(
          limited.save(_session('overflow')),
          throwsA(_storageCode('entry_limit')),
        );
        expect(
          limitedStore.values[PersistentSessionRepository.activeStorageKey],
          active,
        );
      },
    );

    test(
      'history toggle keeps durable history and resumes durable writes',
      () async {
        var historyEnabled = true;
        final store = MemoryLocalStringStore();
        final durable = PersistentSessionRepository(
          store: store,
          clock: () => DateTime.utc(2026, 8, 23),
        );
        final transient = InMemorySessionRepository();
        final repository = ResilientSessionRepository(
          persistentRepository: durable,
          persistentHistory: durable,
          transientRepository: transient,
          historyEnabled: () => historyEnabled,
          onWarning: (_) {},
        );

        await repository.save(_session('durable-before'));
        historyEnabled = false;
        await repository.save(_session('transient-only'));
        expect(
          (await repository.listHistory()).map((entry) => entry.session.id),
          <String>['durable-before'],
        );
        expect(await transient.findById('transient-only'), isNotNull);

        historyEnabled = true;
        await repository.save(_session('durable-after'));
        final reopened = PersistentSessionRepository(store: store);
        expect(
          (await reopened.listHistory())
              .map((entry) => entry.session.id)
              .toSet(),
          <String>{'durable-before', 'durable-after'},
        );
        expect(await reopened.findById('transient-only'), isNull);
      },
    );
  });
}

Matcher _storageCode(String code) =>
    isA<SessionStorageException>().having((error) => error.code, 'code', code);

SessionRecord _session(
  String id, {
  SessionStatus status = SessionStatus.completed,
  String outcomeValue = 'result',
}) => SessionRecord(
  id: id,
  toolId: 'fake',
  schemaVersion: 1,
  ruleVersion: 'fake/rule-v1',
  algorithmVersion: 'fake/algorithm-v1',
  status: status,
  input: const <String, Object?>{'config': 'stable'},
  outcome: <String, Object?>{'value': outcomeValue},
);

final class _FaultStore implements LocalStringStore {
  _FaultStore({this.writeDelay = Duration.zero});

  final Duration writeDelay;
  final Map<String, String> values = <String, String>{};
  final Set<String> failReads = <String>{};
  final Set<String> failWrites = <String>{};
  var failCleanup = false;
  var concurrentWrites = 0;
  var maximumConcurrentWrites = 0;

  @override
  Future<void> clearOwned(Set<String> allowList) async {
    if (failCleanup) throw StateError('cleanup failure');
    for (final key in allowList) {
      values.remove(key);
    }
  }

  @override
  Future<String?> readString(String key) async {
    if (failReads.contains(key)) throw StateError('read failure');
    return values[key];
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    concurrentWrites++;
    if (concurrentWrites > maximumConcurrentWrites) {
      maximumConcurrentWrites = concurrentWrites;
    }
    try {
      if (writeDelay > Duration.zero) await Future<void>.delayed(writeDelay);
      if (failWrites.contains(key)) throw StateError('write failure');
      values[key] = value;
    } finally {
      concurrentWrites--;
    }
  }
}
