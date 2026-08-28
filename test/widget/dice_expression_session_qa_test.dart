import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/registry/default_tool_registry.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/presets/preset.dart';
import 'package:pocketools/core/presets/preset_repository.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_id_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/features/dice/domain/dice_models.dart';
import 'package:pocketools/features/dice/presentation/dice_tool_module.dart';
import 'package:pocketools/features/dice/presentation/dice_tool_page.dart';

void main() {
  testWidgets(
    'invalid advanced configuration consumes no result identity storage or feedback',
    (tester) async {
      final random = _RecordingRandomSource(const <int>[0]);
      final ids = _RecordingSessionIdSource();
      final repository = InMemorySessionRepository();
      final feedback = _RecordingFeedbackService();
      final module = DiceToolModule(
        sessionRepository: repository,
        sessionIdSource: ids,
      );

      await tester.pumpWidget(
        _page(
          module: module,
          repository: repository,
          ids: ids,
          random: random,
          feedback: feedback,
        ),
      );
      await tester.pumpAndSettle();
      await _openDiceAdvanced(tester);
      await tester.enterText(_field(const Key('dice-count-stepper')), '20');
      await tester.enterText(_field(const Key('dice-sides-stepper')), '1000');
      await tester.ensureVisible(find.text('保留最高').first);
      await tester.tap(find.text('保留最高').first);
      await tester.pump();
      await tester.ensureVisible(_field(const Key('keep-count-stepper')));
      await tester.enterText(_field(const Key('keep-count-stepper')), '21');
      await tester.pump();

      expect(find.text('请输入 1～当前骰子数量的整数。'), findsOneWidget);
      expect(random.consumed, 0);
      expect(ids.consumed, 0);
      expect(await repository.findAll(), isEmpty);
      expect(feedback.values, isEmpty);
      expect(find.text('请修正骰池设置'), findsOneWidget);
    },
  );

  testWidgets('advanced controls set mode and the one frozen session input', (
    tester,
  ) async {
    final random = _RecordingRandomSource(const <int>[5, 2, 2, 0]);
    final ids = _RecordingSessionIdSource();
    final repository = InMemorySessionRepository();
    final feedback = _RecordingFeedbackService();
    final module = DiceToolModule(
      sessionRepository: repository,
      sessionIdSource: ids,
    );

    await tester.pumpWidget(
      _page(
        module: module,
        repository: repository,
        ids: ids,
        random: random,
        feedback: feedback,
        initialConfig: DicePoolConfig.normal(dc: 5),
      ),
    );
    await _openDiceAdvanced(tester);
    await tester.enterText(_field(const Key('dice-count-stepper')), '4');
    await tester.enterText(_field(const Key('dice-sides-stepper')), '6');
    await tester.ensureVisible(find.text('保留最低').first);
    await tester.tap(find.text('保留最低').first);
    await tester.pump();
    await tester.ensureVisible(_field(const Key('keep-count-stepper')));
    await tester.enterText(_field(const Key('keep-count-stepper')), '2');
    await tester.ensureVisible(_field(const Key('modifier-stepper')));
    await tester.enterText(_field(const Key('modifier-stepper')), '-3');
    await tester.pump();

    expect(find.text('自定义 · 4D6 · 保留最低 2 · -3 · DC 5'), findsOneWidget);
    expect(random.consumed, 0);
    expect(ids.consumed, 0);
    expect(await repository.findAll(), isEmpty);

    await tester.ensureVisible(find.byKey(const Key('roll-button')));
    await tester.tap(find.byKey(const Key('roll-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final sessions = await repository.findAll();
    expect(sessions, hasLength(1));
    expect(sessions.single.id, 'quick-stepper-session-1');
    final decoded = module.toolSessionAdapter.decode(sessions.single);
    final config = decoded.input as DicePoolConfig;
    final outcome = decoded.outcome as DicePoolResult;
    expect(config.diceCount, 4);
    expect(config.diceSides, 6);
    expect(config.aggregation, DiceAggregation.keepLowest);
    expect(config.keepCount, 2);
    expect(config.modifier, -3);
    expect(config.dc, 5);
    expect(config.mode, DiceMode.custom);
    expect(outcome.rolls.map((roll) => roll.value), <int>[6, 3, 3, 1]);
    expect(outcome.keptInAggregationOrder.map((roll) => roll.index), <int>[
      4,
      2,
    ]);
    expect(outcome.total, 1);
    expect(random.consumed, 4);
    expect(ids.consumed, 1);
    expect(feedback.values, isEmpty);
    expect(find.text('结果已完成'), findsOneWidget);
  });

  testWidgets('tool draft changes never write back to the frozen user preset', (
    tester,
  ) async {
    final registry = buildDefaultToolRegistry();
    final system = registry.systemPresets.firstWhere(
      (preset) => preset.id == 'd20.normal',
    );
    final copy = system.asUserCopy(
      newId: 'qa-frozen-user-copy',
      newName: 'Frozen copy',
    );
    final presetRepository = InMemoryPresetRepository();
    await presetRepository.saveAll(<ToolPreset>[copy]);
    final launch = registry.launchRequestForPreset(copy);
    final module = DiceToolModule(
      sessionRepository: InMemorySessionRepository(),
      sessionIdSource: _RecordingSessionIdSource(),
    );

    await tester.pumpWidget(
      _page(
        module: module,
        repository: InMemorySessionRepository(),
        ids: _RecordingSessionIdSource(),
        random: _RecordingRandomSource(const <int>[]),
        feedback: _RecordingFeedbackService(),
        initialConfig: launch.initialConfig! as DicePoolConfig,
      ),
    );
    await tester.pumpAndSettle();
    await _openDiceAdvanced(tester);
    await tester.ensureVisible(find.byTooltip('增加骰子数量'));
    await tester.tap(find.byTooltip('增加骰子数量'));
    await tester.pump();

    expect(find.text('自定义 · 2D20 · 全部求和 · +0'), findsOneWidget);
    final stored = (await presetRepository.load()).presets.single;
    expect(stored.id, copy.id);
    expect(stored.type, PresetType.user);
    expect(stored.source, PresetSource.local);
    expect(stored.configuration, system.configuration);
    expect(stored.configuration['diceCount'], 1);
  });
}

Widget _page({
  required DiceToolModule module,
  required SessionRepository repository,
  required SessionIdSource ids,
  required RandomSource random,
  required FeedbackService feedback,
  DicePoolConfig? initialConfig,
}) => MaterialApp(
  theme: AppTheme.light(),
  home: DiceToolPage(
    moduleContext: ToolModuleContext(
      randomSource: random,
      feedbackService: feedback,
      reduceMotion: true,
      feedbackEnabled: false,
    ),
    sessionRepository: repository,
    sessionAdapter: module.toolSessionAdapter,
    sessionIdSource: ids,
    initialConfig: initialConfig,
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

Finder _field(Key stepperKey) => find.descendant(
  of: find.byKey(stepperKey),
  matching: find.byType(TextField),
);

final class _RecordingRandomSource implements RandomSource {
  _RecordingRandomSource(this.values);

  final List<int> values;
  var consumed = 0;

  @override
  int nextInt(int maxExclusive) => values[consumed++];
}

final class _RecordingSessionIdSource implements SessionIdSource {
  var consumed = 0;

  @override
  String next() => 'quick-stepper-session-${++consumed}';
}

final class _RecordingFeedbackService implements FeedbackService {
  final List<FeedbackIntensity> values = <FeedbackIntensity>[];

  @override
  Future<void> emit(FeedbackIntensity intensity) async {
    values.add(intensity);
  }
}
