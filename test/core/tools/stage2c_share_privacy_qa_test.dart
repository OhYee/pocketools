import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_history.dart';
import 'package:pocketools/core/tools/session_actions.dart';
import 'package:pocketools/core/tools/tool_capabilities.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';
import 'package:pocketools/core/tools/tool_session_adapter.dart';

void main() {
  group('Stage 2C independent share privacy boundary', () {
    test(
      'default and explicit share expose only user-approved safe fields',
      () async {
        final fixture = _ShareFixture(const _SafePrivateModule());
        final preview = await fixture.controller.preview(fixture.session);

        expect(preview.compose(), contains('public-result'));
        expect(preview.compose(), isNot(contains(_ShareFixture.question)));
        expect(preview.compose(), isNot(contains(_ShareFixture.note)));
        expect(preview.compose(), isNot(contains(fixture.session.id)));
        expect(
          preview.compose(),
          isNot(contains(fixture.session.parentSessionId!)),
        );
        expect(
          preview.compose(),
          isNot(contains(fixture.entry.savedAtUtc.toIso8601String())),
        );

        final approved = preview.compose(
          includedFieldIds: const <String>{'question'},
          includePrivateNote: true,
          includeTime: true,
        );
        expect(approved, contains(_ShareFixture.question));
        expect(approved, contains(_ShareFixture.note));
        expect(approved, contains(fixture.entry.savedAtUtc.toIso8601String()));
        expect(approved, isNot(contains(fixture.session.id)));
        expect(approved, isNot(contains(fixture.session.parentSessionId!)));

        final originalInput = fixture.session.input;
        final originalOutcome = fixture.session.outcome;
        expect(
          await fixture.controller.copy(
            preview,
            includedFieldIds: const <String>{'question'},
          ),
          SessionTextActionOutcome.copiedToClipboard,
        );
        expect(
          await fixture.controller.share(preview),
          SessionTextActionOutcome.shared,
        );
        expect(fixture.gateway.copyCalls, 1);
        expect(fixture.gateway.shareCalls, 1);
        expect(fixture.session.input, same(originalInput));
        expect(fixture.session.outcome, same(originalOutcome));
        expect(
          (await fixture.history.findHistoryEntry(fixture.session.id))!.session,
          same(fixture.session),
        );
      },
    );

    test(
      'module cannot make session parent or device identifiers selectable',
      () async {
        final fixture = _ShareFixture(const _IdentifierExfiltrationModule());
        final preview = await fixture.controller.preview(fixture.session);

        expect(preview.optionalFields.map((field) => field.id), <String>[
          'question',
        ], reason: 'The shared layer must reject identifier-shaped options.');
        final attempted = preview.compose(
          includedFieldIds: const <String>{
            'question',
            'sessionId',
            'parentSessionId',
            'deviceId',
          },
        );
        expect(attempted, contains(_ShareFixture.question));
        expect(attempted, isNot(contains(fixture.session.id)));
        expect(attempted, isNot(contains(fixture.session.parentSessionId!)));
        expect(attempted, isNot(contains(_ShareFixture.deviceId)));
      },
    );
  });
}

final class _ShareFixture {
  _ShareFixture(ToolModule module)
    : registry = ToolRegistry(<ToolModule>[module]),
      session = SessionRecord(
        id: 'private-session-6f5a',
        toolId: 'privacy-fake',
        schemaVersion: 1,
        ruleVersion: 'privacy/rule-v1',
        algorithmVersion: 'privacy/algorithm-v1',
        status: SessionStatus.completed,
        input: const <String, Object?>{
          'question': question,
          'device': deviceId,
        },
        outcome: const <String, Object?>{'result': 'public-result'},
        parentSessionId: 'private-parent-4e3b',
      ) {
    entry = HistoryEntry(
      session: session,
      savedAtUtc: DateTime.utc(2026, 8, 23, 9, 8, 7),
      annotation: SessionAnnotation(privateNote: note),
    );
    history = _History(entry);
    controller = SessionActionsController(
      registry: registry,
      historyRepository: history,
      textGateway: gateway,
    );
  }

  static const question = 'PRIVATE_QUESTION_STAGE2C';
  static const note = 'PRIVATE_NOTE_STAGE2C';
  static const deviceId = 'PRIVATE_DEVICE_STAGE2C';

  final ToolRegistry registry;
  final SessionRecord session;
  late final HistoryEntry entry;
  late final _History history;
  final _CapturingGateway gateway = _CapturingGateway();
  late final SessionActionsController controller;
}

class _SafePrivateModule with ToolPrivacyCapabilities implements ToolModule {
  const _SafePrivateModule();

  @override
  ToolDescriptor get descriptor => const ToolDescriptor(
    id: 'privacy-fake',
    name: 'Privacy Fake',
    description: 'Independent Stage 2C privacy fixture',
    route: '/tools/privacy-fake',
    icon: Icons.privacy_tip_outlined,
    accent: ToolAccent.neutral,
  );

  @override
  ToolSessionCodec get sessionCodec => const _PrivacyCodec();

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      const SizedBox.shrink();

  @override
  List<ToolOptionalShareField> optionalShareFields(
    SessionRecord session,
    DecodedToolSession decoded,
  ) => const <ToolOptionalShareField>[
    ToolOptionalShareField(
      id: 'question',
      label: '问题',
      value: _ShareFixture.question,
    ),
  ];

  @override
  Object replayInput(SessionRecord session, DecodedToolSession decoded) =>
      const <String, Object?>{};
}

final class _IdentifierExfiltrationModule extends _SafePrivateModule {
  const _IdentifierExfiltrationModule();

  @override
  List<ToolOptionalShareField> optionalShareFields(
    SessionRecord session,
    DecodedToolSession decoded,
  ) => <ToolOptionalShareField>[
    ...super.optionalShareFields(session, decoded),
    ToolOptionalShareField(id: 'sessionId', label: '会话标识', value: session.id),
    ToolOptionalShareField(
      id: 'parentSessionId',
      label: '父会话标识',
      value: session.parentSessionId!,
    ),
    const ToolOptionalShareField(
      id: 'deviceId',
      label: '设备标识',
      value: _ShareFixture.deviceId,
    ),
  ];
}

final class _PrivacyCodec implements ToolSessionCodec {
  const _PrivacyCodec();

  @override
  String get toolId => 'privacy-fake';

  @override
  Map<String, Object?> decodeInput(Map<String, Object?> input) => input;

  @override
  Map<String, Object?> decodeOutcome(
    Map<String, Object?> outcome,
    Object input,
  ) => outcome;

  @override
  Map<String, Object?> encodeInput(Object input) =>
      Map<String, Object?>.of(input as Map<String, Object?>);

  @override
  Map<String, Object?> encodeOutcome(Object outcome) =>
      Map<String, Object?>.of(outcome as Map<String, Object?>);

  @override
  String summarize(SessionRecord session) =>
      session.outcome['result']! as String;
}

final class _History implements SessionHistoryRepository {
  _History(this.entry);

  HistoryEntry entry;

  @override
  Future<void> clearHistory() async {}

  @override
  Future<void> deleteById(String id) async {}

  @override
  Future<void> deleteByTool(String toolId) async {}

  @override
  Future<HistoryEntry?> findHistoryEntry(String id) async =>
      entry.session.id == id ? entry : null;

  @override
  Future<List<HistoryEntry>> listHistory({String? toolId}) async =>
      <HistoryEntry>[entry];

  @override
  Future<SessionLoadReport> loadReport() async => SessionLoadReport();

  @override
  Future<void> updateAnnotation(String id, SessionAnnotation annotation) async {
    entry = entry.withAnnotation(annotation);
  }
}

final class _CapturingGateway implements SessionTextGateway {
  var copyCalls = 0;
  var shareCalls = 0;
  String? lastText;

  @override
  Future<SessionTextActionOutcome> copyText(String text) async {
    copyCalls++;
    lastText = text;
    return SessionTextActionOutcome.copiedToClipboard;
  }

  @override
  Future<SessionTextActionOutcome> shareText({
    required String title,
    required String text,
  }) async {
    shareCalls++;
    lastText = text;
    return SessionTextActionOutcome.shared;
  }
}
