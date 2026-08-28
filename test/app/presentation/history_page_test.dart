import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/presentation/history_page.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_history.dart';
import 'package:pocketools/core/tools/session_actions.dart';
import 'package:pocketools/core/tools/tool_capabilities.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';
import 'package:pocketools/core/tools/tool_session_adapter.dart';
import 'package:pocketools/design_system/app_theme.dart';

void main() {
  testWidgets('history is generic, newest first, searchable and replayable', (
    tester,
  ) async {
    final registry = ToolRegistry(<ToolModule>[_ReplayFakeModule()]);
    final oldEntry = _entry(
      id: 'history-old-001',
      result: 'old result',
      savedAtUtc: DateTime.utc(2026, 8, 20),
      favorite: true,
      privateNote: 'local private marker',
    );
    final newEntry = _entry(
      id: 'history-new-002',
      result: 'new result',
      savedAtUtc: DateTime.utc(2026, 8, 23),
    );
    final repository = _MutableHistory(<HistoryEntry>[oldEntry, newEntry]);
    final actions = SessionActionsController(
      registry: registry,
      historyRepository: repository,
      textGateway: const NoopSessionTextGateway(),
    );
    ToolLaunchRequest? replay;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: HistoryPage(
          registry: registry,
          repository: repository,
          onReplay: (request) => replay = request,
          sessionActions: actions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final newResultText = _plainText('new result');
    final oldResultText = _plainText('old result');
    expect(newResultText, findsOneWidget);
    expect(oldResultText, findsOneWidget);
    expect(
      tester.getTopLeft(newResultText).dy,
      lessThan(tester.getTopLeft(oldResultText).dy),
    );

    await tester.enterText(
      find.byType(TextField).first,
      'local private marker',
    );
    await tester.pump();
    expect(_plainText('old result'), findsOneWidget);
    expect(_plainText('new result'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'new result');
    await tester.pump();
    expect(_plainText('new result'), findsOneWidget);
    expect(_plainText('old result'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();
    await tester.ensureVisible(find.text('查看详情').first);
    await tester.tap(find.text('查看详情').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('规则：fake-rule-v1'), findsOneWidget);
    expect(find.textContaining('算法：fake-algorithm-v1'), findsOneWidget);

    await tester.tap(find.text('复制或分享'));
    await tester.pumpAndSettle();
    final preview = tester.widget<SelectableText>(
      find.byKey(const Key('session-share-preview-text')),
    );
    expect(preview.data, isNot(contains('local private marker')));
    await tester.tap(find.text('取消').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('复用配置'));
    await tester.pumpAndSettle();
    expect(replay, isNotNull);
    expect(replay!.toolId, 'fake');
    expect(replay!.parentSessionId, 'history-new-002');
    expect(replay!.initialConfig, <String, Object?>{'value': 'public'});
  });

  testWidgets('history stays usable at 360px and 200% text', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final registry = ToolRegistry(<ToolModule>[_ReplayFakeModule()]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: HistoryPage(
          registry: registry,
          repository: _MutableHistory(<HistoryEntry>[
            _entry(
              id: 'large-text',
              result: 'large text result',
              savedAtUtc: DateTime.utc(2026, 8, 23),
            ),
          ]),
          onReplay: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(_plainText('large text result'));

    expect(find.text('large text result'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown codec disables history share and replay safely', (
    tester,
  ) async {
    final registry = ToolRegistry(<ToolModule>[_ReplayFakeModule()]);
    final repository = _MutableHistory(<HistoryEntry>[
      _entry(
        id: 'unknown',
        toolId: 'removed-tool',
        result: 'unknown result',
        savedAtUtc: DateTime.utc(2026, 8, 23),
      ),
    ]);
    final actions = SessionActionsController(
      registry: registry,
      historyRepository: repository,
      textGateway: const NoopSessionTextGateway(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: HistoryPage(
          registry: registry,
          repository: repository,
          sessionActions: actions,
          onReplay: (_) => fail('Unknown sessions must not replay.'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('查看详情'));
    await tester.tap(find.text('查看详情'));
    await tester.pumpAndSettle();

    expect(find.text('此结果无法由当前版本解码。'), findsWidgets);
    expect(find.text('复制或分享'), findsNothing);
    expect(find.text('复用配置'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Finder _plainText(String value) => find.byWidgetPredicate(
  (widget) => widget is Text && widget.data == value,
  description: 'Text("$value")',
);

HistoryEntry _entry({
  required String id,
  required String result,
  required DateTime savedAtUtc,
  String toolId = 'fake',
  bool favorite = false,
  String? privateNote,
}) => HistoryEntry(
  session: SessionRecord(
    id: id,
    toolId: toolId,
    schemaVersion: 1,
    ruleVersion: 'fake-rule-v1',
    algorithmVersion: 'fake-algorithm-v1',
    status: SessionStatus.completed,
    input: const <String, Object?>{'value': 'public', 'private': 'secret'},
    outcome: <String, Object?>{'result': result},
  ),
  savedAtUtc: savedAtUtc,
  annotation: SessionAnnotation(favorite: favorite, privateNote: privateNote),
);

final class _ReplayFakeModule implements ToolModule, ToolReplayCapability {
  @override
  ToolDescriptor get descriptor => const ToolDescriptor(
    id: 'fake',
    name: 'Fake Tool',
    description: 'Fake history module',
    route: '/fake',
    icon: Icons.extension,
    accent: ToolAccent.neutral,
  );

  @override
  ToolSessionCodec get sessionCodec => const _HistoryCodec();

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      const SizedBox.shrink();

  @override
  Object replayInput(SessionRecord session, DecodedToolSession decoded) =>
      <String, Object?>{
        'value': (decoded.input as Map<String, Object?>)['value'],
      };
}

final class _HistoryCodec implements ToolSessionCodec {
  const _HistoryCodec();

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
      session.outcome['result']! as String;
}

final class _MutableHistory implements SessionHistoryRepository {
  _MutableHistory(Iterable<HistoryEntry> entries)
    : _entries = <String, HistoryEntry>{
        for (final entry in entries) entry.session.id: entry,
      };

  final Map<String, HistoryEntry> _entries;

  @override
  Future<void> clearHistory() async => _entries.clear();

  @override
  Future<void> deleteById(String id) async => _entries.remove(id);

  @override
  Future<void> deleteByTool(String toolId) async =>
      _entries.removeWhere((_, entry) => entry.session.toolId == toolId);

  @override
  Future<HistoryEntry?> findHistoryEntry(String id) async => _entries[id];

  @override
  Future<List<HistoryEntry>> listHistory({String? toolId}) async => _entries
      .values
      .where((entry) => toolId == null || entry.session.toolId == toolId)
      .toList(growable: false);

  @override
  Future<SessionLoadReport> loadReport() async => SessionLoadReport();

  @override
  Future<void> updateAnnotation(String id, SessionAnnotation annotation) async {
    final entry = _entries[id];
    if (entry != null) _entries[id] = entry.withAnnotation(annotation);
  }
}
