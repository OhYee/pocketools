import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/presentation/app_settings_controller.dart';
import 'package:pocketools/app/presentation/history_page.dart';
import 'package:pocketools/app/presentation/settings_page.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_history.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';
import 'package:pocketools/design_system/app_theme.dart';

void main() {
  testWidgets(
    'history filters tool favorite age and private note without changing result',
    (tester) async {
      final now = DateTime.now().toUtc();
      final recent = _entry(
        id: 'recent',
        toolId: 'fake',
        result: 'recent result',
        savedAtUtc: now.subtract(const Duration(hours: 1)),
        favorite: true,
        note: 'private searchable phrase',
      );
      final eightDays = _entry(
        id: 'eight-days',
        toolId: 'fake',
        result: 'eight day result',
        savedAtUtc: now.subtract(const Duration(days: 8)),
      );
      final other = _entry(
        id: 'other',
        toolId: 'other',
        result: 'other result',
        savedAtUtc: now.subtract(const Duration(days: 31)),
      );
      final repository = _QaHistory(<HistoryEntry>[other, recent, eightDays]);
      final registry = _registry();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: HistoryPage(
            registry: registry,
            repository: repository,
            onReplay: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_text('recent result'), findsOneWidget);
      expect(_text('eight day result'), findsOneWidget);
      expect(_text('other result'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'searchable phrase');
      await tester.pump();
      expect(_text('recent result'), findsOneWidget);
      expect(_text('eight day result'), findsNothing);
      expect(_text('other result'), findsNothing);

      await tester.enterText(find.byType(TextField).first, '');
      await tester.tap(find.text('7 天'));
      await tester.pump();
      expect(_text('recent result'), findsOneWidget);
      expect(_text('eight day result'), findsNothing);

      await tester.tap(find.text('全部'));
      await tester.tap(find.text('只看收藏'));
      await tester.pump();
      expect(_text('recent result'), findsOneWidget);
      expect(_text('eight day result'), findsNothing);

      await tester.tap(find.text('只看收藏'));
      await tester.tap(find.text('全部工具'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other Tool').last);
      await tester.pumpAndSettle();
      expect(_text('other result'), findsOneWidget);
      expect(_text('recent result'), findsNothing);

      await tester.tap(find.text('Other Tool').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fake Tool').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('查看详情').first);
      await tester.tap(find.text('查看详情').first);
      await tester.pumpAndSettle();
      final frozen = repository.entries['recent']!.session;
      await tester.tap(find.text('收藏'));
      await tester.enterText(
        find.widgetWithText(TextField, '私人备注'),
        'updated local note',
      );
      await tester.tap(find.text('保存注释'));
      await tester.pumpAndSettle();

      final annotated = repository.entries['recent']!;
      expect(annotated.session, same(frozen));
      expect(annotated.session.outcome['result'], 'recent result');
      expect(annotated.annotation.favorite, isFalse);
      expect(annotated.annotation.privateNote, 'updated local note');
    },
  );

  testWidgets('single tool and all deletion require explicit confirmation', (
    tester,
  ) async {
    final now = DateTime.now().toUtc();
    final repository = _QaHistory(<HistoryEntry>[
      _entry(id: 'fake-1', toolId: 'fake', result: 'fake one', savedAtUtc: now),
      _entry(
        id: 'other-1',
        toolId: 'other',
        result: 'other one',
        savedAtUtc: now,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: HistoryPage(
          registry: _registry(),
          repository: repository,
          onReplay: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('查看详情').first);
    await tester.tap(find.text('查看详情').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(repository.deleteByIdCalls, 0);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();
    expect(repository.deleteByIdCalls, 1);
    expect(repository.entries, hasLength(1));

    await tester.tap(find.text('全部工具'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other Tool').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除当前工具历史'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(repository.deleteByToolCalls, 0);
    await tester.tap(find.text('删除当前工具历史'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();
    expect(repository.deleteByToolCalls, 1);
    expect(repository.entries, isEmpty);

    repository.entries.addAll(<String, HistoryEntry>{
      'fake-2': _entry(
        id: 'fake-2',
        toolId: 'fake',
        result: 'fake two',
        savedAtUtc: now,
      ),
    });
    await tester.tap(find.text('刷新'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清除全部历史'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(repository.clearCalls, 0);
    await tester.tap(find.text('清除全部历史'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();
    expect(repository.clearCalls, 1);
    expect(repository.entries, isEmpty);
  });

  testWidgets(
    'settings privacy entries and clear confirmation work by keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _QaHistory(<HistoryEntry>[
        _entry(
          id: 'settings-history',
          toolId: 'fake',
          result: 'result',
          savedAtUtc: DateTime.now().toUtc(),
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SettingsPage(
              settings: AppSettingsController(),
              historyRepository: repository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('随机过程'), findsOneWidget);
      expect(find.text('隐私与本地数据'), findsOneWidget);
      expect(find.text('开源许可'), findsNothing);
      expect(find.text('查看第三方许可'), findsNothing);

      await tester.ensureVisible(find.text('清除全部本地历史'));
      final button = find.text('清除全部本地历史');
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(repository.clearCalls, 0);

      await tester.tap(button);
      await tester.pumpAndSettle();
      final confirm = find.text('确认清除');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(repository.clearCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}

ToolRegistry _registry() => ToolRegistry(<ToolModule>[
  const _HistoryModule(id: 'fake', name: 'Fake Tool', route: '/fake'),
  const _HistoryModule(id: 'other', name: 'Other Tool', route: '/other'),
]);

Finder _text(String value) => find.byWidgetPredicate(
  (widget) => widget is Text && widget.data == value,
  description: 'Text("$value")',
);

HistoryEntry _entry({
  required String id,
  required String toolId,
  required String result,
  required DateTime savedAtUtc,
  bool favorite = false,
  String? note,
}) => HistoryEntry(
  session: SessionRecord(
    id: id,
    toolId: toolId,
    schemaVersion: 1,
    ruleVersion: '$toolId/rule-v1',
    algorithmVersion: '$toolId/algorithm-v1',
    status: SessionStatus.completed,
    input: const <String, Object?>{'config': 'safe'},
    outcome: <String, Object?>{'result': result},
  ),
  savedAtUtc: savedAtUtc,
  annotation: SessionAnnotation(favorite: favorite, privateNote: note),
);

final class _HistoryModule implements ToolModule {
  const _HistoryModule({
    required this.id,
    required this.name,
    required this.route,
  });

  final String id;
  final String name;
  final String route;

  @override
  ToolDescriptor get descriptor => ToolDescriptor(
    id: id,
    name: name,
    description: 'Stage 2C history fixture',
    route: route,
    icon: Icons.extension_outlined,
    accent: ToolAccent.neutral,
  );

  @override
  ToolSessionCodec get sessionCodec => _HistoryCodec(id);

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      const SizedBox.shrink();
}

final class _HistoryCodec implements ToolSessionCodec {
  const _HistoryCodec(this.toolId);

  @override
  final String toolId;

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

final class _QaHistory implements SessionHistoryRepository {
  _QaHistory(Iterable<HistoryEntry> values)
    : entries = <String, HistoryEntry>{
        for (final entry in values) entry.session.id: entry,
      };

  final Map<String, HistoryEntry> entries;
  var clearCalls = 0;
  var deleteByIdCalls = 0;
  var deleteByToolCalls = 0;

  @override
  Future<void> clearHistory() async {
    clearCalls++;
    entries.clear();
  }

  @override
  Future<void> deleteById(String id) async {
    deleteByIdCalls++;
    entries.remove(id);
  }

  @override
  Future<void> deleteByTool(String toolId) async {
    deleteByToolCalls++;
    entries.removeWhere((_, entry) => entry.session.toolId == toolId);
  }

  @override
  Future<HistoryEntry?> findHistoryEntry(String id) async => entries[id];

  @override
  Future<List<HistoryEntry>> listHistory({String? toolId}) async => entries
      .values
      .where((entry) => toolId == null || entry.session.toolId == toolId)
      .toList(growable: false);

  @override
  Future<SessionLoadReport> loadReport() async => SessionLoadReport();

  @override
  Future<void> updateAnnotation(String id, SessionAnnotation annotation) async {
    final entry = entries[id];
    if (entry != null) entries[id] = entry.withAnnotation(annotation);
  }
}
