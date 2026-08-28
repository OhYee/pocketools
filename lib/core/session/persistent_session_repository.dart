import 'dart:async';
import 'dart:collection';

import 'local_string_store.dart';
import 'session.dart';
import 'session_envelope.dart';
import 'session_history.dart';

typedef UtcClock = DateTime Function();

/// Local, tool-neutral repository backed by a complete versioned snapshot.
///
/// Mutations are serialized and become visible in memory only after the new
/// active snapshot has been written. A failed active write therefore leaves
/// both the previous active snapshot and this repository's view unchanged.
final class PersistentSessionRepository
    implements SessionRepository, SessionHistoryRepository {
  PersistentSessionRepository({
    required LocalStringStore store,
    SessionStorageLimits limits = const SessionStorageLimits(),
    UtcClock? clock,
  }) : _store = AllowlistedLocalStringStore(
         delegate: store,
         allowedKeys: ownedKeys,
       ),
       _codec = SessionSnapshotJsonCodec(limits: limits),
       _clock = clock ?? _systemUtcClock;

  static const String activeStorageKey =
      'pocketools.sessions.snapshot.active.v1';
  static const String pendingStorageKey =
      'pocketools.sessions.snapshot.pending.v1';
  static const Set<String> ownedKeys = <String>{
    activeStorageKey,
    pendingStorageKey,
  };

  final LocalStringStore _store;
  final SessionSnapshotJsonCodec _codec;
  final UtcClock _clock;
  final Map<String, HistoryEntry> _entries = <String, HistoryEntry>{};
  final List<QuarantinedSessionData> _quarantined = <QuarantinedSessionData>[];
  final List<SessionLoadIssue> _issues = <SessionLoadIssue>[];

  Future<void> _operationTail = Future<void>.value();
  bool _loaded = false;

  static DateTime _systemUtcClock() => DateTime.now().toUtc();

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _operationTail = _operationTail.then((_) async {
      try {
        completer.complete(await operation());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    String? activeText;
    String? pendingText;
    try {
      activeText = await _store.readString(activeStorageKey);
      pendingText = await _store.readString(pendingStorageKey);
    } on Object {
      throw const SessionStorageException(
        'read_failed',
        'The local session snapshot could not be read.',
      );
    }

    if (activeText != null) {
      final snapshot = _codec.decode(activeText);
      for (final entry in snapshot.entries) {
        _entries[entry.session.id] = entry;
      }
      _quarantined.addAll(snapshot.quarantined);
      _issues.addAll(snapshot.issues);
    }
    if (pendingText != null) {
      _quarantined.add(
        QuarantinedSessionData(
          reasonCode: SessionLoadIssueCode.pendingSnapshotIgnored.name,
          rawText: pendingText,
        ),
      );
      _issues.add(
        const SessionLoadIssue(
          code: SessionLoadIssueCode.pendingSnapshotIgnored,
          message: 'An incomplete pending snapshot was isolated; active data was used.',
        ),
      );
    }
    _loaded = true;
  }

  @override
  Future<void> save(SessionRecord session) => _serialized(() async {
    await _ensureLoaded();
    final current = _entries[session.id];
    if (current != null) {
      _validateExistingSession(current.session, session);
      if (_sessionsEqual(current.session, session)) return;
    }

    final candidate = LinkedHashMap<String, HistoryEntry>.of(_entries);
    candidate[session.id] = current == null
        ? HistoryEntry(session: session, savedAtUtc: _clock())
        : current.withSession(session, _clock());
    await _commit(candidate, _quarantined);
  });

  @override
  Future<SessionRecord?> findById(String id) => _serialized(() async {
    await _ensureLoaded();
    return _entries[id]?.session;
  });

  @override
  Future<List<SessionRecord>> findAll() => _serialized(() async {
    await _ensureLoaded();
    return List<SessionRecord>.unmodifiable(
      _newestFirst(_entries.values).map((entry) => entry.session),
    );
  });

  @override
  Future<List<HistoryEntry>> listHistory({String? toolId}) =>
      _serialized(() async {
        await _ensureLoaded();
        final completed = _entries.values.where(
          (entry) =>
              entry.session.status == SessionStatus.completed &&
              (toolId == null || entry.session.toolId == toolId),
        );
        return List<HistoryEntry>.unmodifiable(_newestFirst(completed));
      });

  @override
  Future<HistoryEntry?> findHistoryEntry(String id) => _serialized(() async {
    await _ensureLoaded();
    return _entries[id];
  });

  @override
  Future<void> updateAnnotation(String id, SessionAnnotation annotation) =>
      _serialized(() async {
        await _ensureLoaded();
        final current = _entries[id];
        if (current == null) {
          throw const SessionStorageException(
            'not_found',
            'The requested session does not exist.',
          );
        }
        final candidate = LinkedHashMap<String, HistoryEntry>.of(_entries);
        candidate[id] = current.withAnnotation(annotation);
        await _commit(candidate, _quarantined);
      });

  @override
  Future<void> deleteById(String id) => _serialized(() async {
    await _ensureLoaded();
    if (!_entries.containsKey(id)) return;
    final candidate = LinkedHashMap<String, HistoryEntry>.of(_entries)
      ..remove(id);
    await _commit(candidate, _quarantined);
  });

  @override
  Future<void> deleteByTool(String toolId) => _serialized(() async {
    await _ensureLoaded();
    final candidate = LinkedHashMap<String, HistoryEntry>.of(_entries)
      ..removeWhere((_, entry) => entry.session.toolId == toolId);
    if (candidate.length == _entries.length) return;
    await _commit(candidate, _quarantined);
  });

  @override
  Future<void> clearHistory() => _serialized(() async {
    await _ensureLoaded();
    if (_entries.isEmpty && _quarantined.isEmpty) return;
    await _commit(
      const <String, HistoryEntry>{},
      const <QuarantinedSessionData>[],
    );
  });

  @override
  Future<SessionLoadReport> loadReport() => _serialized(() async {
    await _ensureLoaded();
    return SessionLoadReport(issues: _issues, quarantined: _quarantined);
  });

  List<HistoryEntry> _newestFirst(Iterable<HistoryEntry> source) {
    final result = List<HistoryEntry>.of(source);
    result.sort((left, right) => right.savedAtUtc.compareTo(left.savedAtUtc));
    return result;
  }

  Future<void> _commit(
    Map<String, HistoryEntry> candidate,
    Iterable<QuarantinedSessionData> quarantined,
  ) async {
    final frozenQuarantine = List<QuarantinedSessionData>.of(quarantined);
    final encoded = _codec.encode(
      entries: candidate.values,
      quarantined: frozenQuarantine,
    );
    try {
      await _store.writeString(pendingStorageKey, encoded);
      await _store.writeString(activeStorageKey, encoded);
    } on Object {
      throw const SessionStorageException(
        'write_failed',
        'The local session snapshot could not be saved.',
      );
    }

    _entries
      ..clear()
      ..addAll(candidate);
    _quarantined
      ..clear()
      ..addAll(frozenQuarantine);

    try {
      await _store.clearOwned(const <String>{pendingStorageKey});
    } on Object {
      _issues.add(
        const SessionLoadIssue(
          code: SessionLoadIssueCode.pendingCleanupFailed,
          message: 'The active snapshot was saved, but pending cleanup must be retried.',
        ),
      );
    }
  }

  void _validateExistingSession(
    SessionRecord oldValue,
    SessionRecord newValue,
  ) {
    if (oldValue.toolId != newValue.toolId ||
        oldValue.schemaVersion != newValue.schemaVersion ||
        oldValue.ruleVersion != newValue.ruleVersion ||
        oldValue.algorithmVersion != newValue.algorithmVersion ||
        oldValue.parentSessionId != newValue.parentSessionId ||
        !_deepEquals(oldValue.input, newValue.input)) {
      throw const SessionStorageException(
        'immutable_session_changed',
        'Stored session identity, input, or rule metadata cannot be rewritten.',
      );
    }
    if (newValue.status.index < oldValue.status.index) {
      throw const SessionStorageException(
        'status_regression',
        'A stored session cannot move to an earlier lifecycle state.',
      );
    }
    if (oldValue.status == SessionStatus.completed &&
        !_sessionsEqual(oldValue, newValue)) {
      throw const SessionStorageException(
        'completed_session_changed',
        'A completed session cannot be rewritten in place.',
      );
    }
  }

  bool _sessionsEqual(SessionRecord left, SessionRecord right) =>
      left.id == right.id &&
      left.toolId == right.toolId &&
      left.schemaVersion == right.schemaVersion &&
      left.ruleVersion == right.ruleVersion &&
      left.algorithmVersion == right.algorithmVersion &&
      left.status == right.status &&
      left.parentSessionId == right.parentSessionId &&
      _deepEquals(left.input, right.input) &&
      _deepEquals(left.outcome, right.outcome);

  bool _deepEquals(Object? left, Object? right) {
    if (identical(left, right)) return true;
    if (left is Map && right is Map) {
      if (left.length != right.length) return false;
      for (final key in left.keys) {
        if (!right.containsKey(key) || !_deepEquals(left[key], right[key])) {
          return false;
        }
      }
      return true;
    }
    if (left is List && right is List) {
      if (left.length != right.length) return false;
      for (var index = 0; index < left.length; index++) {
        if (!_deepEquals(left[index], right[index])) return false;
      }
      return true;
    }
    if (left is Set && right is Set) {
      if (left.length != right.length) return false;
      return left.every(
        (leftValue) =>
            right.any((rightValue) => _deepEquals(leftValue, rightValue)),
      );
    }
    return left == right;
  }
}
