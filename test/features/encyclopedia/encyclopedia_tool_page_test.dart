import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/pocketools_app.dart';
import 'package:pocketools/app/presentation/app_settings_controller.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/design_system/components/app_runtime_asset.dart';
import 'package:pocketools/features/encyclopedia/presentation/encyclopedia_tool_page.dart';

void main() {
  testWidgets('encyclopedia browses Tarot cards and Liuyao hexagrams', (
    tester,
  ) async {
    await tester.pumpWidget(
      PocketoolsApp(
        randomSource: SequenceRandomSource(const <int>[0]),
        feedbackService: const NoopFeedbackService(),
        settings: AppSettingsController(reduceMotion: true),
      ),
    );

    final encyclopediaEntry = find.text('塔罗/周易图鉴').first;
    await tester.ensureVisible(encyclopediaEntry);
    await tester.tap(encyclopediaEntry);
    await tester.pump();

    expect(find.byKey(const Key('encyclopedia-page')), findsOneWidget);
    expect(find.byKey(const Key('encyclopedia-tarot-grid')), findsOneWidget);
    expect(
      find.byKey(const Key('encyclopedia-tarot-major-00-fool')),
      findsOneWidget,
    );
    expect(find.byType(RuntimeAssetSlot), findsNWidgets(78));

    final firstTarot = find.byKey(
      const Key('encyclopedia-tarot-major-00-fool'),
    );
    await tester.ensureVisible(firstTarot);
    await tester.tap(firstTarot);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('encyclopedia-tarot-detail')), findsOneWidget);
    expect(find.text('愚者'), findsWidgets);
    expect(find.textContaining('开放'), findsWidgets);
    expect(find.text('传统牌义（Rider–Waite–Smith 体系）'), findsOneWidget);
    expect(find.text('常见正位解读'), findsOneWidget);
    expect(find.text('常见逆位解读'), findsOneWidget);

    Navigator.of(
      tester.element(find.byKey(const Key('encyclopedia-tarot-detail'))),
    ).pop();
    await tester.pumpAndSettle();

    final liuyaoTab = find.byKey(const Key('encyclopedia-tab-liuyao'));
    await tester.ensureVisible(liuyaoTab);
    await tester.tap(liuyaoTab);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('encyclopedia-liuyao-table')), findsOneWidget);
    final table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.columns, hasLength(9));
    expect(table.rows, hasLength(8));
    expect(find.byKey(const Key('encyclopedia-hexagram-01')), findsOneWidget);

    final firstHexagram = find.byKey(const Key('encyclopedia-hexagram-01'));
    await tester.ensureVisible(firstHexagram);
    await tester.tap(firstHexagram);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('encyclopedia-liuyao-detail')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('encyclopedia-liuyao-detail')),
        matching: find.text('第 1 卦 · 乾'),
      ),
      findsOneWidget,
    );
    expect(find.text('《周易》卦辞原文'), findsOneWidget);
    expect(find.text('乾：元亨。利貞。'), findsOneWidget);
    expect(find.text('常见结构解读'), findsOneWidget);
    expect(find.text('观察提示'), findsOneWidget);
  });

  testWidgets('encyclopedia search narrows the active catalog', (tester) async {
    await tester.pumpWidget(
      PocketoolsApp(
        randomSource: SequenceRandomSource(const <int>[0]),
        feedbackService: const NoopFeedbackService(),
        settings: AppSettingsController(reduceMotion: true),
      ),
    );

    final encyclopediaEntry = find.text('塔罗/周易图鉴').first;
    await tester.ensureVisible(encyclopediaEntry);
    await tester.tap(encyclopediaEntry);
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('encyclopedia-search-field')),
      '太阳',
    );
    await tester.pump();

    expect(
      find.byKey(const Key('encyclopedia-tarot-major-19-sun')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('encyclopedia-tarot-major-00-fool')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('encyclopedia-clear-search')));
    await tester.pump();

    expect(find.text('塔罗牌 · 78 张'), findsOneWidget);
    expect(
      find.byKey(const Key('encyclopedia-tarot-major-00-fool')),
      findsOneWidget,
    );
  });

  testWidgets('selecting a late entry brings its explanation into view', (
    tester,
  ) async {
    await tester.pumpWidget(
      PocketoolsApp(
        randomSource: SequenceRandomSource(const <int>[0]),
        feedbackService: const NoopFeedbackService(),
        settings: AppSettingsController(reduceMotion: true),
      ),
    );

    final encyclopediaEntry = find.text('塔罗/周易图鉴').first;
    await tester.ensureVisible(encyclopediaEntry);
    await tester.tap(encyclopediaEntry);
    await tester.pump();

    final lateEntry = find.byKey(
      const Key('encyclopedia-tarot-major-21-world'),
    );
    await tester.ensureVisible(lateEntry);
    await tester.tap(lateEntry);
    await tester.pumpAndSettle();

    final detail = find.byKey(const Key('encyclopedia-tarot-detail'));
    expect(detail, findsOneWidget);
    expect(
      find.descendant(of: detail, matching: find.text('世界')),
      findsOneWidget,
    );
  });

  testWidgets('encyclopedia stays usable at 360px and 200 percent text', (
    tester,
  ) async {
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
          body: EncyclopediaToolPage(
            moduleContext: ToolModuleContext(
              randomSource: SequenceRandomSource(const <int>[0]),
              feedbackService: const NoopFeedbackService(),
              reduceMotion: true,
              feedbackEnabled: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final liuyaoTab = find.byKey(const Key('encyclopedia-tab-liuyao'));
    await tester.ensureVisible(liuyaoTab);
    await tester.tap(liuyaoTab);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(DataTable), findsOneWidget);
  });
}
