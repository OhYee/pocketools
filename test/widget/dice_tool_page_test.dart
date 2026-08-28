import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/design_system/components/app_button.dart';
import 'package:pocketools/design_system/components/app_segmented_control.dart';
import 'package:pocketools/design_system/components/app_stepper.dart';
import 'package:pocketools/features/dice/domain/dice_models.dart';
import 'package:pocketools/features/dice/presentation/dice_tool_page.dart';

void main() {
  const fixedConfig = DicePoolConfig(
    diceCount: 4,
    diceSides: 20,
    aggregation: DiceAggregation.keepHighest,
    keepCount: 3,
    modifier: 5,
    dc: 35,
  );

  testWidgets('DND page uses shared controls and renders the fixed 41 result', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DiceToolPage(
          initialConfig: fixedConfig,
          moduleContext: ToolModuleContext(
            randomSource: SequenceRandomSource(<int>[7, 15, 3, 11]),
            feedbackService: const NoopFeedbackService(),
            reduceMotion: true,
            feedbackEnabled: false,
          ),
        ),
      ),
    );

    expect(find.text('点击骰子或下方按钮掷骰'), findsOneWidget);

    await _openDiceAdvanced(tester);
    expect(find.byType(AppSegmentedControl<DiceMode>), findsOneWidget);
    expect(find.byType(AppStepper), findsNWidgets(7));
    expect(find.byType(AppButton), findsOneWidget);
    expect(find.text('自定义 · 4D20 · 保留最高 3 · +5 · DC 35'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('roll-button')));
    await tester.tap(find.byKey(const Key('roll-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('41'), findsOneWidget);
    expect(find.text('16 + 12 + 8 + 5 = 41'), findsOneWidget);
    expect(find.text('保留'), findsNWidgets(3));
    expect(find.text('舍弃'), findsOneWidget);
    expect(find.text('41 ≥ 35，达到 DC 35'), findsOneWidget);
  });

  testWidgets('skip animation reveals the same frozen dice result', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DiceToolPage(
          moduleContext: ToolModuleContext(
            randomSource: SequenceRandomSource(const <int>[7]),
            feedbackService: const NoopFeedbackService(),
            reduceMotion: false,
            feedbackEnabled: false,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('roll-button')));
    await tester.tap(find.byKey(const Key('roll-button')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('skip-dice-animation-button')),
    );
    await tester.tap(find.byKey(const Key('skip-dice-animation-button')));
    await tester.pump();

    expect(find.text('结果已完成'), findsOneWidget);
    expect(find.text('8'), findsWidgets);
    expect(find.byKey(const Key('skip-dice-animation-button')), findsNothing);
  });

  testWidgets('200 percent text on a 360px screen does not overflow', (
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
        home: DiceToolPage(
          moduleContext: ToolModuleContext(
            randomSource: SequenceRandomSource(const <int>[0]),
            feedbackService: const NoopFeedbackService(),
            reduceMotion: true,
            feedbackEnabled: false,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('roll-button')));
    await tester.tap(find.byKey(const Key('roll-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('D20 检定'), findsOneWidget);
    expect(find.text('总值'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('steppers expose semantics and 48px controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DiceToolPage(
          moduleContext: ToolModuleContext(
            randomSource: SequenceRandomSource(const <int>[0]),
            feedbackService: const NoopFeedbackService(),
            reduceMotion: true,
            feedbackEnabled: false,
          ),
        ),
      ),
    );

    await _openDiceAdvanced(tester);
    final countSemantics = tester.getSemantics(
      find.byKey(const Key('dice-count-stepper')),
    );
    final sidesSemantics = tester.getSemantics(
      find.byKey(const Key('dice-sides-stepper')),
    );
    final aggregationSemantics = tester.getSemantics(
      find.byType(AppSegmentedControl<DiceAggregation>),
    );

    expect(countSemantics.label, contains('骰子数量'));
    expect(countSemantics.value, contains('1'));
    expect(sidesSemantics.label, contains('自定义面数'));
    expect(sidesSemantics.value, contains('20'));
    expect(aggregationSemantics.label, contains('聚合方式'));
    for (final tooltip in <String>['增加骰子数量', '减少骰子数量']) {
      final size = tester.getSize(find.byTooltip(tooltip));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('keyboard input reaches all custom dice upper boundaries', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DiceToolPage(
          moduleContext: ToolModuleContext(
            randomSource: SequenceRandomSource(List<int>.filled(20, 0)),
            feedbackService: const NoopFeedbackService(),
            reduceMotion: true,
            feedbackEnabled: false,
          ),
        ),
      ),
    );

    await _openDiceAdvanced(tester);
    Finder field(Key key) =>
        find.descendant(of: find.byKey(key), matching: find.byType(TextField));

    await tester.enterText(field(const Key('dice-count-stepper')), '20');
    await tester.enterText(field(const Key('dice-sides-stepper')), '1000');
    await tester.ensureVisible(find.text('保留最高'));
    await tester.tap(find.text('保留最高'));
    await tester.pump();
    await tester.ensureVisible(field(const Key('keep-count-stepper')));
    await tester.enterText(field(const Key('keep-count-stepper')), '20');
    await tester.pump();

    expect(find.text('自定义 · 20D1000 · 保留最高 20 · +0'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('增加骰子数量'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('增加自定义面数'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('增加保留数量 K'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.ensureVisible(find.byKey(const Key('roll-button')));
    await tester.tap(find.byKey(const Key('roll-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('20'), findsWidgets);
    expect(find.text('结果已完成'), findsOneWidget);
  });

  testWidgets('invalid keyboard input blocks randomness', (tester) async {
    final random = _RecordingRandomSource(const <int>[0]);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DiceToolPage(
          moduleContext: ToolModuleContext(
            randomSource: random,
            feedbackService: const NoopFeedbackService(),
            reduceMotion: true,
            feedbackEnabled: false,
          ),
        ),
      ),
    );

    await _openDiceAdvanced(tester);
    final countField = find.descendant(
      of: find.byKey(const Key('dice-count-stepper')),
      matching: find.byType(TextField),
    );
    await tester.enterText(countField, '21');
    await tester.pump();

    expect(find.text('请输入 1～20 的整数。'), findsOneWidget);
    expect(
      tester.widget<AppButton>(find.byKey(const Key('roll-button'))).onPressed,
      isNull,
    );
    expect(random.consumed, 0);
  });

  testWidgets('result freezes before feedback and consumes randomness once', (
    tester,
  ) async {
    final random = _RecordingRandomSource(<int>[7, 15, 3, 11]);
    late final _RecordingFeedbackService feedback;
    feedback = _RecordingFeedbackService(() => random.consumed);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DiceToolPage(
          initialConfig: fixedConfig,
          moduleContext: ToolModuleContext(
            randomSource: random,
            feedbackService: feedback,
            reduceMotion: false,
            feedbackEnabled: true,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('roll-button')));
    await tester.tap(find.byKey(const Key('roll-button')));
    await tester.pump();

    expect(random.consumed, 4);
    expect(feedback.intensities, <FeedbackIntensity>[FeedbackIntensity.light]);
    expect(feedback.randomConsumptionAtEmit, <int>[4]);

    await tester.pump(const Duration(milliseconds: 90));
    await tester.pump(const Duration(milliseconds: 360));
    expect(find.text('41'), findsNothing);
    expect(feedback.intensities, <FeedbackIntensity>[
      FeedbackIntensity.light,
      FeedbackIntensity.medium,
    ]);
    expect(feedback.randomConsumptionAtEmit, <int>[4, 4]);

    await tester.pump(const Duration(milliseconds: 640));
    expect(random.consumed, 4);
    expect(find.text('41'), findsOneWidget);
    expect(find.text('结果已完成'), findsOneWidget);
  });

  testWidgets('disabled feedback is a no-op in reduced motion', (tester) async {
    final feedback = _RecordingFeedbackService(() => 0);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DiceToolPage(
          moduleContext: ToolModuleContext(
            randomSource: SequenceRandomSource(const <int>[0]),
            feedbackService: feedback,
            reduceMotion: true,
            feedbackEnabled: false,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('roll-button')));
    await tester.tap(find.byKey(const Key('roll-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(feedback.intensities, isEmpty);
    expect(find.text('总值'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('结果已完成'), findsOneWidget);
  });

  testWidgets(
    'random source failure creates no result and explains the error',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: DiceToolPage(
            moduleContext: const ToolModuleContext(
              randomSource: _ThrowingRandomSource(),
              feedbackService: NoopFeedbackService(),
              reduceMotion: true,
              feedbackEnabled: false,
            ),
          ),
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('roll-button')));
      await tester.tap(find.byKey(const Key('roll-button')));
      await tester.pump();

      expect(find.text('当前环境无法提供安全随机源，未生成结果。'), findsOneWidget);
      expect(find.text('总值'), findsNothing);
    },
  );
}

Future<void> _openDiceAdvanced(WidgetTester tester) async {
  final advanced = find.byKey(const Key('dice-advanced-options'));
  await tester.ensureVisible(advanced);
  await tester.tap(advanced);
  await tester.pumpAndSettle();
}

final class _ThrowingRandomSource implements RandomSource {
  const _ThrowingRandomSource();

  @override
  int nextInt(int maxExclusive) => throw UnsupportedError('No secure source');
}

final class _RecordingRandomSource implements RandomSource {
  _RecordingRandomSource(this._values);

  final List<int> _values;
  var consumed = 0;

  @override
  int nextInt(int maxExclusive) => _values[consumed++];
}

final class _RecordingFeedbackService implements FeedbackService {
  _RecordingFeedbackService(this._readRandomConsumption);

  final int Function() _readRandomConsumption;
  final List<FeedbackIntensity> intensities = <FeedbackIntensity>[];
  final List<int> randomConsumptionAtEmit = <int>[];

  @override
  Future<void> emit(FeedbackIntensity intensity) async {
    intensities.add(intensity);
    randomConsumptionAtEmit.add(_readRandomConsumption());
  }
}
