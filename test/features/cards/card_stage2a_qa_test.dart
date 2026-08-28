import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/pocketools_app.dart';
import 'package:pocketools/app/presentation/app_settings_controller.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';
import 'package:pocketools/core/tools/tool_session_adapter.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/features/cards/domain/card_drawer.dart';
import 'package:pocketools/features/cards/domain/card_models.dart';
import 'package:pocketools/features/cards/presentation/card_session_codec.dart';
import 'package:pocketools/features/cards/presentation/card_session_id_source.dart';
import 'package:pocketools/features/cards/presentation/card_tool_module.dart';
import 'package:pocketools/features/cards/presentation/card_tool_page.dart';

void main() {
  test('52 and 54 card boundaries preserve order uniqueness and remaining', () {
    final cases = <({CardDrawConfig config, int entropyCount})>[
      (config: const CardDrawConfig(drawCount: 1), entropyCount: 51),
      (config: const CardDrawConfig(drawCount: 52), entropyCount: 51),
      (
        config: const CardDrawConfig(drawCount: 1, includeJokers: true),
        entropyCount: 53,
      ),
      (
        config: const CardDrawConfig(drawCount: 54, includeJokers: true),
        entropyCount: 53,
      ),
    ];

    for (final testCase in cases) {
      final result = CardDrawer(
        SequenceRandomSource(List<int>.filled(testCase.entropyCount, 0)),
      ).draw(testCase.config);

      expect(result.cards, hasLength(testCase.config.drawCount));
      expect(
        result.cards.map((card) => card.id).toSet(),
        hasLength(testCase.config.drawCount),
      );
      expect(
        result.remainingCount,
        testCase.config.deckSize - testCase.config.drawCount,
      );
      if (!testCase.config.includeJokers) {
        expect(result.cards.where((card) => card.isJoker), isEmpty);
      }
    }

    final ordered = CardDrawer(SequenceRandomSource(List<int>.filled(51, 0)))
        .draw(const CardDrawConfig(drawCount: 3));
    expect(ordered.cards.map((card) => card.id), <String>[
      'clubs-three',
      'clubs-four',
      'clubs-five',
    ]);
  });

  test('every illegal draw count is rejected before random consumption', () {
    final random = _CountingRandomSource();
    for (final config in <CardDrawConfig>[
      const CardDrawConfig(drawCount: -1),
      const CardDrawConfig(drawCount: 0),
      const CardDrawConfig(drawCount: 53),
      const CardDrawConfig(drawCount: 55, includeJokers: true),
    ]) {
      expect(
        () => CardDrawer(random).draw(config),
        throwsA(isA<CardValidationException>()),
      );
    }
    expect(random.consumed, 0);
  });

  test('registry history and share use the card adapter and redact extras', () {
    final registry = ToolRegistry(<ToolModule>[CardToolModule()]);
    final session = SessionRecord(
      id: 'private-local-session-id',
      toolId: 'cards',
      schemaVersion: 1,
      ruleVersion: CardDrawer.ruleVersion,
      algorithmVersion: CardDrawer.algorithmVersion,
      status: SessionStatus.completed,
      parentSessionId: 'private-parent-session-id',
      input: <String, Object?>{
        'drawCount': 2,
        'includeJokers': false,
        'deckSize': 52,
        'question': 'private-question-value',
        'note': 'private-note-value',
        'device': 'private-device-value',
        'completedAt': 'private-time-value',
      },
      outcome: <String, Object?>{
        'cards': <Object?>['clubs-two', 'hearts-ace'],
        'remainingCount': 50,
        'analyticsId': 'private-analytics-value',
      },
    );

    final history = registry.historySummary(session);
    final share = registry.sharePayload(session);
    final publicText = '${history.summary}\n${share.plainText}';

    expect(history.toolId, 'cards');
    expect(history.summary, '扑克牌 · 抽取 2 张');
    expect(share.plainText, contains('#1 梅花 2'));
    expect(share.plainText, contains('#2 红桃 A'));
    expect(share.plainText, contains('剩余 50 张'));
    for (final secret in <String>[
      'private-local-session-id',
      'private-parent-session-id',
      'private-question-value',
      'private-note-value',
      'private-device-value',
      'private-time-value',
      'private-analytics-value',
    ]) {
      expect(publicText, isNot(contains(secret)), reason: secret);
    }
  });

  testWidgets('animation starts only after the session save commits', (
    tester,
  ) async {
    final repository = _CommitGateSessionRepository();
    final random = _RecordingRandomSource(List<int>.filled(1, 0));
    await _pumpCardPage(
      tester,
      randomSource: random,
      repository: repository,
      reduceMotion: false,
    );

    await tester.ensureVisible(find.byKey(const Key('cards-deck')));
    await tester.tap(find.byKey(const Key('cards-deck')));
    await tester.pump();

    expect(repository.attempted, isNotNull);
    expect(repository.saved, isEmpty);
    expect(random.consumed, 1);
    expect(find.text('设置已冻结'), findsOneWidget);
    expect(find.text('结果已冻结，正在洗牌'), findsNothing);

    repository.commit();
    await tester.pump();
    expect(repository.saved, hasLength(1));
    expect(find.text('设置已冻结'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 90));
    expect(find.text('结果已冻结，正在洗牌'), findsOneWidget);
    _hideApp(tester);
    await tester.pump();
    expect(find.text('结果已完成'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    _resumeApp(tester);
    await tester.pump();
  });

  testWidgets('skip and page hiding complete the same frozen session', (
    tester,
  ) async {
    final skipRepository = _RecordingSessionRepository();
    final skipRandom = _RecordingRandomSource(List<int>.filled(1, 0));
    await _pumpCardPage(
      tester,
      randomSource: skipRandom,
      repository: skipRepository,
      reduceMotion: false,
    );
    await tester.ensureVisible(find.byKey(const Key('cards-deck')));
    await tester.tap(find.byKey(const Key('cards-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    await tester.pump(const Duration(milliseconds: 520));

    final skippedSession = skipRepository.saved.single;
    await tester.ensureVisible(
      find.byKey(const Key('skip-card-animation-button')),
    );
    await tester.tap(find.byKey(const Key('skip-card-animation-button')));
    await tester.pump();
    expect(find.text('结果已完成'), findsOneWidget);
    expect(skipRepository.saved.single, same(skippedSession));
    expect(skipRandom.consumed, 1);
    await tester.pump(const Duration(milliseconds: 640));

    final hiddenRepository = _RecordingSessionRepository();
    final hiddenRandom = _RecordingRandomSource(List<int>.filled(1, 0));
    await _pumpCardPage(
      tester,
      randomSource: hiddenRandom,
      repository: hiddenRepository,
      reduceMotion: false,
    );
    await tester.ensureVisible(find.byKey(const Key('cards-deck')));
    await tester.tap(find.byKey(const Key('cards-deck')));
    await tester.pump();
    final hiddenSession = hiddenRepository.saved.single;

    _hideApp(tester);
    await tester.pump();
    expect(find.text('结果已完成'), findsOneWidget);
    expect(hiddenRepository.saved.single, same(hiddenSession));
    expect(hiddenRandom.consumed, 1);
    await tester.pump(const Duration(seconds: 2));
    _resumeApp(tester);
    await tester.pump();
  });

  testWidgets('leaving during motion restores the frozen session without RNG', (
    tester,
  ) async {
    final random = _RecordingRandomSource(List<int>.filled(1, 0));
    await tester.pumpWidget(
      PocketoolsApp(
        randomSource: random,
        feedbackService: const NoopFeedbackService(),
        settings: AppSettingsController(
          reduceMotion: false,
          feedbackEnabled: false,
        ),
      ),
    );

    await tester.ensureVisible(find.text('抽扑克牌'));
    await tester.tap(find.text('抽扑克牌'));
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('cards-deck')));
    await tester.tap(find.byKey(const Key('cards-deck')));
    await tester.pump();
    expect(find.text('设置已冻结'), findsOneWidget);
    expect(random.consumed, 1);

    await tester.tap(find.byIcon(Icons.home));
    await tester.pump();
    await tester.ensureVisible(find.text('抽扑克牌'));
    await tester.tap(find.text('抽扑克牌'));
    await tester.pump();
    await tester.pump();

    expect(find.text('梅花 2'), findsOneWidget);
    expect(find.text('梅花 3'), findsNothing);
    expect(find.text('梅花 4'), findsNothing);
    expect(random.consumed, 1);
    await tester.pump(const Duration(seconds: 2));
  });
}

Future<void> _pumpCardPage(
  WidgetTester tester, {
  required RandomSource randomSource,
  required SessionRepository repository,
  required bool reduceMotion,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: CardToolPage(
        key: UniqueKey(),
        moduleContext: ToolModuleContext(
          randomSource: randomSource,
          feedbackService: const NoopFeedbackService(),
          reduceMotion: reduceMotion,
          feedbackEnabled: false,
        ),
        sessionRepository: repository,
        sessionAdapter: _cardAdapter(),
        sessionIdSource: _IncrementingTestIdSource(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ToolSessionAdapter _cardAdapter() => ToolSessionAdapter(
  descriptor: const ToolDescriptor(
    id: 'cards',
    name: '抽扑克牌',
    description: 'Stage 2A QA module',
    route: '/tools/cards',
    icon: Icons.style_outlined,
    accent: ToolAccent.cards,
  ),
  codec: const CardSessionCodec(),
);

void _hideApp(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
}

void _resumeApp(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

final class _CountingRandomSource implements RandomSource {
  var consumed = 0;

  @override
  int nextInt(int maxExclusive) {
    consumed++;
    return 0;
  }
}

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

final class _CommitGateSessionRepository extends _RecordingSessionRepository {
  final Completer<void> _gate = Completer<void>();
  SessionRecord? attempted;

  void commit() => _gate.complete();

  @override
  Future<void> save(SessionRecord session) async {
    attempted = session;
    await _gate.future;
    saved.add(session);
  }
}

final class _IncrementingTestIdSource implements CardSessionIdSource {
  var _sequence = 0;

  @override
  String next() => 'stage2a-qa-${++_sequence}';
}
