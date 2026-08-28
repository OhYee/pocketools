import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_id_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/design_system/components/app_runtime_asset.dart';
import 'package:pocketools/design_system/components/app_surfaces.dart';
import 'package:pocketools/assets/runtime/runtime_asset_manifest.dart';
import 'package:pocketools/features/coin/domain/coin_models.dart';
import 'package:pocketools/features/coin/presentation/widgets/coin_primitive.dart';
import 'package:pocketools/features/dice/domain/dice_models.dart';
import 'package:pocketools/features/dice/presentation/dice_tool_module.dart';
import 'package:pocketools/features/dice/presentation/dice_tool_page.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';
import 'package:pocketools/features/tarot/presentation/tarot_tool_module.dart';
import 'package:pocketools/features/tarot/presentation/tarot_tool_page.dart';
import 'package:pocketools/features/tarot/presentation/widgets/tarot_card_primitive.dart';

void main() {
  testWidgets(
    'coin animation physically lifts, flips, impacts, and settles in order',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: CoinPrimitive(
            side: CoinSide.heads,
            label: '正面',
            animate: true,
            animationDuration: Duration(milliseconds: 1000),
            assetBuilder: (context, asset, fallback) => fallback,
          ),
        ),
      );
      await tester.pump();

      final start = _coinYOffset(tester);
      await tester.pump(const Duration(milliseconds: 200));
      final lift = _coinYOffset(tester);
      final rotationDuringFlight = _coinRotationMagnitude(tester);
      await tester.pump(const Duration(milliseconds: 160));
      final apex = _coinYOffset(tester);
      await tester.pump(const Duration(milliseconds: 180));
      final descent = _coinYOffset(tester);
      await tester.pump(const Duration(milliseconds: 180));
      final landing = _coinYOffset(tester);
      await tester.pump(const Duration(milliseconds: 280));
      final settled = _coinYOffset(tester);

      expect(start, closeTo(0, 0.01));
      expect(lift, lessThan(-10));
      expect(apex, lessThan(lift));
      expect(descent, greaterThan(apex));
      expect(landing, closeTo(0, 0.01));
      expect(rotationDuringFlight, greaterThan(0.1));
      expect(settled, closeTo(0, 0.01));
      expect(find.text('正面'), findsOneWidget);
    },
  );

  testWidgets('coin preserves distinct heads and tails results', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Row(
          children: <Widget>[
            CoinPrimitive(
              side: CoinSide.heads,
              label: '正面',
              assetBuilder: (context, asset, fallback) => fallback,
            ),
            CoinPrimitive(
              side: CoinSide.tails,
              label: '反面',
              assetBuilder: (context, asset, fallback) => fallback,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('正面'), findsOneWidget);
    expect(find.text('反面'), findsOneWidget);
  });

  testWidgets(
    'DND accepts arbitrary dice count and sides, then keeps final faces frozen',
    (tester) async {
      final random = _RecordingRandomSource(const <int>[0, 999, 41]);
      final repository = _MemorySessionRepository();
      final ids = _FixedSessionIdSource('dnd-arbitrary-1');
      final module = DiceToolModule(
        sessionRepository: repository,
        sessionIdSource: ids,
      );

      await tester.pumpWidget(
        _dicePage(
          module: module,
          repository: repository,
          ids: ids,
          random: random,
          reduceMotion: true,
          initialConfig: const DicePoolConfig(
            diceCount: 3,
            diceSides: 1000,
            aggregation: DiceAggregation.sum,
            dc: 1043,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('roll-button')));
      await tester.tap(find.byKey(const Key('roll-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(find.text('结果已完成'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('dice-physical-stage')),
          matching: find.text('1000'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('dice-roll-2')), findsNothing);
      expect(find.text('42'), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == '第 2 枚实体 D1000 骰子，点击重置并再掷',
        ),
        findsOneWidget,
      );

      final session = (await repository.findAll()).single;
      final decoded = module.toolSessionAdapter.decode(session);
      final result = decoded.outcome as DicePoolResult;
      expect(result.rolls.map((roll) => roll.value), <int>[1, 1000, 42]);
      expect(result.total, 1043);
      expect(result.dcOutcome, DcOutcome.reached);
      expect(random.consumed, 3);

      await tester.pump(const Duration(seconds: 2));
      expect(random.consumed, 3);
      expect(
        (module.toolSessionAdapter.decode(session).outcome as DicePoolResult)
            .rolls
            .map((roll) => roll.value),
        <int>[1, 1000, 42],
      );
    },
  );

  testWidgets(
    'DND persists before timed phases and emits feedback after commit',
    (tester) async {
      final random = _RecordingRandomSource(const <int>[19]);
      final repository = _DeferredSessionRepository();
      final feedback = _RecordingFeedbackService();
      final ids = _FixedSessionIdSource('dnd-persist-1');
      final module = DiceToolModule(
        sessionRepository: repository,
        sessionIdSource: ids,
      );

      await tester.pumpWidget(
        _dicePage(
          module: module,
          repository: repository,
          ids: ids,
          random: random,
          feedback: feedback,
          reduceMotion: false,
          initialConfig: const DicePoolConfig(
            diceCount: 1,
            diceSides: 20,
            aggregation: DiceAggregation.sum,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('roll-button')));
      await tester.tap(find.byKey(const Key('roll-button')));
      await tester.pump();

      expect(repository.received, hasLength(1));
      expect(repository.committed, isEmpty);
      expect(random.consumed, 1);
      expect(feedback.values, isEmpty);
      expect(find.text('设置已冻结'), findsOneWidget);
      expect(find.text('19'), findsNothing);

      repository.commit();
      await tester.pump();
      expect(repository.committed, hasLength(1));
      expect(feedback.values, <FeedbackIntensity>[FeedbackIntensity.light]);
      expect(find.text('设置已冻结'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 90));
      expect(find.text('正在生成结果'), findsOneWidget);
      expect(find.text('19'), findsNothing);

      await tester.pump(const Duration(milliseconds: 360));
      expect(find.text('结果已生成，正在揭示'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppResultCard),
          matching: find.text('20'),
        ),
        findsNothing,
      );

      await tester.pump(const Duration(milliseconds: 640));
      expect(find.text('结果已完成'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppResultCard),
          matching: find.text('20'),
        ),
        findsOneWidget,
      );
      expect(random.consumed, 1);
      expect(repository.committed.single.outcome['total'], 20);
    },
  );

  testWidgets(
    'reduced motion skips timed dice animation without changing frozen results',
    (tester) async {
      final random = _RecordingRandomSource(const <int>[19, 0]);
      final repository = _MemorySessionRepository();
      final ids = _FixedSessionIdSource('dnd-reduced-motion-1');
      final module = DiceToolModule(
        sessionRepository: repository,
        sessionIdSource: ids,
      );

      await tester.pumpWidget(
        _dicePage(
          module: module,
          repository: repository,
          ids: ids,
          random: random,
          reduceMotion: true,
          initialConfig: const DicePoolConfig(
            diceCount: 2,
            diceSides: 20,
            aggregation: DiceAggregation.sum,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('roll-button')));
      await tester.tap(find.byKey(const Key('roll-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(find.text('结果已完成'), findsOneWidget);
      final session = repository.saved.single;
      final result =
          module.toolSessionAdapter.decode(session).outcome as DicePoolResult;
      expect(result.rolls.map((roll) => roll.value), <int>[20, 1]);
      expect(result.total, 21);
      expect(random.consumed, 2);

      await tester.pump(const Duration(seconds: 2));
      final unchanged =
          module.toolSessionAdapter.decode(session).outcome as DicePoolResult;
      expect(unchanged.rolls.map((roll) => roll.value), <int>[20, 1]);
      expect(unchanged.total, 21);
    },
  );

  testWidgets(
    'tarot appends one frozen card per deck tap without changing existing cards',
    (tester) async {
      final random = _RecordingRandomSource(<int>[1, 0, 1, 1, 1, 0]);
      final repository = _MemorySessionRepository();
      final ids = _SequenceSessionIdSource(<String>[
        'tarot-sequential-1',
        'tarot-sequential-2',
        'tarot-sequential-3',
      ]);
      final module = TarotToolModule(
        sessionRepository: repository,
        sessionIdSource: ids,
      );

      await tester.pumpWidget(
        _tarotPage(
          module: module,
          repository: repository,
          ids: ids,
          random: random,
          initialConfig: const TarotReadingConfig(
            spread: TarotSpreadPreset.pastPresentFuture,
            useReversals: true,
            revealMode: TarotRevealMode.sequential,
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final expected in <String>[
        '过去 · 魔术师 · 正位',
        '现在 · 女祭司 · 逆位',
        '未来 · 女皇 · 正位',
      ]) {
        final deck = find.byKey(const Key('tarot-deck'));
        await tester.ensureVisible(deck);
        await tester.tap(deck);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 90));
        await tester.pump(const Duration(milliseconds: 360));
        await tester.pump(const Duration(milliseconds: 480));
        expect(find.text(expected), findsOneWidget);
      }

      expect(repository.saved, hasLength(3));
      expect(random.consumed, 6);
      expect(find.text('牌阵与原创解释已完成'), findsOneWidget);
      expect(find.text('组合提示'), findsOneWidget);
      expect(find.byType(TarotCardPrimitive), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing runtime artwork uses the deterministic fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: RuntimeAssetSlot(
          asset: RuntimeAssetManifest.tarotFace(
            cardId: 'missing-card-resource',
            orientation: RuntimeAssetOrientation.reversed,
            semanticLabel: '缺失牌面资源',
          ),
          fallback: const Text('fallback-artwork'),
          assetBuilder: (context, asset, fallback) => fallback,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('fallback-artwork'), findsOneWidget);
    expect(find.bySemanticsLabel('缺失牌面资源'), findsOneWidget);
  });
}

double _coinYOffset(WidgetTester tester) {
  final translations = tester
      .widgetList<Transform>(find.byType(Transform))
      .map((transform) => transform.transform.storage[13])
      .toList(growable: false);
  return translations.reduce(
    (largest, value) => value.abs() > largest.abs() ? value : largest,
  );
}

double _coinRotationMagnitude(WidgetTester tester) {
  final transforms = tester.widgetList<Transform>(find.byType(Transform));
  return transforms
      .map(
        (transform) =>
            // rotateX is the physical horizontal-axis flip. In a column-
            // major Matrix4 its sine terms live at [6] and [9]; [2]/[8]
            // would measure the old rotateY contract.
            transform.transform.storage[6].abs() +
            transform.transform.storage[9].abs(),
      )
      .fold<double>(0, (largest, value) => value > largest ? value : largest);
}

Widget _dicePage({
  required DiceToolModule module,
  required SessionRepository repository,
  required SessionIdSource ids,
  required RandomSource random,
  required bool reduceMotion,
  FeedbackService feedback = const NoopFeedbackService(),
  DicePoolConfig? initialConfig,
}) => MaterialApp(
  theme: AppTheme.light(),
  home: DiceToolPage(
    moduleContext: ToolModuleContext(
      randomSource: random,
      feedbackService: feedback,
      reduceMotion: reduceMotion,
      feedbackEnabled: feedback is! NoopFeedbackService,
    ),
    sessionRepository: repository,
    sessionAdapter: module.toolSessionAdapter,
    sessionIdSource: ids,
    initialConfig: initialConfig,
  ),
);

Widget _tarotPage({
  required TarotToolModule module,
  required SessionRepository repository,
  required SessionIdSource ids,
  required RandomSource random,
  TarotReadingConfig? initialConfig,
}) => MaterialApp(
  theme: AppTheme.light(),
  home: TarotToolPage(
    moduleContext: ToolModuleContext(
      randomSource: random,
      feedbackService: const NoopFeedbackService(),
      reduceMotion: false,
      feedbackEnabled: false,
    ),
    sessionRepository: repository,
    sessionAdapter: module.toolSessionAdapter,
    sessionIdSource: ids,
    initialConfig: initialConfig,
  ),
);

final class _RecordingRandomSource implements RandomSource {
  _RecordingRandomSource(Iterable<int> values)
    : _delegate = SequenceRandomSource(values);

  final SequenceRandomSource _delegate;

  int get consumed => _delegate.consumed;

  @override
  int nextInt(int maxExclusive) => _delegate.nextInt(maxExclusive);
}

final class _FixedSessionIdSource implements SessionIdSource {
  _FixedSessionIdSource(this.id);

  final String id;
  var consumed = 0;

  @override
  String next() {
    consumed++;
    return id;
  }
}

final class _SequenceSessionIdSource implements SessionIdSource {
  _SequenceSessionIdSource(Iterable<String> ids)
    : _ids = List<String>.unmodifiable(ids);

  final List<String> _ids;
  var _index = 0;

  @override
  String next() => _ids[_index++];
}

class _MemorySessionRepository implements SessionRepository {
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

final class _DeferredSessionRepository implements SessionRepository {
  final List<SessionRecord> received = <SessionRecord>[];
  final List<SessionRecord> committed = <SessionRecord>[];
  final Completer<void> _commitCompleter = Completer<void>();

  void commit() => _commitCompleter.complete();

  @override
  Future<SessionRecord?> findById(String id) async {
    for (final session in committed) {
      if (session.id == id) return session;
    }
    return null;
  }

  @override
  Future<List<SessionRecord>> findAll() async =>
      List<SessionRecord>.unmodifiable(committed.reversed);

  @override
  Future<void> save(SessionRecord session) async {
    received.add(session);
    await _commitCompleter.future;
    committed.add(session);
  }
}

final class _RecordingFeedbackService implements FeedbackService {
  final List<FeedbackIntensity> values = <FeedbackIntensity>[];

  @override
  Future<void> emit(FeedbackIntensity intensity) async => values.add(intensity);
}
