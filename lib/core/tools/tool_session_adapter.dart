import '../session/session.dart';
import 'tool_module.dart';

/// Tool-neutral data rendered by the history experience.
final class ToolHistorySummary {
  const ToolHistorySummary({
    required this.toolId,
    required this.toolName,
    required this.summary,
    required this.status,
  });

  final String toolId;
  final String toolName;
  final String summary;
  final SessionStatus status;
}

/// Tool-neutral content rendered by any platform share integration.
final class ToolSharePayload {
  const ToolSharePayload({
    required this.title,
    required this.summary,
    required this.plainText,
  });

  final String title;
  final String summary;
  final String plainText;
}

/// Typed domain values decoded from a shared session envelope.
final class DecodedToolSession {
  const DecodedToolSession({required this.input, required this.outcome});

  final Object input;
  final Object outcome;
}

typedef ToolShareRenderer = ToolSharePayload Function(
  ToolDescriptor descriptor,
  SessionRecord session,
  String summary,
);

/// Unified feature boundary for session creation, history, and sharing.
///
/// Every [ToolModule] automatically receives this default adapter from the
/// registry. A module can implement [ToolSessionAdapterProvider] when its share
/// representation needs feature-specific rendering.
final class ToolSessionAdapter {
  ToolSessionAdapter({
    required this.descriptor,
    required this.codec,
    ToolShareRenderer? shareRenderer,
  }) : _shareRenderer = shareRenderer ?? _defaultShareRenderer {
    if (descriptor.id != codec.toolId) {
      throw ArgumentError(
        'Codec ${codec.toolId} does not match ${descriptor.id}.',
      );
    }
  }

  final ToolDescriptor descriptor;
  final ToolSessionCodec codec;
  final ToolShareRenderer _shareRenderer;

  SessionRecord createSession({
    required String id,
    required int schemaVersion,
    required String ruleVersion,
    required String algorithmVersion,
    required SessionStatus status,
    required Object input,
    required Object outcome,
    String? parentSessionId,
  }) {
    return SessionRecord(
      id: id,
      toolId: descriptor.id,
      schemaVersion: schemaVersion,
      ruleVersion: ruleVersion,
      algorithmVersion: algorithmVersion,
      status: status,
      input: codec.encodeInput(input),
      outcome: codec.encodeOutcome(outcome),
      parentSessionId: parentSessionId,
    );
  }

  DecodedToolSession decode(SessionRecord session) {
    _validateSession(session);
    final input = codec.decodeInput(session.input);
    return DecodedToolSession(
      input: input,
      outcome: codec.decodeOutcome(session.outcome, input),
    );
  }

  ToolHistorySummary historySummary(SessionRecord session) {
    _validateSession(session);
    return ToolHistorySummary(
      toolId: descriptor.id,
      toolName: descriptor.name,
      summary: codec.summarize(session),
      status: session.status,
    );
  }

  ToolSharePayload sharePayload(SessionRecord session) {
    _validateSession(session);
    return _shareRenderer(descriptor, session, codec.summarize(session));
  }

  void _validateSession(SessionRecord session) {
    if (session.toolId != descriptor.id) {
      throw ArgumentError(
        'Session ${session.id} belongs to ${session.toolId}, not '
        '${descriptor.id}.',
      );
    }
  }

  static ToolSharePayload _defaultShareRenderer(
    ToolDescriptor descriptor,
    SessionRecord session,
    String summary,
  ) {
    return ToolSharePayload(
      title: descriptor.name,
      summary: summary,
      plainText: <String>[
        'Pocketools · ${descriptor.name}',
        summary,
        '规则版本：${session.ruleVersion}',
        '算法版本：${session.algorithmVersion}',
      ].join('\n'),
    );
  }
}

/// Optional capability for modules that need a custom share representation.
/// Codec-only modules do not need to implement it.
abstract interface class ToolSessionAdapterProvider {
  ToolSessionAdapter get toolSessionAdapter;
}

ToolSessionAdapter resolveToolSessionAdapter(ToolModule module) {
  if (module case ToolSessionAdapterProvider provider) {
    return provider.toolSessionAdapter;
  }
  return ToolSessionAdapter(
    descriptor: module.descriptor,
    codec: module.sessionCodec,
  );
}
