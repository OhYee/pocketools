import 'dart:collection';

import 'session.dart';

final class SessionAnnotation {
  SessionAnnotation({this.favorite = false, String? privateNote})
    : privateNote = _normalizePrivateNote(privateNote);

  static const maximumPrivateNoteLength = 2000;

  final bool favorite;
  final String? privateNote;

  SessionAnnotation copyWith({bool? favorite, String? privateNote}) =>
      SessionAnnotation(
        favorite: favorite ?? this.favorite,
        privateNote: privateNote ?? this.privateNote,
      );

  static String? _normalizePrivateNote(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    if (normalized.length > maximumPrivateNoteLength) {
      throw ArgumentError(
        'Private note exceeds $maximumPrivateNoteLength characters.',
      );
    }
    for (final unit in normalized.codeUnits) {
      if ((unit < 0x20 && unit != 0x09 && unit != 0x0A && unit != 0x0D) ||
          unit == 0x7F) {
        throw ArgumentError('Private note contains unsupported control data.');
      }
    }
    return normalized;
  }
}

final class HistoryEntry {
  HistoryEntry({
    required this.session,
    required DateTime savedAtUtc,
    SessionAnnotation? annotation,
  }) : savedAtUtc = _requireUtc(savedAtUtc),
       annotation = annotation ?? SessionAnnotation();

  final SessionRecord session;
  final DateTime savedAtUtc;
  final SessionAnnotation annotation;

  HistoryEntry withSession(SessionRecord value, DateTime savedAtUtc) =>
      HistoryEntry(
        session: value,
        savedAtUtc: savedAtUtc,
        annotation: annotation,
      );

  HistoryEntry withAnnotation(SessionAnnotation value) =>
      HistoryEntry(session: session, savedAtUtc: savedAtUtc, annotation: value);

  static DateTime _requireUtc(DateTime value) {
    if (!value.isUtc) {
      throw ArgumentError.value(value, 'savedAtUtc', 'Time must be UTC.');
    }
    return value;
  }
}

enum SessionLoadIssueCode {
  corruptJson,
  invalidTopLevel,
  unknownStorageVersion,
  invalidDocument,
  duplicateSessionId,
  legacyMigrated,
  pendingSnapshotIgnored,
  pendingCleanupFailed,
  snapshotLimitExceeded,
  storageUnavailable,
}

final class SessionLoadIssue {
  const SessionLoadIssue({required this.code, required this.message});

  final SessionLoadIssueCode code;
  final String message;
}

final class QuarantinedSessionData {
  const QuarantinedSessionData({
    required this.reasonCode,
    required this.rawText,
  });

  final String reasonCode;
  final String rawText;
}

final class SessionLoadReport {
  SessionLoadReport({
    Iterable<SessionLoadIssue> issues = const <SessionLoadIssue>[],
    Iterable<QuarantinedSessionData> quarantined =
        const <QuarantinedSessionData>[],
  }) : issues = UnmodifiableListView<SessionLoadIssue>(
         List<SessionLoadIssue>.of(issues),
       ),
       quarantined = UnmodifiableListView<QuarantinedSessionData>(
         List<QuarantinedSessionData>.of(quarantined),
       );

  final List<SessionLoadIssue> issues;
  final List<QuarantinedSessionData> quarantined;

  bool get hasIssues => issues.isNotEmpty || quarantined.isNotEmpty;
}

/// Tool-neutral history and annotation contract layered over SessionRepository.
abstract interface class SessionHistoryRepository {
  Future<List<HistoryEntry>> listHistory({String? toolId});

  Future<HistoryEntry?> findHistoryEntry(String id);

  Future<void> updateAnnotation(String id, SessionAnnotation annotation);

  Future<void> deleteById(String id);

  Future<void> deleteByTool(String toolId);

  Future<void> clearHistory();

  Future<SessionLoadReport> loadReport();
}
