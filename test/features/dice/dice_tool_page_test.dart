import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/design_system/app_tokens.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/features/dice/domain/dice_models.dart';
import 'package:pocketools/features/dice/presentation/dice_tool_page.dart';

void main() {
  testWidgets('renders one physical die per configured dice count', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      config: const DicePoolConfig(
        diceCount: 3,
        diceSides: 20,
        aggregation: DiceAggregation.sum,
      ),
    );

    expect(find.byKey(const Key('dice-physical-stage')), findsOneWidget);
    expect(find.byKey(const Key('dice-stage-die-1')), findsOneWidget);
    expect(find.byKey(const Key('dice-stage-die-2')), findsOneWidget);
    expect(find.byKey(const Key('dice-stage-die-3')), findsOneWidget);
    expect(find.byKey(const Key('dice-stage-die-4')), findsNothing);
    expect(
      tester
          .getSemantics(find.byKey(const Key('dice-stage-die-1')))
          .flagsCollection
          .isButton,
      isTrue,
    );
  });

  testWidgets('keeps the physical dice stage at one bounded height', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      config: const DicePoolConfig(
        diceCount: 1,
        diceSides: 20,
        aggregation: DiceAggregation.sum,
      ),
    );
    final oneDieHeight = tester
        .getSize(find.byKey(const Key('dice-physical-stage-slot')))
        .height;

    await _pumpPage(
      tester,
      config: const DicePoolConfig(
        diceCount: 4,
        diceSides: 20,
        aggregation: DiceAggregation.sum,
      ),
    );
    final fourDiceHeight = tester
        .getSize(find.byKey(const Key('dice-physical-stage-slot')))
        .height;

    expect(oneDieHeight, AppSizes.dicePhysicalStageSlotHeight);
    expect(fourDiceHeight, oneDieHeight);
  });

  testWidgets('tapping a physical die invokes the roll action', (tester) async {
    await _pumpPage(tester);

    final die = find.byKey(const Key('dice-stage-die-1'));
    expect(die, findsOneWidget);
    await tester.tap(die);
    await tester.pumpAndSettle();

    expect(find.text('总值'), findsOneWidget);
  });

  testWidgets(
    'top aDb steppers update physical dice immediately without text input',
    (tester) async {
      await _pumpPage(
        tester,
        config: const DicePoolConfig(
          diceCount: 1,
          diceSides: 6,
          aggregation: DiceAggregation.sum,
        ),
      );

      final quickCard = find.byKey(const Key('dice-quick-expression-card'));
      expect(find.byKey(const Key('dice-quick-count-stepper')), findsOneWidget);
      expect(find.byKey(const Key('dice-quick-sides-stepper')), findsOneWidget);
      expect(
        find.descendant(of: quickCard, matching: find.byType(TextField)),
        findsNothing,
      );

      await tester.tap(find.byTooltip('增加骰子数 a').first);
      await tester.pump();

      expect(find.byKey(const Key('dice-stage-die-2')), findsOneWidget);
      expect(find.byKey(const Key('dice-stage-die-3')), findsNothing);
    },
  );

  testWidgets(
    'changing the dice count immediately resets the old result and renders the new pool',
    (tester) async {
      await _pumpPage(
        tester,
        config: const DicePoolConfig(
          diceCount: 1,
          diceSides: 20,
          aggregation: DiceAggregation.sum,
        ),
      );

      await tester.tap(find.byKey(const Key('dice-stage-die-1')));
      await tester.pumpAndSettle();
      expect(find.text('总值'), findsOneWidget);

      await tester.tap(find.byTooltip('增加骰子数 a').first);
      await tester.pump();

      expect(find.text('总值'), findsNothing);
      expect(find.byKey(const Key('dice-stage-die-1')), findsOneWidget);
      expect(find.byKey(const Key('dice-stage-die-2')), findsOneWidget);
    },
  );

  testWidgets(
    'changing the dice sides immediately resets the old result and renders the new pool',
    (tester) async {
      await _pumpPage(
        tester,
        config: const DicePoolConfig(
          diceCount: 1,
          diceSides: 20,
          aggregation: DiceAggregation.sum,
        ),
      );

      await tester.tap(find.byKey(const Key('dice-stage-die-1')));
      await tester.pumpAndSettle();
      expect(find.text('总值'), findsOneWidget);

      await tester.tap(find.byTooltip('增加骰面 b').first);
      await tester.pump();

      expect(find.text('总值'), findsNothing);
      expect(find.text('D21'), findsOneWidget);
    },
  );

  testWidgets('does not show the final result before the roll animation ends', (
    tester,
  ) async {
    await _pumpPage(tester, reduceMotion: false);

    await tester.tap(find.byKey(const Key('dice-stage-die-1')));
    await tester.pump();
    expect(find.text('总值'), findsNothing);

    await tester.pump(const Duration(milliseconds: 90));
    expect(find.text('总值'), findsNothing);

    await tester.pump(const Duration(milliseconds: 360));
    expect(find.text('总值'), findsNothing);

    await tester.pump(const Duration(milliseconds: 640));
    expect(find.text('总值'), findsOneWidget);
  });

  testWidgets('dice result is rendered once in the physical stage', (
    tester,
  ) async {
    await _pumpPage(tester, reduceMotion: true);

    await tester.tap(find.byKey(const Key('dice-stage-die-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dice-roll-1')), findsNothing);
    expect(find.text('总值'), findsOneWidget);
  });

  testWidgets(
    'advanced options stay editable after animation and apply on the next roll',
    (tester) async {
      await _pumpPage(
        tester,
        reduceMotion: false,
        random: SequenceRandomSource(const <int>[0, 1, 2]),
      );

      await tester.ensureVisible(find.byKey(const Key('roll-button')));
      await tester.tap(find.byKey(const Key('roll-button')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('dice-advanced-options')),
      );
      await tester.tap(find.byKey(const Key('dice-advanced-options')));
      await tester.pump();

      final countField = find.descendant(
        of: find.byKey(const Key('dice-count-stepper')),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(countField).enabled, isTrue);

      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(countField).enabled, isTrue);

      await tester.enterText(countField, '2');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('roll-button')));
      await tester.tap(find.byKey(const Key('roll-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dice-stage-die-2')), findsOneWidget);
      expect(find.byKey(const Key('dice-stage-die-3')), findsNothing);
    },
  );
}

Future<void> _pumpPage(
  WidgetTester tester, {
  DicePoolConfig? config,
  RandomSource? random,
  bool reduceMotion = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: DiceToolPage(
        initialConfig: config,
        moduleContext: ToolModuleContext(
          randomSource: random ?? SequenceRandomSource(const <int>[0, 1, 2]),
          feedbackService: const NoopFeedbackService(),
          reduceMotion: reduceMotion,
          feedbackEnabled: false,
        ),
      ),
    ),
  );
  await tester.pump();
}
