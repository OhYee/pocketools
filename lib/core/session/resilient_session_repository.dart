import 'session.dart';
import 'session_envelope.dart';
import 'session_history.dart';

typedef HistoryEnabledReader = bool Function();
typedef SessionWarningSink = void Function(String message);

/// Routes writes between durable and app-lifetime storage without changing a
/// frozen result. Durable failures are recovered into the transient repository
/// and surfaced through a tool-neutral warning sink.
final class ResilientSessionRepository
    implements SessionRepository, SessionHistoryRepository {
  factory ResilientSessionRepository({
    required SessionRepository persistentRepository,
    required SessionHistoryRepository persistentHistory,
    required HistoryEnabledReader historyEnabled,
    required SessionWarningSink onWarning,
    SessionRepository? transientRepository,
  }) => ResilientSessionRepository._(
    persistentRepository,
    persistentHistory,
    transientRepository ?? InMemorySessionRepository(),
    historyEnabled,
    onWarning,
  );

  ResilientSessionRepository._(
    this._persistentRepository,
    this._persistentHistory,
    this._transientRepository,
    this._historyEnabled,
    this._onWarning,
  );

  final SessionRepository _persistentRepository;
  final SessionHistoryRepository _persistentHistory;
  final SessionRepository _transientRepository;
  final HistoryEnabledReader _historyEnabled;
  final SessionWarningSink _onWarning;
  final Map<String, SessionRecord> _recent = <String, SessionRecord>{};
  var _persistentAvailable = true;

  SessionRepository get persistentRepository => _persistentRepository;
  SessionRepository get transientRepository => _transientRepository;

  @override
  Future<void> save(SessionRecord session) async {
    if (!_historyEnabled() || !_persistentAvailable) {
      await _transientRepository.save(session);
      _remember(session);
      return;
    }
    try {
      await _persistentRepository.save(session);
    } on Object catch (error) {
      if (!_isRecoverableStorageFailure(error)) rethrow;
      _persistentAvailable = false;
      await _transientRepository.save(session);
      _onWarning('本地历史暂时无法写入；当前结果已保留到本次应用会话。');
    }
    _remember(session);
  }

  void _remember(SessionRecord session) {
    _recent
      ..remove(session.id)
      ..[session.id] = session;
  }

  @override
  Future<SessionRecord?> findById(String id) async {
    final recent = _recent[id];
    if (recent != null) return recent;
    final transient = await _transientRepository.findById(id);
    if (transient != null) return transient;
    try {
      return await _persistentRepository.findById(id);
    } on Object catch (error) {
      if (!_isRecoverableStorageFailure(error)) rethrow;
      _persistentAvailable = false;
      _onWarning('本地历史暂时无法读取；可继续使用当前应用中的结果。');
      return null;
    }
  }

  @override
  Future<List<SessionRecord>> findAll() async {
    List<SessionRecord> persistent;
    try {
      if (!_persistentAvailable) throw const _PersistentUnavailable();
      persistent = await _persistentRepository.findAll();
    } on Object catch (error) {
      if (!_isRecoverableStorageFailure(error)) rethrow;
      persistent = const <SessionRecord>[];
      if (_persistentAvailable) {
        _persistentAvailable = false;
        _onWarning('本地历史暂时无法读取；可继续使用当前应用中的结果。');
      }
    }
    final transient = await _transientRepository.findAll();
    final result = <SessionRecord>[];
    final ids = <String>{};
    void add(SessionRecord session) {
      if (ids.add(session.id)) result.add(session);
    }

    for (final session in _recent.values.toList().reversed) {
      add(session);
    }
    for (final session in transient) {
      add(session);
    }
    for (final session in persistent) {
      add(session);
    }
    return List<SessionRecord>.unmodifiable(result);
  }

  @override
  Future<List<HistoryEntry>> listHistory({String? toolId}) async {
    if (!_persistentAvailable) return const <HistoryEntry>[];
    try {
      return await _persistentHistory.listHistory(toolId: toolId);
    } on Object catch (error) {
      if (!_isRecoverableStorageFailure(error)) rethrow;
      _persistentAvailable = false;
      _onWarning('本地历史暂时无法读取；可继续使用当前应用中的结果。');
      return const <HistoryEntry>[];
    }
  }

  @override
  Future<HistoryEntry?> findHistoryEntry(String id) async {
    if (!_persistentAvailable) return null;
    try {
      return await _persistentHistory.findHistoryEntry(id);
    } on Object catch (error) {
      if (!_isRecoverableStorageFailure(error)) rethrow;
      _persistentAvailable = false;
      _onWarning('本地历史暂时无法读取；可继续使用当前应用中的结果。');
      return null;
    }
  }

  @override
  Future<void> updateAnnotation(String id, SessionAnnotation annotation) async {
    if (!_persistentAvailable) {
      throw const SessionStorageException(
        'storage_unavailable',
        'Persistent session storage is unavailable.',
      );
    }
    try {
      await _persistentHistory.updateAnnotation(id, annotation);
    } on Object catch (error) {
      if (!_isRecoverableStorageFailure(error)) rethrow;
      _persistentAvailable = false;
      _onWarning('本地历史暂时无法写入；当前注释未保存。');
      rethrow;
    }
  }

  @override
  Future<void> deleteById(String id) async {
    _recent.remove(id);
    if (!_persistentAvailable) return;
    await _persistentHistory.deleteById(id);
  }

  @override
  Future<void> deleteByTool(String toolId) async {
    _recent.removeWhere((_, session) => session.toolId == toolId);
    if (!_persistentAvailable) return;
    await _persistentHistory.deleteByTool(toolId);
  }

  @override
  Future<void> clearHistory() async {
    _recent.clear();
    if (!_persistentAvailable) return;
    await _persistentHistory.clearHistory();
  }

  @override
  Future<SessionLoadReport> loadReport() async {
    try {
      return await _persistentHistory.loadReport();
    } on Object catch (error) {
      if (!_isRecoverableStorageFailure(error)) rethrow;
      _persistentAvailable = false;
      _onWarning('本地历史暂时无法读取；应用已切换为本次会话临时保存。');
      return SessionLoadReport(
        issues: const <SessionLoadIssue>[
          SessionLoadIssue(
            code: SessionLoadIssueCode.storageUnavailable,
            message: 'Persistent session storage is unavailable.',
          ),
        ],
      );
    }
  }
}

bool _isRecoverableStorageFailure(Object error) {
  if (error is! SessionStorageException) return true;
  return error.code == 'read_failed' || error.code == 'write_failed';
}

final class _PersistentUnavailable implements Exception {
  const _PersistentUnavailable();
}
