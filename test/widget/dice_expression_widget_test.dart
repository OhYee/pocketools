import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/design_system/components/app_button.dart';
import 'package:pocketools/features/dice/presentation/dice_tool_page.dart';

void main() {
  testWidgets('advanced numeric controls update the structured dice draft', (
    tester,
  ) async {
    await tester.pumpWidget(_page(_RecordingRandomSource()));
    await _openDiceAdvanced(tester);

    final count = find.descendant(
      of: find.byKey(const Key('dice-count-stepper')),
      matching: find.byType(TextField),
    );
    final sides = find.descendant(
      of: find.byKey(const Key('dice-sides-stepper')),
      matching: find.byType(TextField),
    );
    await tester.enterText(count, '2');
    await tester.enterText(sides, '20');
    await tester.pump();

    expect(find.text('自定义 · 2D20 · 全部求和 · +0'), findsOneWidget);
    expect(tester.widget<TextField>(count).controller?.text, '2');
    expect(tester.widget<TextField>(sides).controller?.text, '20');
  });

  testWidgets(
    'invalid structured input is inline and does not consume randomness',
    (tester) async {
      final random = _RecordingRandomSource();
      await tester.pumpWidget(_page(random));
      await _openDiceAdvanced(tester);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('dice-count-stepper')),
          matching: find.byType(TextField),
        ),
        '21',
      );
      await tester.pump();

      expect(find.text('请输入 1～20 的整数。'), findsOneWidget);
      expect(random.consumed, 0);
      expect(
        tester
            .widget<AppButton>(find.byKey(const Key('roll-button')))
            .onPressed,
        isNull,
      );
    },
  );
}

Widget _page(RandomSource random) => MaterialApp(
  theme: AppTheme.light(),
  home: DiceToolPage(
    moduleContext: ToolModuleContext(
      randomSource: random,
      feedbackService: const NoopFeedbackService(),
      reduceMotion: true,
      feedbackEnabled: false,
    ),
  ),
);

Future<void> _openDiceAdvanced(WidgetTester tester) async {
  final advanced = find.byKey(const Key('dice-advanced-options'));
  await tester.ensureVisible(advanced);
  await tester.tap(advanced);
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(
    tester.element(find.byKey(const Key('dice-count-stepper'))),
    alignment: 0.5,
  );
}

final class _RecordingRandomSource implements RandomSource {
  var consumed = 0;

  @override
  int nextInt(int maxExclusive) {
    consumed++;
    return 0;
  }
}
