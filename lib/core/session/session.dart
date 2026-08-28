import 'dart:collection';

/// Copies a serializable session payload and recursively makes every
/// collection read-only.
///
/// Session payload maps use string keys so they remain compatible with storage
/// codecs. Cyclic and unsupported mutable values are rejected instead of being
/// retained by reference.
Map<String, Object?> deepFreezeMap(Map<String, Object?> source) =>
    _SessionValueFreezer().freezeMap(source, path: 'payload');

/// Copies a supported session value and recursively makes it read-only.
Object? deepFreezeValue(Object? source) =>
    _SessionValueFreezer().freeze(source, path: 'value');

final class _SessionValueFreezer {
  final Set<Object> _activeCollections = HashSet<Object>.identity();

  Object? freeze(Object? value, {required String path}) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is Map) {
      return freezeMap(value, path: path);
    }
    if (value is List) {
      return _withCollection(value, path, () {
        return List<Object?>.unmodifiable(
          value.indexed.map(
            (entry) => freeze(entry.$2, path: '$path[${entry.$1}]'),
          ),
        );
      });
    }
    if (value is Set) {
      return _withCollection(value, path, () {
        return Set<Object?>.unmodifiable(
          value.map((item) => freeze(item, path: '$path{item}')),
        );
      });
    }
    throw ArgumentError.value(
      value,
      path,
      'Session payload values must be null, scalar, map, list, or set.',
    );
  }

  Map<String, Object?> freezeMap(Map source, {required String path}) {
    return _withCollection(source, path, () {
      final frozen = <String, Object?>{};
      for (final entry in source.entries) {
        final key = entry.key;
        if (key is! String) {
          throw ArgumentError.value(
            key,
            path,
            'Session payload map keys must be strings.',
          );
        }
        frozen[key] = freeze(entry.value, path: '$path.$key');
      }
      return Map<String, Object?>.unmodifiable(frozen);
    });
  }

  T _withCollection<T>(Object collection, String path, T Function() build) {
    if (!_activeCollections.add(collection)) {
      throw ArgumentError.value(
        collection,
        path,
        'Session payload collections must not contain cycles.',
      );
    }
    try {
      return build();
    } finally {
      _activeCollections.remove(collection);
    }
  }
}

enum SessionStatus { draft, ready, generating, revealing, completed }

/// Cross-tool, serializable session envelope consumed by history and sharing.
final class SessionRecord {
  SessionRecord({
    required this.id,
    required this.toolId,
    required this.schemaVersion,
    required this.ruleVersion,
    required this.algorithmVersion,
    required this.status,
    required Map<String, Object?> input,
    required Map<String, Object?> outcome,
    this.parentSessionId,
  }) : input = deepFreezeMap(input),
       outcome = deepFreezeMap(outcome);

  final String id;
  final String toolId;
  final int schemaVersion;
  final String ruleVersion;
  final String algorithmVersion;
  final SessionStatus status;
  final Map<String, Object?> input;
  final Map<String, Object?> outcome;
  final String? parentSessionId;
}

/// Feature-owned adapter between typed domain objects and shared sessions.
abstract interface class ToolSessionCodec {
  String get toolId;

  Map<String, Object?> encodeInput(Object input);

  Object decodeInput(Map<String, Object?> input);

  Map<String, Object?> encodeOutcome(Object outcome);

  Object decodeOutcome(Map<String, Object?> outcome, Object input);

  String summarize(SessionRecord session);
}

abstract interface class SessionRepository {
  Future<void> save(SessionRecord session);

  Future<SessionRecord?> findById(String id);

  Future<List<SessionRecord>> findAll();
}

final class InMemorySessionRepository implements SessionRepository {
  final Map<String, SessionRecord> _sessions = <String, SessionRecord>{};

  @override
  Future<SessionRecord?> findById(String id) async => _sessions[id];

  @override
  Future<List<SessionRecord>> findAll() async =>
      List<SessionRecord>.unmodifiable(_sessions.values.toList().reversed);

  @override
  Future<void> save(SessionRecord session) async {
    _sessions[session.id] = session;
  }
}
