import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_session_adapter.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/design_system/components/app_generation_state_view.dart';
import 'package:pocketools/design_system/components/app_physical_action.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';
import 'package:pocketools/features/tarot/presentation/tarot_session_codec.dart';
import 'package:pocketools/features/tarot/presentation/tarot_session_id_source.dart';
import 'package:pocketools/features/tarot/presentation/tarot_tool_page.dart';
import 'package:pocketools/features/tarot/presentation/widgets/tarot_card_primitive.dart';
import 'package:pocketools/features/tarot/presentation/widgets/tarot_result_view.dart';

void main() {
  testWidgets('offers three spreads with reversals enabled by default', (
    tester,
  ) async {
    await _pumpTarotPage(
      tester,
      randomSource: SequenceRandomSource(<int>[...List<int>.filled(77, 0), 0]),
    );

    expect(find.byKey(const Key('tarot-core-entity')), findsOneWidget);
    expect(find.byKey(const Key('reset-tarot-button')), findsOneWidget);
    expect(
      tester
          .widget<ExpansionTile>(
            find.byKey(const Key('tarot-advanced-options')),
          )
          .initiallyExpanded,
      isFalse,
    );
    await _openTarotAdvancedOptions(tester);
    expect(find.text('今日一牌'), findsWidgets);
    expect(find.text('单牌问答'), findsOneWidget);
    expect(find.text('过去／现在／未来'), findsOneWidget);
    expect(find.text('固定位置：今日提示'), findsOneWidget);
    expect(find.text('点击牌堆抽牌'), findsOneWidget);
    expect(find.byKey(const Key('tarot-intention-field')), findsOneWidget);
    expect(find.textContaining('仅保存在本机'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('tarot-reversals-switch')),
          )
          .value,
      isTrue,
    );
  });

  testWidgets('persists a frozen result before motion and feedback', (
    tester,
  ) async {
    final random = _RecordingRandomSource(<int>[...List<int>.filled(77, 0), 1]);
    final repository = _DeferredSessionRepository();
    final feedback = _RecordingFeedbackService(repository);
    await _pumpTarotPage(
      tester,
      randomSource: random,
      repository: repository,
      feedbackService: feedback,
      reduceMotion: false,
    );

    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();

    expect(random.consumed, 2);
    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.status, SessionStatus.completed);
    expect(repository.saved.single.outcome['cards'], hasLength(1));
    expect(feedback.intensities, isEmpty);
    expect(find.text('牌阵设置已冻结'), findsOneWidget);

    repository.allowSave();
    await tester.pump();
    expect(feedback.intensities, <FeedbackIntensity>[FeedbackIntensity.medium]);
    expect(feedback.savedCountsAtEmit, <int>[1]);

    await tester.pump(const Duration(milliseconds: 90));
    expect(find.text('结果已冻结保存，正在准备牌背'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 360));
    expect(find.text('新牌正在翻面并落位'), findsOneWidget);
    expect(find.textContaining('今日提示 · 愚者 · 正位'), findsOneWidget);
    expect(find.byKey(const Key('reveal-next-tarot-button')), findsNothing);
    expect(random.consumed, 2);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('牌阵与原创解释已完成'), findsOneWidget);
    expect(feedback.intensities, <FeedbackIntensity>[
      FeedbackIntensity.medium,
      FeedbackIntensity.light,
      FeedbackIntensity.light,
    ]);
  });

  testWidgets('tarot deck is disabled throughout the reveal phase', (
    tester,
  ) async {
    await _pumpTarotPage(
      tester,
      randomSource: SequenceRandomSource(<int>[...List<int>.filled(77, 0), 0]),
      reduceMotion: false,
    );

    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    final resultView = tester.widget<TarotResultView>(
      find.byType(TarotResultView),
    );
    expect(resultView.onDeckTap, isNull);
    final entity = tester.widget<AppEntityStateView>(
      find.byKey(const Key('tarot-core-entity')),
    );
    expect(entity.affordanceHint, isNot(contains('点击牌堆')));
  });

  testWidgets('redraw reads the edited tarot config after a result', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
    await _pumpTarotPage(
      tester,
      randomSource: _RecordingRandomSource(List<int>.filled(200, 0)),
      repository: repository,
      idSource: _SequenceTarotSessionIdSource(<String>[
        'tarot-config-first',
        'tarot-config-second',
      ]),
    );

    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await _openTarotAdvancedOptions(tester);
    await tester.ensureVisible(
      find.byKey(const Key('tarot-minor-arcana-switch')),
    );
    await tester.tap(find.byKey(const Key('tarot-minor-arcana-switch')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(repository.saved, hasLength(2));
    expect(repository.saved.last.input['includeMinorArcana'], isFalse);
  });

  testWidgets('explicit tarot launch does not restore the latest result', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
    await _pumpTarotPage(
      tester,
      randomSource: SequenceRandomSource(<int>[...List<int>.filled(77, 0), 0]),
      repository: repository,
      idSource: _SequenceTarotSessionIdSource(<String>['tarot-existing']),
    );
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await _pumpTarotPage(
      tester,
      randomSource: _RecordingRandomSource(const <int>[]),
      repository: repository,
      initialConfig: const TarotReadingConfig(
        spread: TarotSpreadPreset.pastPresentFuture,
      ),
      initialParentSessionId: 'tarot-existing',
    );

    expect(find.text('准备就绪'), findsOneWidget);
    expect(find.text('牌阵与原创解释已完成'), findsNothing);
    await _openTarotAdvancedOptions(tester);
    expect(find.text('过去／现在／未来'), findsWidgets);
  });

  testWidgets('three-card spread appends one physical card per deck tap', (
    tester,
  ) async {
    final random = _RecordingRandomSource(<int>[1, 0, 1, 1, 1, 0]);
    await _pumpTarotPage(
      tester,
      randomSource: random,
      reduceMotion: true,
      idSource: _SequenceTarotSessionIdSource(<String>[
        'tarot-one',
        'tarot-two',
        'tarot-three',
      ]),
      initialConfig: const TarotReadingConfig(
        spread: TarotSpreadPreset.pastPresentFuture,
      ),
    );

    for (final expected in <({int index, String position, String card})>[
      (index: 0, position: '过去', card: '魔术师'),
      (index: 1, position: '现在', card: '女祭司'),
      (index: 2, position: '未来', card: '女皇'),
    ]) {
      final deck = find.byKey(const Key('tarot-deck'));
      await tester.ensureVisible(deck);
      await tester.tap(deck);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byKey(Key('tarot-drawn-card-${expected.index}')),
        findsOneWidget,
      );
      expect(
        find.textContaining('${expected.position} · ${expected.card}'),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('tarot-drawn-card-${expected.index + 1}')),
        findsNothing,
      );
      expect(random.consumed, (expected.index + 1) * 2);
    }
    expect(find.text('组合提示'), findsOneWidget);
    expect(find.text('牌阵与原创解释已完成'), findsOneWidget);
  });

  testWidgets(
    'a new all-at-once draw animates only the newly added tarot card',
    (tester) async {
      final repository = _RecordingSessionRepository();
      await _pumpTarotPage(
        tester,
        randomSource: _RecordingRandomSource(<int>[
          ...List<int>.filled(160, 0),
        ]),
        repository: repository,
        reduceMotion: false,
        idSource: _SequenceTarotSessionIdSource(<String>[
          'tarot-all-at-once-first',
          'tarot-all-at-once-second',
        ]),
        initialConfig: const TarotReadingConfig(
          spread: TarotSpreadPreset.pastPresentFuture,
          revealMode: TarotRevealMode.allAtOnce,
        ),
      );

      final deck = find.byKey(const Key('tarot-deck'));
      await tester.tap(deck);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('牌阵与原创解释已完成'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
      await tester.tap(find.byKey(const Key('tarot-deck')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      await tester.pump(const Duration(milliseconds: 360));
      await tester.pump(const Duration(milliseconds: 100));

      expect(repository.saved, hasLength(2));
      expect(find.byKey(const Key('tarot-drawn-card-0')), findsOneWidget);
      expect(find.byKey(const Key('tarot-drawn-card-1')), findsOneWidget);
      final primitives = tester
          .widgetList<TarotCardPrimitive>(find.byType(TarotCardPrimitive))
          .toList(growable: false);
      expect(primitives, hasLength(2));
      expect(primitives[0].animate, isFalse);
      expect(primitives[1].animate, isTrue);
    },
  );

  testWidgets('the newest appended tarot card opens its interpretation', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
    await _pumpTarotPage(
      tester,
      randomSource: _RecordingRandomSource(<int>[...List<int>.filled(160, 0)]),
      repository: repository,
      reduceMotion: false,
      idSource: _SequenceTarotSessionIdSource(<String>[
        'tarot-meaning-first',
        'tarot-meaning-second',
      ]),
    );

    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.saved, hasLength(2));

    final newestCard = find.byKey(const Key('tarot-card-action-1'));
    expect(newestCard, findsOneWidget);
    expect(tester.widget<AppPhysicalAction>(newestCard).onTap, isNotNull);
    await tester.ensureVisible(newestCard);
    await tester.tap(newestCard);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('tarot-interpretation-sheet-1')),
      findsOneWidget,
    );
  });

  testWidgets(
    'reversals off consumes only shuffle entropy and records upright',
    (tester) async {
      final random = _RecordingRandomSource(List<int>.filled(77, 0));
      final repository = _RecordingSessionRepository();
      await _pumpTarotPage(
        tester,
        randomSource: random,
        repository: repository,
        reduceMotion: true,
      );

      await _openTarotAdvancedOptions(tester);
      await tester.ensureVisible(
        find.byKey(const Key('tarot-reversals-switch')),
      );
      await tester.tap(find.byKey(const Key('tarot-reversals-switch')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
      await tester.tap(find.byKey(const Key('tarot-deck')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(random.consumed, 1);
      expect(repository.saved.single.input['useReversals'], isFalse);
      final cards = repository.saved.single.outcome['cards']! as List<Object?>;
      expect(
        (cards.single! as Map<Object?, Object?>)['orientation'],
        'upright',
      );
      final drawnCard = find.byKey(const Key('tarot-drawn-card-0'));
      await tester.ensureVisible(drawnCard);
      await tester.tap(drawnCard);
      await tester.pump();
      expect(find.textContaining('关闭逆位，未请求方向随机值'), findsWidgets);
    },
  );

  testWidgets(
    'disabling minor arcana keeps a major-only reading across reset and redraw',
    (tester) async {
      final random = _RecordingRandomSource(<int>[
        ...List<int>.filled(65, 0),
        1,
      ]);
      final repository = _RecordingSessionRepository();
      await _pumpTarotPage(
        tester,
        randomSource: random,
        repository: repository,
        idSource: _SequenceTarotSessionIdSource(<String>[
          'major-only-first',
          'major-only-second',
          'major-only-third',
        ]),
        reduceMotion: true,
      );

      await _openTarotAdvancedOptions(tester);
      await tester.ensureVisible(
        find.byKey(const Key('tarot-minor-arcana-switch')),
      );
      await tester.tap(find.byKey(const Key('tarot-minor-arcana-switch')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
      await tester.tap(find.byKey(const Key('tarot-deck')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(random.consumed, 2);
      expect(repository.saved, hasLength(1));
      expect(repository.saved.single.input['includeMinorArcana'], isFalse);
      final firstCards =
          repository.saved.single.outcome['cards']! as List<Object?>;
      expect(
        firstCards.every(
          (raw) => (raw! as Map<Object?, Object?>)['cardId']
              .toString()
              .startsWith('major-'),
        ),
        isTrue,
      );
      expect(find.textContaining('仅大阿卡那（22 张）'), findsWidgets);

      await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
      await tester.tap(find.byKey(const Key('tarot-deck')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(random.consumed, 4);
      expect(repository.saved, hasLength(2));
      expect(repository.saved.last.parentSessionId, 'major-only-first');

      await tester.ensureVisible(find.byKey(const Key('reset-tarot-button')));
      await tester.tap(find.byKey(const Key('reset-tarot-button')));
      await tester.pump();
      expect(random.consumed, 4);
      expect(find.text('准备就绪'), findsOneWidget);
      expect(find.text('牌阵与原创解释已完成'), findsNothing);
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('tarot-minor-arcana-switch')),
            )
            .value,
        isFalse,
      );
      await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
      await tester.tap(find.byKey(const Key('tarot-deck')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(random.consumed, 6);
      expect(repository.saved, hasLength(3));
      expect(repository.saved.last.parentSessionId, 'major-only-second');
      expect(repository.saved.last.input['includeMinorArcana'], isFalse);
    },
  );

  testWidgets('legacy all-at-once setting still draws one card per tap', (
    tester,
  ) async {
    final random = _RecordingRandomSource(<int>[1, 0, 1, 1]);
    await _pumpTarotPage(
      tester,
      randomSource: random,
      reduceMotion: true,
      idSource: _SequenceTarotSessionIdSource(<String>[
        'tarot-all-at-once-one',
        'tarot-all-at-once-two',
      ]),
      initialConfig: const TarotReadingConfig(
        spread: TarotSpreadPreset.pastPresentFuture,
        revealMode: TarotRevealMode.allAtOnce,
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('牌阵与原创解释已完成'), findsOneWidget);
    expect(find.textContaining('过去 · 魔术师 · 正位'), findsOneWidget);
    expect(find.textContaining('现在 ·'), findsNothing);
    expect(random.consumed, 2);

    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('现在 · 女祭司 · 逆位'), findsOneWidget);
    expect(random.consumed, 4);
  });

  testWidgets('hide while save is pending completes frozen result silently', (
    tester,
  ) async {
    final repository = _DeferredSessionRepository();
    final random = _RecordingRandomSource(<int>[...List<int>.filled(77, 0), 1]);
    final feedback = _RecordingFeedbackService(repository);
    await _pumpTarotPage(
      tester,
      randomSource: random,
      repository: repository,
      feedbackService: feedback,
      reduceMotion: false,
    );

    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    repository.allowSave();
    await tester.pump();

    expect(find.text('牌阵与原创解释已完成'), findsOneWidget);
    expect(find.textContaining('今日提示 · 愚者 · 正位'), findsOneWidget);
    expect(random.consumed, 2);
    expect(repository.saved, hasLength(1));
    expect(feedback.intensities, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('skip and app hide reveal only the already saved reading', (
    tester,
  ) async {
    final random = _RecordingRandomSource(<int>[...List<int>.filled(77, 0), 1]);
    final repository = _RecordingSessionRepository();
    final feedback = _RecordingFeedbackService(repository);
    await _pumpTarotPage(
      tester,
      randomSource: random,
      repository: repository,
      feedbackService: feedback,
      reduceMotion: false,
    );

    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('skip-tarot-animation-button')),
    );
    await tester.tap(find.byKey(const Key('skip-tarot-animation-button')));
    await tester.pump();

    expect(find.text('牌阵与原创解释已完成'), findsOneWidget);
    expect(find.textContaining('今日提示 · 愚者 · 正位'), findsOneWidget);
    expect(random.consumed, 2);
    expect(repository.saved, hasLength(1));
    expect(feedback.intensities, <FeedbackIntensity>[FeedbackIntensity.medium]);
    await tester.pump(const Duration(seconds: 2));
    expect(feedback.intensities, <FeedbackIntensity>[FeedbackIntensity.medium]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(random.consumed, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('redraw creates a parent-linked session without mutation', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
    final random = _RecordingRandomSource(<int>[
      ...List<int>.filled(77, 0),
      0,
      ...List<int>.filled(77, 0),
      1,
    ]);
    await _pumpTarotPage(
      tester,
      randomSource: random,
      repository: repository,
      idSource: _SequenceTarotSessionIdSource(<String>[
        'tarot-first',
        'tarot-second',
      ]),
      reduceMotion: true,
      initialConfig: const TarotReadingConfig(
        intention: ' private redraw question ',
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final first = repository.saved.single;

    await tester.ensureVisible(find.byKey(const Key('redraw-tarot-button')));
    await tester.tap(find.byKey(const Key('redraw-tarot-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(repository.saved, hasLength(2));
    expect(repository.saved.first, same(first));
    expect(repository.saved.first.id, 'tarot-first');
    expect(repository.saved.first.parentSessionId, isNull);
    expect(
      repository.saved.first.input['intention'],
      'private redraw question',
    );
    expect(repository.saved.last.id, 'tarot-second');
    expect(repository.saved.last.parentSessionId, 'tarot-first');
    expect(repository.saved.last.input['intention'], isNull);
    expect(random.consumed, 4);
  });

  testWidgets('restores a completed reading without consuming random', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
    final sourceRandom = SequenceRandomSource(<int>[
      ...List<int>.filled(77, 0),
      1,
    ]);
    final adapter = _tarotAdapter();
    await _pumpTarotPage(
      tester,
      randomSource: sourceRandom,
      repository: repository,
      adapter: adapter,
      reduceMotion: true,
    );
    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final emptyRandom = _RecordingRandomSource(const <int>[]);
    await _pumpTarotPage(
      tester,
      randomSource: emptyRandom,
      repository: repository,
      adapter: adapter,
      reduceMotion: true,
    );

    expect(find.textContaining('今日提示 · 愚者 · 正位'), findsOneWidget);
    expect(find.text('再次抽牌会创建关联的新会话，不修改当前结果'), findsOneWidget);
    expect(emptyRandom.consumed, 0);
  });

  testWidgets('360px viewport at 200 percent text completes without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpTarotPage(
      tester,
      randomSource: SequenceRandomSource(<int>[...List<int>.filled(77, 0), 0]),
      reduceMotion: true,
      textScaler: const TextScaler.linear(2),
    );

    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(tester.takeException(), isNull);
    expect(find.text('牌阵与原创解释已完成'), findsOneWidget);
    expect(find.text('内容边界'), findsNothing);
  });
}

Future<void> _pumpTarotPage(
  WidgetTester tester, {
  required RandomSource randomSource,
  SessionRepository? repository,
  ToolSessionAdapter? adapter,
  TarotSessionIdSource? idSource,
  FeedbackService feedbackService = const NoopFeedbackService(),
  bool reduceMotion = true,
  TarotReadingConfig? initialConfig,
  String? initialParentSessionId,
  TextScaler? textScaler,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: textScaler == null
          ? null
          : (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: child!,
            ),
      home: TarotToolPage(
        moduleContext: ToolModuleContext(
          randomSource: randomSource,
          feedbackService: feedbackService,
          reduceMotion: reduceMotion,
          feedbackEnabled: feedbackService is! NoopFeedbackService,
        ),
        sessionRepository: repository ?? _RecordingSessionRepository(),
        sessionAdapter: adapter ?? _tarotAdapter(),
        sessionIdSource:
            idSource ??
            _SequenceTarotSessionIdSource(<String>['tarot-default']),
        initialConfig: initialConfig,
        initialParentSessionId: initialParentSessionId,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _openTarotAdvancedOptions(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('tarot-advanced-options')));
  await tester.tap(find.byKey(const Key('tarot-advanced-options')));
  await tester.pumpAndSettle();
}

ToolSessionAdapter _tarotAdapter() => ToolSessionAdapter(
  descriptor: const ToolDescriptor(
    id: 'tarot',
    name: '塔罗',
    description: 'Tarot test module',
    route: '/tools/tarot',
    icon: Icons.auto_awesome_outlined,
    accent: ToolAccent.tarot,
  ),
  codec: const TarotSessionCodec(),
);

final class _RecordingRandomSource implements RandomSource {
  _RecordingRandomSource(Iterable<int> values)
    : _delegate = SequenceRandomSource(values);

  final SequenceRandomSource _delegate;

  int get consumed => _delegate.consumed;

  @override
  int nextInt(int maxExclusive) => _delegate.nextInt(maxExclusive);
}

class _RecordingSessionRepository implements SessionRepository {
  final List<SessionRecord> saved = <SessionRecord>[];

  @override
  Future<SessionRecord?> findById(String id) async {
    for (final session in saved) {
      if (session.id == id) return session;
    }
    return null;
  }

  @override
  Future<List<SessionRecord>> findAll() async =>
      List<SessionRecord>.unmodifiable(saved.reversed);

  @override
  Future<void> save(SessionRecord session) async => saved.add(session);
}

final class _DeferredSessionRepository extends _RecordingSessionRepository {
  final Completer<void> _saveCompleter = Completer<void>();

  void allowSave() => _saveCompleter.complete();

  @override
  Future<void> save(SessionRecord session) {
    saved.add(session);
    return _saveCompleter.future;
  }
}

final class _RecordingFeedbackService implements FeedbackService {
  _RecordingFeedbackService(this.repository);

  final _RecordingSessionRepository repository;
  final List<FeedbackIntensity> intensities = <FeedbackIntensity>[];
  final List<int> savedCountsAtEmit = <int>[];

  @override
  Future<void> emit(FeedbackIntensity intensity) async {
    intensities.add(intensity);
    savedCountsAtEmit.add(repository.saved.length);
  }
}

final class _SequenceTarotSessionIdSource implements TarotSessionIdSource {
  _SequenceTarotSessionIdSource(Iterable<String> ids)
    : _ids = List<String>.unmodifiable(ids);

  final List<String> _ids;
  var _index = 0;

  @override
  String next() => _ids[_index++];
}
