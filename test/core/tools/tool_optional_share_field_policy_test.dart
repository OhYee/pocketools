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
  group('shared optional share field policy', () {
    test('allows only the reviewed question and intention categories', () {
      final fields = _filtered(<ToolOptionalShareField>[
        const ToolOptionalShareField(
          id: 'question',
          label: '问题',
          value: '是否继续？',
        ),
        const ToolOptionalShareField(
          id: 'intention',
          label: '问题或意图',
          value: '梳理下一步',
        ),
        const ToolOptionalShareField(
          id: 'comment',
          label: '附加内容',
          value: 'not reviewed',
        ),
      ]);

      expect(fields.map((field) => field.id), <String>[
        'question',
        'intention',
      ]);
    });

    test('rejects identifier aliases, casing, and disguised labels', () {
      for (final field in <ToolOptionalShareField>[
        const ToolOptionalShareField(
          id: 'SeSsIoN_Id',
          label: '附加内容',
          value: 'value',
        ),
        const ToolOptionalShareField(
          id: 'parentIdentifier',
          label: '附加内容',
          value: 'value',
        ),
        const ToolOptionalShareField(
          id: 'DEVICE-ID',
          label: '附加内容',
          value: 'value',
        ),
        const ToolOptionalShareField(
          id: 'question',
          label: '父会话标识',
          value: 'value',
        ),
        const ToolOptionalShareField(
          id: 'intention',
          label: 'Device Identifier',
          value: 'value',
        ),
      ]) {
        expect(_filtered(<ToolOptionalShareField>[field]), isEmpty);
      }
    });

    test('rejects duplicate, empty, overlong, and control fields', () {
      expect(
        _filtered(const <ToolOptionalShareField>[
          ToolOptionalShareField(id: 'question', label: '问题', value: 'one'),
          ToolOptionalShareField(id: 'question', label: '另一个问题', value: 'two'),
        ]),
        isEmpty,
      );
      for (final field in <ToolOptionalShareField>[
        const ToolOptionalShareField(
          id: 'question',
          label: '   ',
          value: 'value',
        ),
        const ToolOptionalShareField(id: 'question', label: '问题', value: ''),
        const ToolOptionalShareField(
          id: 'question',
          label: '问题\n伪装',
          value: 'value',
        ),
        ToolOptionalShareField(id: 'question', label: '问题', value: 'x' * 2001),
      ]) {
        expect(_filtered(<ToolOptionalShareField>[field]), isEmpty);
      }
    });

    test('rejects values containing current or parent session identifiers', () {
      for (final value in <String>[
        'before ${_session.id} after',
        'before ${_session.parentSessionId} after',
        _session.id.toUpperCase(),
      ]) {
        expect(
          _filtered(<ToolOptionalShareField>[
            ToolOptionalShareField(id: 'question', label: '问题', value: value),
          ]),
          isEmpty,
        );
      }
    });
  });

  test('preview rejects poisoned default payload before any gateway call', () {
    for (final poison in <String Function(SessionRecord)>[
      (session) => 'public ${session.id}',
      (session) => 'public ${session.parentSessionId}',
    ]) {
      final registry = ToolRegistry(<ToolModule>[
        _PolicyModule(payloadText: poison),
      ]);
      final gateway = _RecordingGateway();
      final controller = SessionActionsController(
        registry: registry,
        historyRepository: const _EmptyHistoryRepository(),
        textGateway: gateway,
      );

      expect(controller.preview(_session), throwsFormatException);
      expect(gateway.shareCalls, 0);
      expect(gateway.copyCalls, 0);
    }
  });
}

List<ToolOptionalShareField> _filtered(List<ToolOptionalShareField> fields) {
  final registry = ToolRegistry(<ToolModule>[_PolicyModule(fields: fields)]);
  return registry.optionalShareFields(_session);
}

final SessionRecord _session = SessionRecord(
  id: 'Session-Secret-AbC123',
  toolId: 'privacy-policy',
  schemaVersion: 1,
  ruleVersion: 'privacy-policy/rule-v1',
  algorithmVersion: 'privacy-policy/algorithm-v1',
  status: SessionStatus.completed,
  input: const <String, Object?>{},
  outcome: const <String, Object?>{'result': 'public'},
  parentSessionId: 'Parent-Secret-XyZ789',
);

final class _PolicyModule
    with ToolPrivacyCapabilities
    implements ToolModule, ToolSessionAdapterProvider {
  _PolicyModule({
    this.fields = const <ToolOptionalShareField>[],
    this.payloadText,
  });

  final List<ToolOptionalShareField> fields;
  final String Function(SessionRecord session)? payloadText;

  @override
  ToolDescriptor get descriptor => const ToolDescriptor(
    id: 'privacy-policy',
    name: 'Privacy Policy',
    description: 'Shared optional share policy fixture',
    route: '/privacy-policy',
    icon: Icons.privacy_tip_outlined,
    accent: ToolAccent.neutral,
  );

  @override
  ToolSessionCodec get sessionCodec => const _PolicyCodec();

  @override
  ToolSessionAdapter get toolSessionAdapter => ToolSessionAdapter(
    descriptor: descriptor,
    codec: sessionCodec,
    shareRenderer: (descriptor, session, summary) => ToolSharePayload(
      title: descriptor.name,
      summary: summary,
      plainText: payloadText?.call(session) ?? summary,
    ),
  );

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      const SizedBox.shrink();

  @override
  List<ToolOptionalShareField> optionalShareFields(
    SessionRecord session,
    DecodedToolSession decoded,
  ) => fields;

  @override
  Object replayInput(SessionRecord session, DecodedToolSession decoded) =>
      decoded.input;
}

final class _PolicyCodec implements ToolSessionCodec {
  const _PolicyCodec();

  @override
  String get toolId => 'privacy-policy';

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
  String summarize(SessionRecord session) => 'public';
}

final class _RecordingGateway implements SessionTextGateway {
  var shareCalls = 0;
  var copyCalls = 0;

  @override
  Future<SessionTextActionOutcome> copyText(String text) async {
    copyCalls++;
    return SessionTextActionOutcome.copiedToClipboard;
  }

  @override
  Future<SessionTextActionOutcome> shareText({
    required String title,
    required String text,
  }) async {
    shareCalls++;
    return SessionTextActionOutcome.shared;
  }
}

final class _EmptyHistoryRepository implements SessionHistoryRepository {
  const _EmptyHistoryRepository();

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
