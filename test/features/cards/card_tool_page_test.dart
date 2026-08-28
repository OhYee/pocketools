import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_session_adapter.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/features/cards/domain/card_models.dart';
import 'package:pocketools/features/cards/presentation/card_session_codec.dart';
import 'package:pocketools/features/cards/presentation/card_session_id_source.dart';
import 'package:pocketools/features/cards/presentation/card_tool_page.dart';

void main() {
  testWidgets('deck and completed primary action both draw without reset', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
    await _pumpCardPage(
      tester,
      randomSource: SequenceRandomSource(List<int>.filled(102, 0)),
      repository: repository,
      idSource: _SequenceCardSessionIdSource(<String>[
        'cards-first',
        'cards-second',
      ]),
    );

    expect(find.text('点击牌堆抽一张'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cards-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(repository.saved, hasLength(1));
    expect(find.byKey(const Key('reset-cards-button')), findsOneWidget);
    expect(find.text('结果说明'), findsNothing);
    expect(find.byKey(const Key('card-process-details')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('cards-deck')));
    await tester.tap(find.byKey(const Key('cards-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(repository.saved, hasLength(2));
    expect(repository.saved.last.parentSessionId, 'cards-first');
  });

  testWidgets('defaults to 52 cards and explicitly enables the 54-card deck', (
    tester,
  ) async {
    await _pumpCardPage(
      tester,
      randomSource: SequenceRandomSource(List<int>.filled(53, 0)),
    );
    await _openCardAdvancedOptions(tester);

    expect(find.text('标准牌组 · 不含大小王 · 52 张 · 抽取 3 张 · 无放回'), findsOneWidget);
    expect(find.text('默认关闭'), findsOneWidget);
    expect(find.text('范围：1～52'), findsOneWidget);

    final jokersSwitch = find.byKey(const Key('include-jokers-switch'));
    await tester.ensureVisible(jokersSwitch);
    await tester.tap(jokersSwitch);
    await tester.pump();

    expect(find.text('标准牌组 · 含大小王 · 54 张 · 抽取 3 张 · 无放回'), findsOneWidget);
    expect(find.text('已加入小王与大王'), findsOneWidget);
    expect(find.text('范围：1～54'), findsOneWidget);
  });

  testWidgets('persists one frozen result before motion and feedback', (
    tester,
  ) async {
    final random = _RecordingRandomSource(List<int>.filled(51, 0));
    final repository = _DeferredSessionRepository();
    final feedback = _RecordingFeedbackService(repository);
    await _pumpCardPage(
      tester,
      randomSource: random,
      repository: repository,
      feedbackService: feedback,
      reduceMotion: false,
    );

    await tester.ensureVisible(find.byKey(const Key('cards-deck')));
    await tester.tap(find.byKey(const Key('cards-deck')));
    await tester.pump();

    expect(random.consumed, 1);
    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.status, SessionStatus.completed);
    expect(feedback.intensities, isEmpty);
    expect(find.text('设置已冻结'), findsOneWidget);
    expect(find.text('梅花 2'), findsNothing);

    repository.allowSave();
    await tester.pump();
    expect(feedback.intensities, <FeedbackIntensity>[FeedbackIntensity.medium]);
    expect(feedback.savedCountsAtEmit, <int>[1]);

    await tester.pump(const Duration(milliseconds: 90));
    expect(find.text('结果已冻结，正在洗牌'), findsOneWidget);
    expect(find.text('中断或恢复继续同一已冻结结果，不重抽'), findsOneWidget);
    expect(find.text('梅花 2'), findsNothing);

    await tester.pump(const Duration(milliseconds: 520));
    expect(find.text('按冻结顺序抽牌'), findsOneWidget);
    expect(find.text('梅花 2'), findsOneWidget);
    expect(find.text('梅花 3'), findsNothing);
    expect(find.text('梅花 4'), findsNothing);
    expect(feedback.intensities, <FeedbackIntensity>[
      FeedbackIntensity.medium,
      FeedbackIntensity.light,
    ]);

    await tester.pump(const Duration(milliseconds: 640));
    expect(find.text('结果已完成'), findsOneWidget);
    expect(random.consumed, 1);
    expect(repository.saved, hasLength(1));
    expect(feedback.intensities, <FeedbackIntensity>[
      FeedbackIntensity.medium,
      FeedbackIntensity.light,
      FeedbackIntensity.light,
    ]);
  });

  testWidgets('restores the same completed session without consuming random', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
    final adapter = _cardAdapter();
    final result = CardDrawResult(
      config: const CardDrawConfig(drawCount: 3),
      cards: const <PlayingCard>[
        PlayingCard.standard(CardSuit.spades, CardRank.ace),
        PlayingCard.standard(CardSuit.hearts, CardRank.ten),
        PlayingCard.standard(CardSuit.clubs, CardRank.king),
      ],
    );
    await repository.save(
      adapter.createSession(
        id: 'cards-existing',
        schemaVersion: 1,
        ruleVersion: 'cards/1.0.0',
        algorithmVersion: 'random-unbiased-fisher-yates/1.0.0',
        status: SessionStatus.completed,
        input: result.config,
        outcome: result,
      ),
    );
    final random = _RecordingRandomSource(const <int>[]);

    await _pumpCardPage(
      tester,
      randomSource: random,
      repository: repository,
      adapter: adapter,
    );

    expect(find.text('黑桃 A'), findsOneWidget);
    expect(find.text('红桃 10'), findsOneWidget);
    expect(find.text('梅花 K'), findsOneWidget);
    expect(find.text('剩余 49 张'), findsNothing);
    expect(find.text('49 张'), findsWidgets);
    expect(find.text('重新抽取会创建新会话，不修改当前结果'), findsNothing);
    expect(random.consumed, 0);
    expect(repository.saved, hasLength(1));
  });

  testWidgets('explicit card launch does not restore the latest result', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
    final adapter = _cardAdapter();
    final result = CardDrawResult(
      config: const CardDrawConfig(drawCount: 3),
      cards: const <PlayingCard>[
        PlayingCard.standard(CardSuit.spades, CardRank.ace),
        PlayingCard.standard(CardSuit.hearts, CardRank.ten),
        PlayingCard.standard(CardSuit.clubs, CardRank.king),
      ],
    );
    await repository.save(
      adapter.createSession(
        id: 'cards-existing',
        schemaVersion: 1,
        ruleVersion: 'cards/1.0.0',
        algorithmVersion: 'random-unbiased-fisher-yates/1.0.0',
        status: SessionStatus.completed,
        input: result.config,
        outcome: result,
      ),
    );

    await _pumpCardPage(
      tester,
      randomSource: _RecordingRandomSource(const <int>[]),
      repository: repository,
      initialConfig: const CardDrawConfig(drawCount: 1),
      initialParentSessionId: 'cards-existing',
    );

    expect(find.text('准备就绪'), findsOneWidget);
    expect(find.text('黑桃 A'), findsNothing);
  });

  testWidgets('redraw creates a child session and preserves the first record', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
    final random = _RecordingRandomSource(List<int>.filled(102, 0));
    await _pumpCardPage(
      tester,
      randomSource: random,
      repository: repository,
      idSource: _SequenceCardSessionIdSource(<String>[
        'cards-first',
        'cards-second',
      ]),
      reduceMotion: true,
    );

    await tester.ensureVisible(find.byKey(const Key('cards-deck')));
    await tester.tap(find.byKey(const Key('cards-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final first = repository.saved.single;

    await tester.ensureVisible(find.byKey(const Key('cards-deck')));
    await tester.tap(find.byKey(const Key('cards-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(repository.saved, hasLength(2));
    expect(repository.saved[0], same(first));
    expect(repository.saved[0].id, 'cards-first');
    expect(repository.saved[0].parentSessionId, isNull);
    expect(repository.saved[1].id, 'cards-second');
    expect(repository.saved[1].parentSessionId, 'cards-first');
    expect(random.consumed, 2);
  });

  testWidgets('cards use the shared vermilion semantic theme', (tester) async {
    await _pumpCardPage(
      tester,
      randomSource: SequenceRandomSource(List<int>.filled(51, 0)),
    );

    final buttonContext = tester.element(find.byKey(const Key('cards-deck')));
    expect(
      Theme.of(buttonContext).colorScheme.primary,
      const Color(0xFFB4232A),
    );
  });

  testWidgets('invalid draw count blocks generation without consuming random', (
    tester,
  ) async {
    final random = _RecordingRandomSource(List<int>.filled(51, 0));
    await _pumpCardPage(tester, randomSource: random);
    await _openCardAdvancedOptions(tester);
    final field = find.descendant(
      of: find.byKey(const Key('card-draw-count-stepper')),
      matching: find.byType(TextField),
    );

    await tester.ensureVisible(field);
    await tester.enterText(field, '53');
    await tester.pump();

    expect(find.text('请输入 1～52 的整数。'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('cards-deck')));
    await tester.tap(find.byKey(const Key('cards-deck')));
    await tester.pump();
    expect(random.consumed, 0);
  });

  testWidgets('360px viewport at 200 percent text completes without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpCardPage(
      tester,
      randomSource: SequenceRandomSource(List<int>.filled(51, 0)),
      textScaler: const TextScaler.linear(2),
    );

    await tester.ensureVisible(find.byKey(const Key('cards-deck')));
    await tester.tap(find.byKey(const Key('cards-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(tester.takeException(), isNull);
    expect(find.text('结果已完成'), findsOneWidget);
    expect(find.text('梅花 2'), findsOneWidget);
  });
}

Future<void> _pumpCardPage(
  WidgetTester tester, {
  required RandomSource randomSource,
  SessionRepository? repository,
  ToolSessionAdapter? adapter,
  CardSessionIdSource? idSource,
  FeedbackService feedbackService = const NoopFeedbackService(),
  bool reduceMotion = true,
  CardDrawConfig? initialConfig,
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
      home: CardToolPage(
        moduleContext: ToolModuleContext(
          randomSource: randomSource,
          feedbackService: feedbackService,
          reduceMotion: reduceMotion,
          feedbackEnabled: feedbackService is! NoopFeedbackService,
        ),
        sessionRepository: repository ?? _RecordingSessionRepository(),
        sessionAdapter: adapter ?? _cardAdapter(),
        sessionIdSource:
            idSource ?? _SequenceCardSessionIdSource(<String>['cards-default']),
        initialConfig: initialConfig,
        initialParentSessionId: initialParentSessionId,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _openCardAdvancedOptions(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('cards-advanced-options')));
  await tester.tap(find.byKey(const Key('cards-advanced-options')));
  await tester.pumpAndSettle();
}

ToolSessionAdapter _cardAdapter() => ToolSessionAdapter(
  descriptor: const ToolDescriptor(
    id: 'cards',
    name: '抽扑克牌',
    description: 'Cards test module',
    route: '/tools/cards',
    icon: Icons.style_outlined,
    accent: ToolAccent.cards,
  ),
  codec: const CardSessionCodec(),
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

final class _SequenceCardSessionIdSource implements CardSessionIdSource {
  _SequenceCardSessionIdSource(Iterable<String> ids)
    : _ids = List<String>.unmodifiable(ids);

  final List<String> _ids;
  var _index = 0;

  @override
  String next() => _ids[_index++];
}
