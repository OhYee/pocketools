import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_session_adapter.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';
import 'package:pocketools/features/tarot/presentation/tarot_session_codec.dart';
import 'package:pocketools/features/tarot/presentation/tarot_session_id_source.dart';
import 'package:pocketools/features/tarot/presentation/tarot_tool_page.dart';
import 'package:pocketools/features/tarot/presentation/widgets/tarot_card_primitive.dart';
import 'package:pocketools/features/tarot/presentation/widgets/tarot_result_view.dart';

void main() {
  testWidgets('animation and feedback wait for a real repository commit', (
    tester,
  ) async {
    final repository = _CommitControlledRepository();
    final random = _RecordingRandomSource(<int>[...List<int>.filled(77, 0), 1]);
    final feedback = _RecordingFeedbackService();
    await _pumpTarot(
      tester,
      random: random,
      repository: repository,
      feedback: feedback,
      reduceMotion: false,
    );

    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();

    expect(repository.received, hasLength(1));
    expect(repository.committed, isEmpty);
    expect(random.consumed, 2);
    expect(feedback.intensities, isEmpty);
    expect(find.text('牌阵设置已冻结'), findsOneWidget);
    expect(find.byKey(const Key('skip-tarot-animation-button')), findsNothing);
    expect(find.textContaining('今日提示 · 魔术师'), findsNothing);

    repository.commit();
    await tester.pump();
    expect(repository.committed, hasLength(1));
    expect(feedback.intensities, <FeedbackIntensity>[FeedbackIntensity.medium]);
    expect(
      find.byKey(const Key('skip-tarot-animation-button')),
      findsOneWidget,
    );
    expect(random.consumed, 2);
  });

  testWidgets('save failure never reveals or animates an uncommitted result', (
    tester,
  ) async {
    final repository = _RejectingRepository();
    final random = _RecordingRandomSource(<int>[...List<int>.filled(77, 0), 0]);
    final feedback = _RecordingFeedbackService();
    await _pumpTarot(
      tester,
      random: random,
      repository: repository,
      feedback: feedback,
      reduceMotion: false,
    );

    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    await tester.pump();

    expect(repository.attempted, hasLength(1));
    expect(random.consumed, 2);
    expect(feedback.intensities, isEmpty);
    expect(find.textContaining('无法保存已冻结结果'), findsOneWidget);
    expect(find.byKey(const Key('skip-tarot-animation-button')), findsNothing);
    expect(find.textContaining('今日提示 · 魔术师'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(random.consumed, 2);
    expect(feedback.intensities, isEmpty);
  });

  testWidgets('random failure creates no session and no placeholder result', (
    tester,
  ) async {
    final repository = _RecordingRepository();
    final random = _ThrowingRandomSource();
    await _pumpTarot(
      tester,
      random: random,
      repository: repository,
      reduceMotion: true,
    );

    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();

    expect(random.calls, 1);
    expect(repository.saved, isEmpty);
    expect(find.textContaining('无法提供安全随机源'), findsOneWidget);
    expect(find.textContaining('今日提示 ·'), findsNothing);
    expect(find.byKey(const Key('redraw-tarot-button')), findsNothing);
  });

  testWidgets(
    'disposing staggered reveal cancels timers and preserves entropy',
    (tester) async {
      final random = _RecordingRandomSource(<int>[
        ...List<int>.filled(77, 0),
        0,
        1,
        0,
      ]);
      await _pumpTarot(
        tester,
        random: random,
        repository: _RecordingRepository(),
        reduceMotion: false,
        initialConfig: const TarotReadingConfig(
          spread: TarotSpreadPreset.pastPresentFuture,
          revealMode: TarotRevealMode.allAtOnce,
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
      await tester.tap(find.byKey(const Key('tarot-deck')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      await tester.pump(const Duration(milliseconds: 360));
      expect(find.text('新牌正在翻面并落位'), findsOneWidget);
      expect(random.consumed, 2);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      expect(random.consumed, 2);
    },
  );

  testWidgets('reduced motion never leaves a card in the flip animation', (
    tester,
  ) async {
    final random = _RecordingRandomSource(<int>[
      ...List<int>.filled(77, 0),
      0,
      1,
      0,
    ]);
    await _pumpTarot(
      tester,
      random: random,
      repository: _RecordingRepository(),
      reduceMotion: true,
      initialConfig: const TarotReadingConfig(
        spread: TarotSpreadPreset.pastPresentFuture,
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('牌阵与原创解释已完成'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TarotResultView),
        matching: find.byType(TarotCardPrimitive),
      ),
      findsOneWidget,
    );
    expect(find.byType(TarotCardBack), findsNWidgets(7));
    expect(random.consumed, 2);
  });

  testWidgets('360px at 200 percent keeps the first card usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final random = _RecordingRandomSource(<int>[1, 0]);
    await _pumpTarot(
      tester,
      random: random,
      repository: _RecordingRepository(),
      reduceMotion: true,
      textScaler: const TextScaler.linear(2),
      initialConfig: const TarotReadingConfig(
        spread: TarotSpreadPreset.pastPresentFuture,
        intention: '医疗法律财务人身安全 QA_PRIVATE_HIGH_RISK_TEXT',
      ),
    );

    final draw = find.byKey(const Key('tarot-deck'));
    await tester.ensureVisible(draw);
    expect(tester.getSize(draw).height, greaterThanOrEqualTo(48));
    expect(_semanticsWidgetWithLabel('塔罗牌堆，点击抽一张牌'), findsOneWidget);
    await tester.tap(draw);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump(const Duration(milliseconds: 480));

    expect(random.consumed, 2);
    expect(find.text('牌阵与原创解释已完成'), findsOneWidget);
    final expectedCardSemantics = <String>[
      '过去位置，魔术师，正位，经典 Rider–Waite–Smith 牌面',
    ];
    final actualCardSemantics = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byType(TarotCardPrimitive),
            matching: find.byType(Semantics),
          ),
        )
        .map((widget) => widget.properties.label)
        .whereType<String>()
        .toList(growable: false);
    expect(actualCardSemantics, containsAll(expectedCardSemantics));
    expect(find.text('内容边界'), findsNothing);
    final redraw = find.byKey(const Key('redraw-tarot-button'));
    await tester.ensureVisible(redraw);
    expect(tester.getSize(redraw).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard focus can draw one additional card per Enter', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final random = _RecordingRandomSource(<int>[1, 0, 1, 1, 1, 0]);
    await _pumpTarot(
      tester,
      random: random,
      repository: _RecordingRepository(),
      reduceMotion: true,
      initialConfig: const TarotReadingConfig(
        spread: TarotSpreadPreset.pastPresentFuture,
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    final deck = find.byKey(const Key('tarot-deck'));
    await tester.ensureVisible(deck);
    await _focusWithTab(tester, deck);

    for (var drawn = 1; drawn <= 3; drawn++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(random.consumed, drawn * 2);
      if (drawn < 3) await _focusWithTab(tester, deck);
    }

    expect(find.textContaining('过去 · 魔术师 · 正位'), findsOneWidget);
    expect(find.textContaining('现在 · 女祭司 · 逆位'), findsOneWidget);
    expect(find.textContaining('未来 · 女皇 · 正位'), findsOneWidget);
    await tester.ensureVisible(find.text('牌阵与原创解释已完成'));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp(r'.*牌阵与原创解释已完成.*')), findsOneWidget);
    expect(random.consumed, 6);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpTarot(
  WidgetTester tester, {
  required RandomSource random,
  required SessionRepository repository,
  FeedbackService feedback = const NoopFeedbackService(),
  required bool reduceMotion,
  TarotReadingConfig? initialConfig,
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
          randomSource: random,
          feedbackService: feedback,
          reduceMotion: reduceMotion,
          feedbackEnabled: feedback is! NoopFeedbackService,
        ),
        sessionRepository: repository,
        sessionAdapter: _tarotAdapter(),
        sessionIdSource: _IncrementingIdSource(),
        initialConfig: initialConfig,
      ),
    ),
  );
  await tester.pump();
}

ToolSessionAdapter _tarotAdapter() => ToolSessionAdapter(
  descriptor: const ToolDescriptor(
    id: 'tarot',
    name: '塔罗',
    description: 'Stage 2B2 QA module',
    route: '/tools/tarot',
    icon: Icons.auto_awesome_outlined,
    accent: ToolAccent.tarot,
  ),
  codec: const TarotSessionCodec(),
);

Finder _semanticsWidgetWithLabel(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
  description: 'Semantics widget with label "$label"',
);

Future<void> _focusWithTab(WidgetTester tester, Finder target) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    if (_focusIsInside(tester, target)) return;
  }
  fail('Target did not receive keyboard focus after 30 Tab presses.');
}

bool _focusIsInside(WidgetTester tester, Finder target) {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext is! Element || target.evaluate().isEmpty) return false;
  final targetElement = target.evaluate().single;
  if (identical(focusContext, targetElement)) return true;
  var found = false;
  focusContext.visitAncestorElements((ancestor) {
    if (identical(ancestor, targetElement)) found = true;
    return !found;
  });
  return found;
}

final class _RecordingRandomSource implements RandomSource {
  _RecordingRandomSource(Iterable<int> values)
    : _delegate = SequenceRandomSource(values);

  final SequenceRandomSource _delegate;

  int get consumed => _delegate.consumed;

  @override
  int nextInt(int maxExclusive) => _delegate.nextInt(maxExclusive);
}

final class _ThrowingRandomSource implements RandomSource {
  var calls = 0;

  @override
  int nextInt(int maxExclusive) {
    calls++;
    throw StateError('Injected random failure.');
  }
}

class _RecordingRepository implements SessionRepository {
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

final class _CommitControlledRepository implements SessionRepository {
  final List<SessionRecord> received = <SessionRecord>[];
  final List<SessionRecord> committed = <SessionRecord>[];
  final Completer<void> _commit = Completer<void>();

  void commit() => _commit.complete();

  @override
  Future<SessionRecord?> findById(String id) async => null;

  @override
  Future<List<SessionRecord>> findAll() async =>
      List<SessionRecord>.unmodifiable(committed.reversed);

  @override
  Future<void> save(SessionRecord session) async {
    received.add(session);
    await _commit.future;
    committed.add(session);
  }
}

final class _RejectingRepository implements SessionRepository {
  final List<SessionRecord> attempted = <SessionRecord>[];

  @override
  Future<SessionRecord?> findById(String id) async => null;

  @override
  Future<List<SessionRecord>> findAll() async => const <SessionRecord>[];

  @override
  Future<void> save(SessionRecord session) async {
    attempted.add(session);
    throw StateError('Injected storage failure.');
  }
}

final class _RecordingFeedbackService implements FeedbackService {
  final List<FeedbackIntensity> intensities = <FeedbackIntensity>[];

  @override
  Future<void> emit(FeedbackIntensity intensity) async {
    intensities.add(intensity);
  }
}

final class _IncrementingIdSource implements TarotSessionIdSource {
  var sequence = 0;

  @override
  String next() => 'qa-tarot-${++sequence}';
}
