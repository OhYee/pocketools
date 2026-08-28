import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/session/local_string_store.dart';
import 'package:pocketools/core/session/persistent_session_repository.dart';
import 'package:pocketools/core/session/resilient_session_repository.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_envelope.dart';
import 'package:pocketools/core/session/session_history.dart';

void main() {
  test(
    'history off routes new sessions transiently without deleting history',
    () async {
      var historyEnabled = true;
      var savedDay = 23;
      final persistent = PersistentSessionRepository(
        store: MemoryLocalStringStore(),
        clock: () => DateTime.utc(2026, 8, savedDay++),
      );
      final transient = InMemorySessionRepository();
      final repository = ResilientSessionRepository(
        persistentRepository: persistent,
        persistentHistory: persistent,
        transientRepository: transient,
        historyEnabled: () => historyEnabled,
        onWarning: (_) {},
      );

      await repository.save(_session('persistent-1'));
      historyEnabled = false;
      await repository.save(_session('transient-1'));
      expect(
        (await repository.listHistory()).map((entry) => entry.session.id),
        <String>['persistent-1'],
      );
      expect(await repository.findById('transient-1'), isNotNull);

      historyEnabled = true;
      await repository.save(_session('persistent-2'));
      expect(
        (await repository.listHistory()).map((entry) => entry.session.id),
        <String>['persistent-2', 'persistent-1'],
      );
    },
  );

  test(
    'persistent write failure keeps the frozen session transiently',
    () async {
      final warnings = <String>[];
      final persistent = _FailureRepository(failWrites: true);
      final transient = InMemorySessionRepository();
      final repository = ResilientSessionRepository(
        persistentRepository: persistent,
        persistentHistory: persistent,
        transientRepository: transient,
        historyEnabled: () => true,
        onWarning: warnings.add,
      );
      final session = _session('fallback');

      await repository.save(session);

      expect(await transient.findById(session.id), same(session));
      expect(await repository.findById(session.id), same(session));
      expect(warnings.single, contains('本次应用会话'));
    },
  );

  test(
    'session contract errors are not downgraded to storage failures',
    () async {
      final warnings = <String>[];
      final persistent = PersistentSessionRepository(
        store: MemoryLocalStringStore(),
      );
      final repository = ResilientSessionRepository(
        persistentRepository: persistent,
        persistentHistory: persistent,
        transientRepository: InMemorySessionRepository(),
        historyEnabled: () => true,
        onWarning: warnings.add,
      );

      await repository.save(_session('immutable'));
      await expectLater(
        repository.save(_session('immutable', status: SessionStatus.draft)),
        throwsA(
          isA<SessionStorageException>().having(
            (error) => error.code,
            'code',
            'status_regression',
          ),
        ),
      );

      expect(warnings, isEmpty);
      expect(
        (await repository.findById('immutable'))!.status,
        SessionStatus.completed,
      );
    },
  );
}

SessionRecord _session(
  String id, {
  SessionStatus status = SessionStatus.completed,
}) => SessionRecord(
  id: id,
  toolId: 'fake',
  schemaVersion: 1,
  ruleVersion: 'rule-v1',
  algorithmVersion: 'algorithm-v1',
  status: status,
  input: const <String, Object?>{'config': true},
  outcome: const <String, Object?>{'result': true},
);

final class _FailureRepository
    implements SessionRepository, SessionHistoryRepository {
  _FailureRepository({required this.failWrites});

  final bool failWrites;

  @override
  Future<void> save(SessionRecord session) async {
    if (failWrites) throw StateError('write failed');
  }

  @override
  Future<SessionRecord?> findById(String id) async => null;

  @override
  Future<List<SessionRecord>> findAll() async => const <SessionRecord>[];

  @override
  Future<void> clearHistory() async {}

  @override
  Future<void> deleteById(String id) async {}

  @override
  Future<void> deleteByTool(String toolId) async {}

  @override
  Future<HistoryEntry?> findHistoryEntry(String id) async => null;

  @override
  Future<List<HistoryEntry>> listHistory({String? toolId}) async =>
      const <HistoryEntry>[];

  @override
  Future<SessionLoadReport> loadReport() async => SessionLoadReport();

  @override
  Future<void> updateAnnotation(
    String id,
    SessionAnnotation annotation,
  ) async {}
}
