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
import 'package:pocketools/features/coin/domain/coin_models.dart';
import 'package:pocketools/features/coin/domain/coin_tosser.dart';
import 'package:pocketools/features/coin/presentation/coin_session_codec.dart';
import 'package:pocketools/features/coin/presentation/coin_session_id_source.dart';
import 'package:pocketools/features/coin/presentation/coin_tool_module.dart';
import 'package:pocketools/features/coin/presentation/coin_tool_page.dart';

void main() {
  test('ordinary batches cover 1 3 5 10 and 100 in original order', () {
    for (final count in <int>[1, 3, 5, 10, 100]) {
      final entropy = List<int>.generate(
        count,
        (index) => index.isEven ? 0 : 1,
      );
      final random = _RecordingRandomSource(entropy);
      final result = CoinTosser(random)
          .toss(CoinTossConfig(mode: CoinTossMode.batch, batchCount: count));

      expect(result.tossCount, count, reason: 'batchCount=$count');
      expect(result.sequence, <CoinSide>[
        for (var index = 0; index < count; index++)
          index.isEven ? CoinSide.heads : CoinSide.tails,
      ]);
      expect(result.headsCount + result.tailsCount, count);
      expect(result.headsRatio + result.tailsRatio, closeTo(1, 1e-12));
      expect(result.stopReason, CoinStopReason.configuredCountReached);
      expect(result.winner, isNull);
      expect(random.consumed, count);
    }
  });

  test('invalid bounds and normalized label failures consume no entropy', () {
    for (final config in <CoinTossConfig>[
      const CoinTossConfig(mode: CoinTossMode.batch, batchCount: 0),
      const CoinTossConfig(mode: CoinTossMode.batch, batchCount: 101),
      const CoinTossConfig(headsLabel: '  ', tailsLabel: '反面'),
      const CoinTossConfig(headsLabel: '正面', tailsLabel: '\t\n'),
      const CoinTossConfig(headsLabel: ' A ', tailsLabel: 'A'),
    ]) {
      final random = _RecordingRandomSource(const <int>[0]);
      expect(
        () => CoinTosser(random).toss(config),
        throwsA(isA<CoinValidationException>()),
      );
      expect(random.consumed, 0, reason: config.validate().join(' '));
    }

    const codec = CoinSessionCodec();
    final normalized = CoinTosser(_RecordingRandomSource(const <int>[0, 1]))
        .toss(
          const CoinTossConfig(
            mode: CoinTossMode.batch,
            batchCount: 2,
            headsLabel: '  甲  ',
            tailsLabel: '  乙 ',
          ),
        );
    expect(normalized.config.headsLabel, '甲');
    expect(normalized.config.tailsLabel, '乙');
    expect(codec.encodeOutcome(normalized)['sequence'], <Object?>[
      'heads',
      'tails',
    ]);
  });

  test('races stop at both winners on shortest and 2N minus 1 paths', () {
    final cases =
        <({int target, List<int> entropy, CoinSide winner, int tossCount})>[
          (
            target: 1,
            entropy: <int>[0, 1],
            winner: CoinSide.heads,
            tossCount: 1,
          ),
          (
            target: 3,
            entropy: <int>[0, 0, 0, 1],
            winner: CoinSide.heads,
            tossCount: 3,
          ),
          (
            target: 3,
            entropy: <int>[1, 1, 1, 0],
            winner: CoinSide.tails,
            tossCount: 3,
          ),
          (
            target: 3,
            entropy: <int>[0, 1, 0, 1, 0, 1],
            winner: CoinSide.heads,
            tossCount: 5,
          ),
          (
            target: 3,
            entropy: <int>[1, 0, 1, 0, 1, 0],
            winner: CoinSide.tails,
            tossCount: 5,
          ),
          (
            target: 100,
            entropy: <int>[
              for (var index = 0; index < 199; index++) index.isEven ? 0 : 1,
              1,
            ],
            winner: CoinSide.heads,
            tossCount: 199,
          ),
        ];

    for (final testCase in cases) {
      final random = _RecordingRandomSource(testCase.entropy);
      final result = CoinTosser(random).toss(
        CoinTossConfig(mode: CoinTossMode.batch, raceTarget: testCase.target),
      );

      expect(result.winner, testCase.winner);
      expect(result.tossCount, testCase.tossCount);
      expect(result.stopReason, CoinStopReason.raceTargetReached);
      expect(random.consumed, testCase.tossCount);
      expect(result.tossCount, lessThanOrEqualTo(testCase.target * 2 - 1));
    }
  });

  test('ordinary batch never inherits race early-stop behavior', () {
    final random = _RecordingRandomSource(const <int>[0, 0, 0, 0, 0, 1]);
    final result = CoinTosser(random)
        .toss(const CoinTossConfig(mode: CoinTossMode.batch, batchCount: 5));

    expect(result.tossCount, 5);
    expect(result.headsCount, 5);
    expect(result.winner, isNull);
    expect(result.stopReason, CoinStopReason.configuredCountReached);
    expect(random.consumed, 5);
  });

  test(
    'codec rejects semantic mismatches and derives ratios from sequence',
    () {
      const codec = CoinSessionCodec();
      const ordinaryConfig = CoinTossConfig(
        mode: CoinTossMode.batch,
        batchCount: 3,
      );
      final ordinary = <String, Object?>{
        'sequence': <Object?>['heads', 'tails', 'heads'],
        'headsCount': 2,
        'tailsCount': 1,
        'stopReason': 'configuredCountReached',
        'winner': null,
      };
      final malformedOrdinary = <Map<String, Object?>>[
        <String, Object?>{...ordinary, 'headsCount': 1},
        <String, Object?>{...ordinary, 'tailsCount': 2},
        <String, Object?>{
          ...ordinary,
          'sequence': <Object?>['heads', 'tails'],
          'headsCount': 1,
          'tailsCount': 1,
        },
        <String, Object?>{...ordinary, 'winner': 'heads'},
        <String, Object?>{...ordinary, 'stopReason': 'raceTargetReached'},
      ];
      for (final payload in malformedOrdinary) {
        expect(
          () => codec.decodeOutcome(payload, ordinaryConfig),
          throwsFormatException,
        );
      }

      final decodedOrdinary = codec.decodeOutcome(ordinary, ordinaryConfig);
      expect(decodedOrdinary.headsRatio, closeTo(2 / 3, 1e-12));
      expect(decodedOrdinary.tailsRatio, closeTo(1 / 3, 1e-12));

      const raceConfig = CoinTossConfig(
        mode: CoinTossMode.batch,
        raceTarget: 2,
      );
      final race = <String, Object?>{
        'sequence': <Object?>['tails', 'heads', 'tails'],
        'headsCount': 1,
        'tailsCount': 2,
        'stopReason': 'raceTargetReached',
        'winner': 'tails',
      };
      expect(codec.decodeOutcome(race, raceConfig).winner, CoinSide.tails);
      for (final invalid
          in <({Map<String, Object?> payload, CoinTossConfig input})>[
            (
              payload: <String, Object?>{...race, 'winner': 'heads'},
              input: raceConfig,
            ),
            (
              payload: <String, Object?>{
                ...race,
                'stopReason': 'configuredCountReached',
              },
              input: raceConfig,
            ),
            (
              payload: race,
              input: const CoinTossConfig(
                mode: CoinTossMode.batch,
                raceTarget: 3,
              ),
            ),
            (
              payload: <String, Object?>{
                'sequence': <Object?>['tails', 'tails', 'heads'],
                'headsCount': 1,
                'tailsCount': 2,
                'stopReason': 'raceTargetReached',
                'winner': 'tails',
              },
              input: raceConfig,
            ),
          ]) {
        expect(
          () => codec.decodeOutcome(invalid.payload, invalid.input),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'codec keeps nullable legacy boundaries without weakening validation',
    () {
      const codec = CoinSessionCodec();
      final legacyInput = <String, Object?>{
        'mode': 'batch',
        'batchCount': 3,
        'headsLabel': '正面',
        'tailsLabel': '反面',
      };
      final legacyOutcome = <String, Object?>{
        'sequence': <Object?>['heads', 'tails', 'heads'],
        'headsCount': 2,
        'tailsCount': 1,
        'stopReason': 'configuredCountReached',
      };

      final config = codec.decodeInput(legacyInput);
      final result = codec.decodeOutcome(legacyOutcome, config);

      expect(config.raceTarget, isNull);
      expect(result.winner, isNull);
      expect(result.sequence, const <CoinSide>[
        CoinSide.heads,
        CoinSide.tails,
        CoinSide.heads,
      ]);
      expect(
        () => codec.decodeOutcome(<String, Object?>{
          ...legacyOutcome,
          'headsCount': 1,
        }, config),
        throwsFormatException,
      );
    },
  );

  test('registry history and share preserve race facts but redact extras', () {
    final registry = ToolRegistry(<ToolModule>[CoinToolModule()]);
    final session = SessionRecord(
      id: 'private-session-id',
      toolId: 'coin',
      schemaVersion: 1,
      ruleVersion: CoinTosser.ruleVersion,
      algorithmVersion: CoinTosser.algorithmVersion,
      status: SessionStatus.completed,
      parentSessionId: 'private-parent-id',
      input: <String, Object?>{
        'mode': 'batch',
        'batchCount': 3,
        'headsLabel': '甲',
        'tailsLabel': '乙',
        'raceTarget': 2,
        'question': 'private-question',
        'note': 'private-note',
        'device': 'private-device',
        'completedAt': 'private-time',
      },
      outcome: <String, Object?>{
        'sequence': <Object?>['tails', 'heads', 'tails'],
        'headsCount': 1,
        'tailsCount': 2,
        'stopReason': 'raceTargetReached',
        'winner': 'tails',
        'analyticsId': 'private-analytics',
      },
    );

    final history = registry.historySummary(session);
    final share = registry.sharePayload(session);
    final publicText = '${history.summary}\n${share.plainText}';

    expect(publicText, contains('heads,tails'));
    expect(publicText, contains('乙率先达到 2 次，共抛 3 次'));
    expect(publicText, contains('甲'));
    expect(publicText, contains('乙'));
    expect(publicText, contains(CoinTosser.ruleVersion));
    expect(publicText, contains(CoinTosser.algorithmVersion));
    for (final secret in <String>[
      'private-session-id',
      'private-parent-id',
      'private-question',
      'private-note',
      'private-device',
      'private-time',
      'private-analytics',
    ]) {
      expect(publicText, isNot(contains(secret)), reason: secret);
    }
  });

  testWidgets('motion and feedback wait for a committed session', (
    tester,
  ) async {
    final repository = _CommitGateSessionRepository();
    final random = _RecordingRandomSource(const <int>[0]);
    final feedback = _RecordingFeedbackService(repository);
    await _pumpCoinPage(
      tester,
      randomSource: random,
      repository: repository,
      feedbackService: feedback,
      reduceMotion: false,
    );

    await tester.tap(find.byKey(const Key('toss-coin-button')));
    await tester.pump();

    expect(random.consumed, 1);
    expect(repository.attempted, isNotNull);
    expect(repository.saved, isEmpty);
    expect(feedback.intensities, isEmpty);
    expect(find.text('设置已冻结'), findsOneWidget);
    expect(find.text('结果已冻结，准备抛起'), findsNothing);
    expect(find.byKey(const Key('skip-coin-animation-button')), findsNothing);

    repository.commit();
    await tester.pump();
    expect(repository.saved, hasLength(1));
    expect(feedback.intensities, <FeedbackIntensity>[FeedbackIntensity.medium]);
    expect(feedback.savedCountsAtEmit, <int>[1]);

    await tester.pump(const Duration(milliseconds: 90));
    expect(find.text('结果已冻结，准备抛起'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('skip-coin-animation-button')),
    );
    await tester.tap(find.byKey(const Key('skip-coin-animation-button')));
    await tester.pump();
    expect(find.text('原始面值：heads（正面）'), findsOneWidget);
    expect(random.consumed, 1);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('hiding while commit is pending completes the saved session', (
    tester,
  ) async {
    final repository = _CommitGateSessionRepository();
    final random = _RecordingRandomSource(const <int>[1]);
    final feedback = _RecordingFeedbackService(repository);
    await _pumpCoinPage(
      tester,
      randomSource: random,
      repository: repository,
      feedbackService: feedback,
      reduceMotion: false,
    );

    await tester.tap(find.byKey(const Key('toss-coin-button')));
    await tester.pump();
    expect(repository.saved, isEmpty);

    _hideApp(tester);
    repository.commit();
    await tester.pump();

    expect(repository.saved, hasLength(1));
    expect(find.text('结果已完成'), findsOneWidget);
    expect(find.text('原始面值：tails（反面）'), findsOneWidget);
    expect(random.consumed, 1);
    expect(feedback.intensities, isEmpty);

    _resumeApp(tester);
    await tester.pump();
    expect(find.text('原始面值：tails（反面）'), findsOneWidget);
    expect(random.consumed, 1);
  });

  testWidgets('leaving during motion restores one frozen shell session', (
    tester,
  ) async {
    final random = _RecordingRandomSource(const <int>[0]);
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

    await tester.ensureVisible(find.text('抛硬币'));
    await tester.tap(find.text('抛硬币'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('toss-coin-button')));
    await tester.pump();
    expect(random.consumed, 1);

    await tester.tap(find.byIcon(Icons.home));
    await tester.pump();
    await tester.ensureVisible(find.text('抛硬币'));
    await tester.tap(find.text('抛硬币'));
    await tester.pump();
    await tester.pump();

    expect(find.text('原始面值：heads（正面）'), findsOneWidget);
    expect(find.text('重新抛掷会创建关联的新会话，不修改当前结果'), findsNothing);
    expect(random.consumed, 1);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('100 tosses fit 360px at 200 percent text with raw semantics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final random = _RecordingRandomSource(List<int>.filled(100, 0));
    await _pumpCoinPage(
      tester,
      randomSource: random,
      initialConfig: const CoinTossConfig(
        mode: CoinTossMode.batch,
        batchCount: 100,
      ),
      textScaler: const TextScaler.linear(2),
    );

    await tester.ensureVisible(find.byKey(const Key('toss-coin-button')));
    await tester.tap(find.byKey(const Key('toss-coin-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(tester.takeException(), isNull);
    expect(find.text('共抛 100 次'), findsOneWidget);
    expect(random.consumed, 100);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label?.contains('第100次') == true &&
            widget.properties.label?.contains('原始面值 heads') == true,
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpCoinPage(
  WidgetTester tester, {
  required RandomSource randomSource,
  SessionRepository? repository,
  FeedbackService feedbackService = const NoopFeedbackService(),
  bool reduceMotion = true,
  CoinTossConfig? initialConfig,
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
      home: CoinToolPage(
        key: UniqueKey(),
        moduleContext: ToolModuleContext(
          randomSource: randomSource,
          feedbackService: feedbackService,
          reduceMotion: reduceMotion,
          feedbackEnabled: feedbackService is! NoopFeedbackService,
        ),
        sessionRepository: repository ?? _RecordingSessionRepository(),
        sessionAdapter: _coinAdapter(),
        sessionIdSource: _IncrementingTestIdSource(),
        initialConfig: initialConfig,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ToolSessionAdapter _coinAdapter() => ToolSessionAdapter(
  descriptor: const ToolDescriptor(
    id: 'coin',
    name: '抛硬币',
    description: 'Stage 2B1 QA module',
    route: '/tools/coin',
    icon: Icons.circle_outlined,
    accent: ToolAccent.coin,
  ),
  codec: const CoinSessionCodec(),
);

void _hideApp(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
}

void _resumeApp(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
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

final class _IncrementingTestIdSource implements CoinSessionIdSource {
  var _sequence = 0;

  @override
  String next() => 'stage2b1-qa-${++_sequence}';
}
