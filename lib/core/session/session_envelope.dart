import 'dart:collection';
import 'dart:convert';

import 'session.dart';
import 'session_history.dart';

final class SessionStorageLimits {
  const SessionStorageLimits({
    this.maximumEntries = 250,
    this.maximumSnapshotBytes = 2 * 1024 * 1024,
  });

  final int maximumEntries;
  final int maximumSnapshotBytes;

  void validate() {
    if (maximumEntries <= 0) {
      throw ArgumentError.value(maximumEntries, 'maximumEntries');
    }
    if (maximumSnapshotBytes <= 0) {
      throw ArgumentError.value(maximumSnapshotBytes, 'maximumSnapshotBytes');
    }
  }
}

final class SessionStorageException implements Exception {
  const SessionStorageException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'SessionStorageException($code): $message';
}

final class SessionSnapshot {
  SessionSnapshot({
    Iterable<HistoryEntry> entries = const <HistoryEntry>[],
    Iterable<QuarantinedSessionData> quarantined =
        const <QuarantinedSessionData>[],
    Iterable<SessionLoadIssue> issues = const <SessionLoadIssue>[],
  }) : entries = UnmodifiableListView<HistoryEntry>(
         List<HistoryEntry>.of(entries),
       ),
       quarantined = UnmodifiableListView<QuarantinedSessionData>(
         List<QuarantinedSessionData>.of(quarantined),
       ),
       issues = UnmodifiableListView<SessionLoadIssue>(
         List<SessionLoadIssue>.of(issues),
       );

  final List<HistoryEntry> entries;
  final List<QuarantinedSessionData> quarantined;
  final List<SessionLoadIssue> issues;
}

/// Strict codec for the storage envelope. Tool session schema versions remain
/// inside each SessionRecord and are never used as the storage schema version.
final class SessionSnapshotJsonCodec {
  SessionSnapshotJsonCodec({this.limits = const SessionStorageLimits()}) {
    limits.validate();
  }

  static const currentStorageSchemaVersion = 1;
  static const legacyStorageSchemaVersion = 0;

  final SessionStorageLimits limits;

  SessionSnapshot decode(String rawText) {
    if (utf8.encode(rawText).length > limits.maximumSnapshotBytes) {
      return _wholeSnapshotQuarantine(
        rawText,
        SessionLoadIssueCode.snapshotLimitExceeded,
        'Stored session snapshot exceeds the configured byte limit.',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(rawText);
    } on FormatException {
      return _wholeSnapshotQuarantine(
        rawText,
        SessionLoadIssueCode.corruptJson,
        'Stored session snapshot is not valid JSON.',
      );
    }
    if (decoded is! Map) {
      return _wholeSnapshotQuarantine(
        rawText,
        SessionLoadIssueCode.invalidTopLevel,
        'Stored session snapshot must be a JSON object.',
      );
    }
    final root = _stringMap(decoded, 'snapshot');
    final version = root['storageSchemaVersion'];
    if (version is! int) {
      return _wholeSnapshotQuarantine(
        rawText,
        SessionLoadIssueCode.invalidTopLevel,
        'Storage schema version must be an integer.',
      );
    }
    if (version == legacyStorageSchemaVersion) {
      return _decodeLegacy(root, rawText);
    }
    if (version != currentStorageSchemaVersion) {
      return _wholeSnapshotQuarantine(
        rawText,
        SessionLoadIssueCode.unknownStorageVersion,
        'Storage schema version is not supported.',
      );
    }
    try {
      _requireExactKeys(root, const <String>{
        'storageSchemaVersion',
        'documents',
        'quarantined',
      }, 'snapshot');
    } on FormatException {
      return _wholeSnapshotQuarantine(
        rawText,
        SessionLoadIssueCode.invalidTopLevel,
        'Stored session snapshot has invalid top-level fields.',
      );
    }
    return _decodeDocuments(
      root,
      rawText: rawText,
      legacy: false,
      inheritedIssues: const <SessionLoadIssue>[],
    );
  }

  String encode({
    required Iterable<HistoryEntry> entries,
    Iterable<QuarantinedSessionData> quarantined =
        const <QuarantinedSessionData>[],
  }) {
    final entryList = List<HistoryEntry>.of(entries);
    final quarantineList = List<QuarantinedSessionData>.of(quarantined);
    if (entryList.length > limits.maximumEntries) {
      throw SessionStorageException(
        'entry_limit',
        'Session entry limit of ${limits.maximumEntries} was reached.',
      );
    }
    late final String encoded;
    try {
      final value = <String, Object?>{
        'storageSchemaVersion': currentStorageSchemaVersion,
        'documents': entryList.map(_encodeEntry).toList(growable: false),
        'quarantined': quarantineList
            .map(
              (item) => <String, Object?>{
                'reasonCode': item.reasonCode,
                'rawText': item.rawText,
              },
            )
            .toList(growable: false),
      };
      encoded = jsonEncode(value);
    } on Object catch (error) {
      if (error is SessionStorageException) rethrow;
      throw const SessionStorageException(
        'non_json_value',
        'Session payload contains a value that JSON cannot encode.',
      );
    }
    if (utf8.encode(encoded).length > limits.maximumSnapshotBytes) {
      throw SessionStorageException(
        'snapshot_limit',
        'Session snapshot exceeds ${limits.maximumSnapshotBytes} bytes.',
      );
    }
    return encoded;
  }

  SessionSnapshot _decodeLegacy(Map<String, Object?> root, String rawText) {
    try {
      _requireExactKeys(root, const <String>{
        'storageSchemaVersion',
        'documents',
      }, 'legacy snapshot');
    } on FormatException {
      return _wholeSnapshotQuarantine(
        rawText,
        SessionLoadIssueCode.invalidTopLevel,
        'Legacy session snapshot has invalid top-level fields.',
      );
    }
    return _decodeDocuments(
      root,
      rawText: rawText,
      legacy: true,
      inheritedIssues: const <SessionLoadIssue>[
        SessionLoadIssue(
          code: SessionLoadIssueCode.legacyMigrated,
          message: 'Legacy storage schema was loaded with default annotations.',
        ),
      ],
    );
  }

  SessionSnapshot _decodeDocuments(
    Map<String, Object?> root, {
    required String rawText,
    required bool legacy,
    required List<SessionLoadIssue> inheritedIssues,
  }) {
    final rawDocuments = root['documents'];
    if (rawDocuments is! List || rawDocuments.length > limits.maximumEntries) {
      return _wholeSnapshotQuarantine(
        rawText,
        rawDocuments is List
            ? SessionLoadIssueCode.snapshotLimitExceeded
            : SessionLoadIssueCode.invalidTopLevel,
        'Stored session documents are missing or exceed the entry limit.',
      );
    }

    final entries = <HistoryEntry>[];
    final quarantined = <QuarantinedSessionData>[];
    final issues = <SessionLoadIssue>[...inheritedIssues];
    final ids = <String>{};
    for (var index = 0; index < rawDocuments.length; index++) {
      final rawDocument = rawDocuments[index];
      try {
        final entry = _decodeEntry(rawDocument, legacy: legacy);
        if (!ids.add(entry.session.id)) {
          quarantined.add(
            QuarantinedSessionData(
              reasonCode: SessionLoadIssueCode.duplicateSessionId.name,
              rawText: jsonEncode(rawDocument),
            ),
          );
          issues.add(
            const SessionLoadIssue(
              code: SessionLoadIssueCode.duplicateSessionId,
              message: 'A duplicate session id was isolated.',
            ),
          );
          continue;
        }
        entries.add(entry);
      } on Object {
        quarantined.add(
          QuarantinedSessionData(
            reasonCode: SessionLoadIssueCode.invalidDocument.name,
            rawText: jsonEncode(rawDocument),
          ),
        );
        issues.add(
          const SessionLoadIssue(
            code: SessionLoadIssueCode.invalidDocument,
            message: 'An invalid session document was isolated.',
          ),
        );
      }
    }

    if (!legacy) {
      final rawQuarantine = root['quarantined'];
      if (rawQuarantine is! List) {
        return _wholeSnapshotQuarantine(
          rawText,
          SessionLoadIssueCode.invalidTopLevel,
          'Stored quarantine data must be a list.',
        );
      }
      for (final rawItem in rawQuarantine) {
        try {
          final item = _stringMap(rawItem, 'quarantined item');
          _requireExactKeys(item, const <String>{
            'reasonCode',
            'rawText',
          }, 'quarantined item');
          quarantined.add(
            QuarantinedSessionData(
              reasonCode: _requiredString(item, 'reasonCode', 'quarantine'),
              rawText: _requiredString(item, 'rawText', 'quarantine'),
            ),
          );
        } on Object {
          quarantined.add(
            QuarantinedSessionData(
              reasonCode: SessionLoadIssueCode.invalidDocument.name,
              rawText: jsonEncode(rawItem),
            ),
          );
          issues.add(
            const SessionLoadIssue(
              code: SessionLoadIssueCode.invalidDocument,
              message: 'Invalid quarantine metadata was isolated.',
            ),
          );
        }
      }
    }
    return SessionSnapshot(
      entries: entries,
      quarantined: quarantined,
      issues: issues,
    );
  }

  HistoryEntry _decodeEntry(Object? raw, {required bool legacy}) {
    final document = _stringMap(raw, 'session document');
    _requireExactKeys(
      document,
      legacy
          ? const <String>{'savedAtUtc', 'session'}
          : const <String>{'savedAtUtc', 'session', 'annotation'},
      'session document',
    );
    final timestampText = _requiredString(
      document,
      'savedAtUtc',
      'session document',
    );
    final savedAt = DateTime.tryParse(timestampText);
    if (savedAt == null || !savedAt.isUtc || !timestampText.endsWith('Z')) {
      throw const FormatException('savedAtUtc must be an ISO-8601 UTC value.');
    }
    return HistoryEntry(
      session: _decodeSession(document['session'], legacy: legacy),
      savedAtUtc: savedAt,
      annotation: legacy
          ? SessionAnnotation()
          : _decodeAnnotation(document['annotation']),
    );
  }

  SessionRecord _decodeSession(Object? raw, {required bool legacy}) {
    final session = _stringMap(raw, 'session');
    const requiredKeys = <String>{
      'id',
      'toolId',
      'schemaVersion',
      'ruleVersion',
      'algorithmVersion',
      'status',
      'input',
      'outcome',
      'parentSessionId',
    };
    if (legacy && !session.containsKey('parentSessionId')) {
      session['parentSessionId'] = null;
    }
    _requireExactKeys(session, requiredKeys, 'session');
    final id = _validatedIdentifier(session, 'id');
    final toolId = _validatedIdentifier(session, 'toolId');
    final schemaVersion = session['schemaVersion'];
    if (schemaVersion is! int || schemaVersion <= 0) {
      throw const FormatException('Session schemaVersion must be positive.');
    }
    final statusName = _requiredString(session, 'status', 'session');
    final status = SessionStatus.values.where(
      (candidate) => candidate.name == statusName,
    );
    if (status.length != 1) {
      throw const FormatException('Session status is not supported.');
    }
    final parent = session['parentSessionId'];
    if (parent != null && parent is! String) {
      throw const FormatException('parentSessionId must be null or a string.');
    }
    if (parent is String) _validateIdentifierValue(parent, 'parentSessionId');
    return SessionRecord(
      id: id,
      toolId: toolId,
      schemaVersion: schemaVersion,
      ruleVersion: _validatedVersion(session, 'ruleVersion'),
      algorithmVersion: _validatedVersion(session, 'algorithmVersion'),
      status: status.single,
      input: _jsonMap(session['input'], 'session.input'),
      outcome: _jsonMap(session['outcome'], 'session.outcome'),
      parentSessionId: parent as String?,
    );
  }

  SessionAnnotation _decodeAnnotation(Object? raw) {
    final annotation = _stringMap(raw, 'annotation');
    _requireExactKeys(annotation, const <String>{
      'favorite',
      'privateNote',
    }, 'annotation');
    final favorite = annotation['favorite'];
    final privateNote = annotation['privateNote'];
    if (favorite is! bool || (privateNote != null && privateNote is! String)) {
      throw const FormatException('Annotation types are invalid.');
    }
    return SessionAnnotation(
      favorite: favorite,
      privateNote: privateNote as String?,
    );
  }

  Map<String, Object?> _encodeEntry(HistoryEntry entry) => <String, Object?>{
    'savedAtUtc': entry.savedAtUtc.toIso8601String(),
    'session': <String, Object?>{
      'id': entry.session.id,
      'toolId': entry.session.toolId,
      'schemaVersion': entry.session.schemaVersion,
      'ruleVersion': entry.session.ruleVersion,
      'algorithmVersion': entry.session.algorithmVersion,
      'status': entry.session.status.name,
      'input': _validatedJsonMap(entry.session.input, 'session.input'),
      'outcome': _validatedJsonMap(entry.session.outcome, 'session.outcome'),
      'parentSessionId': entry.session.parentSessionId,
    },
    'annotation': <String, Object?>{
      'favorite': entry.annotation.favorite,
      'privateNote': entry.annotation.privateNote,
    },
  };

  Map<String, Object?> _validatedJsonMap(
    Map<String, Object?> source,
    String path,
  ) => _jsonMap(source, path);

  Map<String, Object?> _jsonMap(Object? raw, String path) {
    final source = _stringMap(raw, path);
    final result = <String, Object?>{};
    for (final entry in source.entries) {
      result[entry.key] = _jsonValue(entry.value, '$path.${entry.key}');
    }
    return result;
  }

  Object? _jsonValue(Object? value, String path) {
    if (value == null || value is String || value is bool || value is int) {
      return value;
    }
    if (value is double && value.isFinite) return value;
    if (value is List) {
      return value.indexed
          .map((entry) => _jsonValue(entry.$2, '$path[${entry.$1}]'))
          .toList(growable: false);
    }
    if (value is Map) return _jsonMap(value, path);
    throw FormatException('$path contains a non-JSON value.');
  }

  Map<String, Object?> _stringMap(Object? raw, String source) {
    if (raw is! Map) throw FormatException('$source must be an object.');
    final result = <String, Object?>{};
    for (final entry in raw.entries) {
      if (entry.key is! String) {
        throw FormatException('$source keys must be strings.');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  void _requireExactKeys(
    Map<String, Object?> value,
    Set<String> expected,
    String source,
  ) {
    final actual = value.keys.toSet();
    if (actual.length != expected.length || !actual.containsAll(expected)) {
      throw FormatException('$source contains unexpected or missing fields.');
    }
  }

  String _requiredString(
    Map<String, Object?> value,
    String key,
    String source,
  ) {
    final result = value[key];
    if (result is! String || result.isEmpty) {
      throw FormatException('$source.$key must be a non-empty string.');
    }
    return result;
  }

  String _validatedIdentifier(Map<String, Object?> value, String key) {
    final result = _requiredString(value, key, 'session');
    _validateIdentifierValue(result, key);
    return result;
  }

  void _validateIdentifierValue(String value, String key) {
    if (value.length > 160 || value.trim() != value || _hasControl(value)) {
      throw FormatException('Session $key is invalid.');
    }
  }

  String _validatedVersion(Map<String, Object?> value, String key) {
    final result = _requiredString(value, key, 'session');
    if (result.length > 160 || result.trim() != result || _hasControl(result)) {
      throw FormatException('Session $key is invalid.');
    }
    return result;
  }

  bool _hasControl(String value) =>
      value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7F);

  SessionSnapshot _wholeSnapshotQuarantine(
    String rawText,
    SessionLoadIssueCode code,
    String message,
  ) => SessionSnapshot(
    quarantined: <QuarantinedSessionData>[
      QuarantinedSessionData(reasonCode: code.name, rawText: rawText),
    ],
    issues: <SessionLoadIssue>[SessionLoadIssue(code: code, message: message)],
  );
}
