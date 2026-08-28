import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/pocketools_app.dart';
import 'package:pocketools/app/presentation/app_settings_controller.dart';
import 'package:pocketools/app/registry/default_tool_registry.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/design_system/components/app_tool_card.dart';

void main() {
  testWidgets('home renders all seven tools from default registry order', (
    tester,
  ) async {
    final registry = buildDefaultToolRegistry();
    await tester.pumpWidget(
      PocketoolsApp(
        registry: registry,
        randomSource: SequenceRandomSource(const <int>[0]),
        feedbackService: const NoopFeedbackService(),
        settings: AppSettingsController(reduceMotion: true),
      ),
    );

    expect(registry.modules.map((module) => module.descriptor.id), <String>[
      'tarot',
      'liuyao',
      'd20',
      'coin',
      'cards',
      'multi_divination',
      'encyclopedia',
    ]);
    expect(find.byType(AppToolCard), findsNWidgets(7));
    expect(find.text('万象匣'), findsOneWidget);
    expect(find.bySemanticsLabel('万象匣标志'), findsOneWidget);
    for (final name in <String>[
      '塔罗',
      '六爻起卦',
      'D20 检定',
      '抛硬币',
      '抽扑克牌',
      '多重占卜',
      '塔罗/周易图鉴',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
  });

  testWidgets(
    'opening cards keeps the merged home/tools navigation with cards accent',
    (tester) async {
      await tester.pumpWidget(
        PocketoolsApp(
          randomSource: SequenceRandomSource(List<int>.filled(51, 0)),
          feedbackService: const NoopFeedbackService(),
          settings: AppSettingsController(reduceMotion: true),
        ),
      );

      await tester.ensureVisible(find.text('抽扑克牌'));
      await tester.tap(find.text('抽扑克牌'));
      await tester.pump();

      final navigation = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      final navigationContext = tester.element(find.byType(NavigationBar));
      final navigationTheme = NavigationBarTheme.of(navigationContext);
      expect(navigation.selectedIndex, 0);
      expect(
        navigationTheme.iconTheme?.resolve(<WidgetState>{
          WidgetState.selected,
        })?.color,
        const Color(0xFFB4232A),
      );
      expect(find.byKey(const Key('cards-deck')), findsOneWidget);
    },
  );

  test('home source iterates registry without tool-name branches', () {
    final source = File('lib/features/home/presentation/home_page.dart')
        .readAsStringSync();

    expect(source, contains('registry.modules'));
    for (final hardCodedTool in <String>['塔罗', '六爻', 'D20', '硬币', '扑克牌']) {
      expect(source, isNot(contains(hardCodedTool)));
    }
    expect(source, isNot(contains('switch')));
  });
}
