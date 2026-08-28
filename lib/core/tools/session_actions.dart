import '../session/session.dart';
import '../session/session_history.dart';
import 'tool_capabilities.dart';
import 'tool_registry.dart';

enum SessionTextActionOutcome { shared, copiedToClipboard, dismissed, failed }

abstract interface class SessionTextGateway {
  Future<SessionTextActionOutcome> shareText({
    required String title,
    required String text,
  });

  Future<SessionTextActionOutcome> copyText(String text);
}

final class NoopSessionTextGateway implements SessionTextGateway {
  const NoopSessionTextGateway();

  @override
  Future<SessionTextActionOutcome> copyText(String text) async =>
      SessionTextActionOutcome.failed;

  @override
  Future<SessionTextActionOutcome> shareText({
    required String title,
    required String text,
  }) async => SessionTextActionOutcome.failed;
}

final class SessionSharePreview {
  SessionSharePreview({
    required this.title,
    required this.defaultText,
    required Iterable<ToolOptionalShareField> optionalFields,
    this.privateNote,
    this.savedAtUtc,
  }) : optionalFields = List<ToolOptionalShareField>.unmodifiable(
         optionalFields,
       );

  final String title;
  final String defaultText;
  final List<ToolOptionalShareField> optionalFields;
  final String? privateNote;
  final DateTime? savedAtUtc;

  String compose({
    Set<String> includedFieldIds = const <String>{},
    bool includePrivateNote = false,
    bool includeTime = false,
  }) {
    final lines = <String>[defaultText];
    for (final field in optionalFields) {
      if (includedFieldIds.contains(field.id)) {
        lines.add('${field.label}：${field.value}');
      }
    }
    if (includePrivateNote && privateNote != null) {
      lines.add('私人备注：$privateNote');
    }
    if (includeTime && savedAtUtc != null) {
      lines.add('保存时间：${savedAtUtc!.toIso8601String()}');
    }
    return lines.join('\n');
  }
}

final class SessionActionsController {
  const SessionActionsController({
    required this.registry,
    required this.historyRepository,
    required this.textGateway,
  });

  final ToolRegistry registry;
  final SessionHistoryRepository historyRepository;
  final SessionTextGateway textGateway;

  Future<SessionSharePreview> preview(SessionRecord session) async {
    final payload = registry.sharePayload(session);
    if (<String>[payload.title, payload.summary, payload.plainText].any(
      (text) =>
          ToolOptionalShareFieldPolicy.containsSessionIdentifier(text, session),
    )) {
      throw const FormatException(
        'Default share payload rejected by the shared privacy policy.',
      );
    }
    HistoryEntry? entry;
    try {
      entry = await historyRepository.findHistoryEntry(session.id);
    } on Object {
      entry = null;
    }
    return SessionSharePreview(
      title: payload.title,
      defaultText: payload.plainText,
      optionalFields: registry.optionalShareFields(session),
      privateNote: entry?.annotation.privateNote,
      savedAtUtc: entry?.savedAtUtc,
    );
  }

  Future<SessionTextActionOutcome> share(
    SessionSharePreview preview, {
    Set<String> includedFieldIds = const <String>{},
    bool includePrivateNote = false,
    bool includeTime = false,
  }) => textGateway.shareText(
    title: preview.title,
    text: preview.compose(
      includedFieldIds: includedFieldIds,
      includePrivateNote: includePrivateNote,
      includeTime: includeTime,
    ),
  );

  Future<SessionTextActionOutcome> copy(
    SessionSharePreview preview, {
    Set<String> includedFieldIds = const <String>{},
    bool includePrivateNote = false,
    bool includeTime = false,
  }) => textGateway.copyText(
    preview.compose(
      includedFieldIds: includedFieldIds,
      includePrivateNote: includePrivateNote,
      includeTime: includeTime,
    ),
  );
}
