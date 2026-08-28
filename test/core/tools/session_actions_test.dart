import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_history.dart';
import 'package:pocketools/core/tools/session_actions.dart';
import 'package:pocketools/core/tools/tool_capabilities.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';
import 'package:pocketools/core/tools/tool_session_adapter.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/design_system/components/app_session_actions.dart';

void main() {
  test(
    'preview is private by default and replay uses module capability',
    () async {
      final fixture = _Fixture();
      final preview = await fixture.controller.preview(fixture.session);

      expect(preview.compose(), contains('Fake result public-value'));
      for (final secret in <String>[
        _Fixture.secret,
        _Fixture.note,
        fixture.session.id,
        fixture.session.parentSessionId!,
        fixture.entry.savedAtUtc.toIso8601String(),
      ]) {
        expect(preview.compose(), isNot(contains(secret)));
      }
      expect(
        preview.compose(
          includedFieldIds: const <String>{'question'},
          includePrivateNote: true,
          includeTime: true,
        ),
        allOf(
          contains(_Fixture.secret),
          contains(_Fixture.note),
          contains(fixture.entry.savedAtUtc.toIso8601String()),
        ),
      );

      final replay = fixture.registry.replayRequest(fixture.session);
      expect(replay.toolId, 'fake');
      expect(replay.parentSessionId, fixture.session.id);
      expect(replay.initialConfig, <String, Object?>{'public': 'public-value'});
    },
  );

  testWidgets('shared preview keeps dismissal distinct at 360px and 200%', (
    tester,
  ) async {
    final fixture = _Fixture();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppSessionActions(
              session: fixture.session,
              controller: fixture.controller,
              regenerateLabel: '再次生成',
              onRegenerate: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('复制或分享'));
    await tester.pumpAndSettle();
    final preview = tester.widget<SelectableText>(
      find.byKey(const Key('session-share-preview-text')),
    );
    expect(preview.data, isNot(contains(_Fixture.secret)));
    expect(preview.data, isNot(contains(_Fixture.note)));

    await tester.ensureVisible(find.text('系统分享'));
    await tester.tap(find.text('系统分享'));
    await tester.pump();
    expect(find.text('已取消分享，未复制文本。'), findsOneWidget);
    expect(fixture.gateway.shareCalls, 1);
    expect(fixture.gateway.copyCalls, 0);
    expect(tester.takeException(), isNull);
  });
}

final class _Fixture {
  _Fixture()
    : registry = ToolRegistry(<ToolModule>[_PrivateFakeModule()]),
      session = SessionRecord(
        id: 'never-share-session-id',
        toolId: 'fake',
        schemaVersion: 1,
        ruleVersion: 'fake-rule-v1',
        algorithmVersion: 'fake-algorithm-v1',
        status: SessionStatus.completed,
        input: const <String, Object?>{
          'public': 'public-value',
          'question': secret,
        },
        outcome: const <String, Object?>{'result': 'public-value'},
        parentSessionId: 'never-share-parent-id',
      ) {
    entry = HistoryEntry(
      session: session,
      savedAtUtc: DateTime.utc(2026, 8, 23, 8),
      annotation: SessionAnnotation(privateNote: note),
    );
    history = _SingleEntryHistory(entry);
    controller = SessionActionsController(
      registry: registry,
      historyRepository: history,
      textGateway: gateway,
    );
  }

  static const secret = 'PRIVATE_QUESTION';
  static const note = 'PRIVATE_NOTE';

  final ToolRegistry registry;
  final SessionRecord session;
  late final HistoryEntry entry;
  late final _SingleEntryHistory history;
  final _DismissedGateway gateway = _DismissedGateway();
  late final SessionActionsController controller;
}

final class _PrivateFakeModule
    with ToolPrivacyCapabilities
    implements ToolModule {
  @override
  ToolDescriptor get descriptor => const ToolDescriptor(
    id: 'fake',
    name: 'Fake',
    description: 'Fake module',
    route: '/fake',
    icon: Icons.extension,
    accent: ToolAccent.neutral,
  );

  @override
  ToolSessionCodec get sessionCodec => const _FakeCodec();

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      const SizedBox.shrink();

  @override
  List<ToolOptionalShareField> optionalShareFields(
    SessionRecord session,
    DecodedToolSession decoded,
  ) => <ToolOptionalShareField>[
    ToolOptionalShareField(
      id: 'question',
      label: '问题',
      value: (decoded.input as Map<String, Object?>)['question']! as String,
    ),
  ];

  @override
  Object replayInput(SessionRecord session, DecodedToolSession decoded) =>
      <String, Object?>{
        'public': (decoded.input as Map<String, Object?>)['public'],
      };
}

final class _FakeCodec implements ToolSessionCodec {
  const _FakeCodec();

  @override
  String get toolId => 'fake';

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
      'Fake result ${session.outcome['result']}';
}

final class _DismissedGateway implements SessionTextGateway {
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
    return SessionTextActionOutcome.dismissed;
  }
}

final class _SingleEntryHistory implements SessionHistoryRepository {
  _SingleEntryHistory(this.entry);

  final HistoryEntry entry;

  @override
  Future<void> clearHistory() async {}

  @override
  Future<void> deleteById(String id) async {}

  @override
  Future<void> deleteByTool(String toolId) async {}

  @override
  Future<HistoryEntry?> findHistoryEntry(String id) async =>
      id == entry.session.id ? entry : null;

  @override
  Future<List<HistoryEntry>> listHistory({String? toolId}) async =>
      <HistoryEntry>[entry];

  @override
  Future<SessionLoadReport> loadReport() async => SessionLoadReport();

  @override
  Future<void> updateAnnotation(
    String id,
    SessionAnnotation annotation,
  ) async {}
}
