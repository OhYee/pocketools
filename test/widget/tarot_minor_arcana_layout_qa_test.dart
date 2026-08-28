import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/design_system/components/app_button.dart';
import 'package:pocketools/features/tarot/content/tarot_content_catalog.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';
import 'package:pocketools/features/tarot/presentation/tarot_tool_page.dart';
import 'package:pocketools/features/tarot/presentation/widgets/tarot_card_primitive.dart';

import '../features/tarot/tarot_minor_arcana_qa_support.dart';

void main() {
  testWidgets(
    'simplified tarot shell puts the core entity first and keeps advanced options collapsed',
    (tester) async {
      await _pumpTarotPage(
        tester,
        random: TarotMinorArcanaQaRandomSource(),
        repository: TarotMinorArcanaQaSessionRepository(),
      );

      final coreEntity = find.byType(TarotDeckStack);
      final fallbackCoreEntity = find.byType(TarotCardPrimitive);
      expect(
        coreEntity.evaluate().isNotEmpty ||
            fallbackCoreEntity.evaluate().isNotEmpty,
        isTrue,
        reason: 'The first view needs an accessible tarot card pile or face.',
      );
      final core = coreEntity.evaluate().isNotEmpty
          ? coreEntity
          : fallbackCoreEntity;
      final draw = find.byKey(const Key('tarot-deck'));
      final reset = _appButtonContaining('重置');
      expect(draw, findsOneWidget);
      expect(reset, findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
      expect(tester.getSemantics(draw).label, contains('抽'));
      expect(tester.getSemantics(reset).label, contains('重置'));
      expect(find.text('高级选项'), findsOneWidget);
      expect(find.text('使用小阿卡纳'), findsNothing);
      expect(
        (tester.getTopLeft(core).dy - tester.getTopLeft(draw).dy).abs(),
        lessThanOrEqualTo(8),
      );
      expect(
        tester.getTopLeft(reset).dy,
        greaterThan(tester.getTopLeft(draw).dy),
      );

      final advancedTitle = find.text('高级选项');
      await tester.ensureVisible(advancedTitle);
      await tester.pumpAndSettle();
      await tester.tap(advancedTitle);
      await tester.pumpAndSettle();
      final minorSwitch = _minorArcanaSwitch();
      expect(minorSwitch, findsOneWidget);
      final switchWidget = tester.widget<SwitchListTile>(minorSwitch);
      expect(switchWidget.value, isTrue);
      expect(switchWidget.onChanged, isNotNull);

      final semanticsNode = tester.getSemantics(minorSwitch);
      expect(semanticsNode.label, contains('小阿卡纳'));
      expect(
        semanticsNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );

      final minorSwitchControl = find.byType(Switch).last;
      await tester.ensureVisible(minorSwitchControl);
      await tester.pumpAndSettle();
      await tester.tap(minorSwitchControl);
      await tester.pump();
      expect(tester.widget<SwitchListTile>(minorSwitch).value, isFalse);
      await tester.ensureVisible(reset);
      await tester.pumpAndSettle();
      await tester.tap(reset);
      await tester.pump();
      if (_minorArcanaSwitch().evaluate().isEmpty) {
        await tester.tap(find.text('高级选项'));
        await tester.pump();
      }
      expect(
        tester.widget<SwitchListTile>(_minorArcanaSwitch()).value,
        isFalse,
        reason: 'Reset clears the reading but preserves the active settings.',
      );
    },
  );

  testWidgets(
    'single tarot tap draws one major card, maps it, and reset clears without rerolling',
    (tester) async {
      final random = TarotMinorArcanaQaRandomSource();
      final repository = TarotMinorArcanaQaSessionRepository();
      await _pumpTarotPage(
        tester,
        random: random,
        repository: repository,
        initialConfig: TarotMinorArcanaQa.config(
          useMinorArcana: false,
          useReversals: false,
        ),
        reduceMotion: false,
      );

      await tester.tap(find.byKey(const Key('tarot-deck')));
      await tester.pump();
      expect(random.calls, 1);
      expect(repository.saved, hasLength(1));
      final session = repository.saved.single;
      final decoded = TarotMinorArcanaQa.adapter().decode(session);
      final result = decoded.outcome as TarotReadingResult;

      expect(TarotMinorArcanaQa.useMinorArcana(result.config), isFalse);
      expect(result.cards, hasLength(1));
      expect(
        result.cards.every((drawn) => drawn.card.arcana == TarotArcana.major),
        isTrue,
      );
      expect(
        TarotContentCatalog.entryFor(result.cards.single.card.id).cardId,
        result.cards.single.card.id,
      );
      expect(find.textContaining('22 张'), findsWidgets);

      await tester.pump(const Duration(seconds: 2));
      expect(random.calls, 1);
      expect(find.textContaining(result.cards.single.card.name), findsWidgets);

      await tester.ensureVisible(find.byKey(const Key('reset-tarot-button')));
      await tester.tap(find.byKey(const Key('reset-tarot-button')));
      await tester.pump();
      expect(random.calls, 1);
      expect(find.text('牌阵与原创解释已完成'), findsNothing);
      expect(find.byKey(ValueKey<String>(session.id)), findsNothing);
      expect(find.byKey(const Key('tarot-core-entity')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'major-only history restores after restart and redraw creates a new session without mutating the old one',
    (tester) async {
      final random = TarotMinorArcanaQaRandomSource();
      final repository = TarotMinorArcanaQaSessionRepository();
      final ids = TarotMinorArcanaQaSessionIds(const <String>[
        'minor-history-first',
        'minor-history-second',
      ]);
      final config = TarotMinorArcanaQa.config(
        useMinorArcana: false,
        useReversals: false,
        revealMode: TarotRevealMode.allAtOnce,
      );
      await _pumpTarotPage(
        tester,
        random: random,
        repository: repository,
        ids: ids,
        initialConfig: config,
      );

      await tester.tap(find.byKey(const Key('tarot-deck')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(repository.saved, hasLength(1));
      final first = repository.saved.single;
      final firstInput = Map<String, Object?>.of(first.input);
      final firstOutcome = Map<String, Object?>.of(first.outcome);
      expect(
        TarotMinorArcanaQa.useMinorArcana(
          TarotMinorArcanaQa.adapter().decode(first).input
              as TarotReadingConfig,
        ),
        isFalse,
      );

      await tester.ensureVisible(find.byKey(const Key('redraw-tarot-button')));
      await tester.tap(find.byKey(const Key('redraw-tarot-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(repository.saved, hasLength(2));
      final second = repository.saved.last;
      expect(first.input, firstInput);
      expect(first.outcome, firstOutcome);
      expect(second.parentSessionId, first.id);
      expect(second.input, firstInput);
      expect(random.calls, 2);

      final restoredRandom = TarotMinorArcanaQaRandomSource();
      await _pumpTarotPage(
        tester,
        random: restoredRandom,
        repository: repository,
        ids: ids,
      );
      await tester.pump();
      await tester.pump();

      expect(restoredRandom.calls, 0);
      expect(find.textContaining('22 张'), findsWidgets);
      final restoredInput =
          TarotMinorArcanaQa.adapter().decode(second).input
              as TarotReadingConfig;
      expect(TarotMinorArcanaQa.useMinorArcana(restoredInput), isFalse);
      expect(find.textContaining('再次抽牌会创建关联的新会话'), findsOneWidget);
    },
  );
}

Finder _appButtonContaining(String fragment) => find.byWidgetPredicate(
  (widget) => widget is AppButton && widget.label.contains(fragment),
  description: 'AppButton containing $fragment',
);

Finder _minorArcanaSwitch() => find.byWidgetPredicate(
  (widget) =>
      widget is SwitchListTile &&
      widget.title is Text &&
      ((widget.title! as Text).data ?? '').contains('小阿卡纳'),
  description: 'SwitchListTile for minor arcana',
);

Future<void> _pumpTarotPage(
  WidgetTester tester, {
  required RandomSource random,
  required TarotMinorArcanaQaSessionRepository repository,
  TarotMinorArcanaQaSessionIds? ids,
  TarotReadingConfig? initialConfig,
  bool reduceMotion = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: TarotToolPage(
        moduleContext: ToolModuleContext(
          randomSource: random,
          feedbackService: const NoopFeedbackService(),
          reduceMotion: reduceMotion,
          feedbackEnabled: false,
        ),
        sessionRepository: repository,
        sessionAdapter: TarotMinorArcanaQa.adapter(),
        sessionIdSource: ids ?? TarotMinorArcanaQaSessionIds(),
        initialConfig: initialConfig,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}
