import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/pocketools_app.dart';
import 'package:pocketools/app/presentation/app_settings_controller.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';

void main() {
  testWidgets('three stable navigation destinations open the DND tool', (
    tester,
  ) async {
    await tester.pumpWidget(
      PocketoolsApp(
        randomSource: SequenceRandomSource(const <int>[0]),
        feedbackService: const NoopFeedbackService(),
        settings: AppSettingsController(reduceMotion: true),
      ),
    );

    for (final label in <String>['首页', '历史', '设置']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('工具'), findsNothing);

    await tester.tap(find.text('D20 检定').first);
    await tester.pump();
    await _openAdvanced(tester, 'dice-advanced-options');
    final navigation = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navigation.selectedIndex, 0);
    expect(find.text('骰子数量'), findsWidgets);
    expect(find.byTooltip('增加骰子数量'), findsOneWidget);
    expect(find.byTooltip('减少骰子数量'), findsOneWidget);
  });

  testWidgets('tool back returns to the tool catalog', (tester) async {
    await tester.pumpWidget(
      PocketoolsApp(
        randomSource: SequenceRandomSource(const <int>[0]),
        feedbackService: const NoopFeedbackService(),
      ),
    );

    await tester.tap(find.text('D20 检定').first);
    await tester.pump();
    expect(find.text('D20 检定'), findsWidgets);
    expect(find.byKey(const Key('tool-back-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tool-back-button')));
    await tester.pump();

    expect(find.text('今天想用哪个工具？'), findsOneWidget);
    expect(find.byKey(const Key('tool-back-button')), findsNothing);
  });

  testWidgets('system back returns from a tool to the tool catalog', (
    tester,
  ) async {
    await tester.pumpWidget(
      PocketoolsApp(
        randomSource: SequenceRandomSource(const <int>[0]),
        feedbackService: const NoopFeedbackService(),
      ),
    );

    await tester.tap(find.text('D20 检定').first);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('今天想用哪个工具？'), findsOneWidget);
    expect(find.byKey(const Key('tool-back-button')), findsNothing);
  });

  testWidgets('applying a preset from settings returns to settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      PocketoolsApp(
        randomSource: SequenceRandomSource(const <int>[0]),
        feedbackService: const NoopFeedbackService(),
      ),
    );

    await tester.tap(find.text('设置').last);
    await tester.pump();
    final managePresets = find.text('管理预设');
    await tester.ensureVisible(managePresets);
    await tester.tap(managePresets);
    await tester.pump();
    expect(find.byKey(const Key('preset-management-page')), findsOneWidget);

    final applyPreset = find.byKey(const Key('apply-preset-tarot.daily-card'));
    await tester.ensureVisible(applyPreset);
    await tester.tap(applyPreset);
    await tester.pump();
    await tester.tap(find.byKey(const Key('tool-back-button')));
    await tester.pump();

    expect(find.text('管理预设'), findsOneWidget);
    expect(find.byKey(const Key('preset-management-page')), findsNothing);
  });

  testWidgets(
    'Liuyao navigation opens the real configuration without casting',
    (tester) async {
      await tester.pumpWidget(
        PocketoolsApp(
          randomSource: SequenceRandomSource(const <int>[0]),
          feedbackService: const NoopFeedbackService(),
        ),
      );

      await tester.tap(find.text('六爻起卦').first);
      await tester.pump();
      await tester.pump();
      await _openAdvanced(tester, 'liuyao-advanced-options');
      expect(find.text('自动投币'), findsWidgets);
      expect(find.text('手工录入'), findsOneWidget);
      expect(find.textContaining('已确认 0/6 爻'), findsWidgets);
      expect(find.textContaining('尚未投掷或录入'), findsOneWidget);
    },
  );

  testWidgets('desktop switches to a labeled navigation rail', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      PocketoolsApp(
        randomSource: SequenceRandomSource(const <int>[0]),
        feedbackService: const NoopFeedbackService(),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openAdvanced(WidgetTester tester, String key) async {
  final advanced = find.byKey(Key(key));
  await tester.ensureVisible(advanced);
  await tester.tap(advanced);
  await tester.pumpAndSettle();
}
