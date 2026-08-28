import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/pocketools_app.dart';
import 'package:pocketools/app/presentation/app_settings_controller.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_models.dart';
import 'package:pocketools/features/liuyao/presentation/liuyao_session_id_source.dart';
import 'package:pocketools/features/liuyao/presentation/liuyao_tool_module.dart';
import 'package:pocketools/features/liuyao/presentation/liuyao_tool_page.dart';
import 'package:pocketools/features/liuyao/presentation/widgets/liuyao_line_primitive.dart';
import 'package:pocketools/features/liuyao/presentation/widgets/liuyao_reading_view.dart';

void main() {
  testWidgets('animation and feedback wait for a committed automatic line', (
    tester,
  ) async {
    final random = _RecordingRandomSource(<int>[0, 1, 0]);
    final repository = _CommitControlledRepository();
    final feedback = _RecordingFeedbackService();
    await _pumpLiuyao(
      tester,
      random: random,
      repository: repository,
      feedback: feedback,
      reduceMotion: false,
    );

    await tester.tap(find.byKey(const Key('cast-next-liuyao-line-button')));
    await tester.pump();

    expect(random.consumed, 3);
    expect(repository.received, hasLength(1));
    expect(repository.committed, isEmpty);
    expect(repository.received.single.status, SessionStatus.ready);
    expect(find.textContaining('当前爻已冻结保存'), findsNothing);
    expect(find.textContaining('初爻 · 8'), findsNothing);
    expect(find.byKey(const Key('liuyao-ready-coins')), findsOneWidget);
    expect(feedback.intensities, isEmpty);

    repository.commit();
    await tester.pump();

    expect(repository.committed, hasLength(1));
    expect(find.text('当前爻已冻结保存'), findsOneWidget);
    expect(feedback.intensities, <FeedbackIntensity>[FeedbackIntensity.medium]);
    expect(random.consumed, 3);
  });

  testWidgets('mid-line random failure saves and displays no partial line', (
    tester,
  ) async {
    final random = _FailingRandomSource(failAt: 2);
    final repository = _RecordingRepository();
    final feedback = _RecordingFeedbackService();
    await _pumpLiuyao(
      tester,
      random: random,
      repository: repository,
      feedback: feedback,
    );

    await tester.tap(find.byKey(const Key('cast-next-liuyao-line-button')));
    await tester.pump();

    expect(random.calls, 3);
    expect(repository.saved, isEmpty);
    expect(feedback.intensities, isEmpty);
    expect(find.text('当前输入无法生成下一爻，未改变草稿。'), findsOneWidget);
    expect(find.textContaining('已确认 0/6 爻'), findsWidgets);
    expect(find.byType(LiuyaoLinePrimitive), findsNothing);
  });

  testWidgets(
    'storage rejection never reveals or feeds back the unsaved line',
    (tester) async {
      final random = _RecordingRandomSource(<int>[1, 1, 1]);
      final repository = _RejectingRepository();
      final feedback = _RecordingFeedbackService();
      await _pumpLiuyao(
        tester,
        random: random,
        repository: repository,
        feedback: feedback,
        reduceMotion: false,
      );

      await tester.tap(find.byKey(const Key('cast-next-liuyao-line-button')));
      await tester.pump();
      await tester.pump();

      expect(random.consumed, 3);
      expect(repository.attempted, hasLength(1));
      expect(feedback.intensities, isEmpty);
      expect(find.textContaining('无法保存已冻结结果'), findsOneWidget);
      expect(find.textContaining('初爻 · 6'), findsNothing);
      expect(find.byKey(const Key('liuyao-ready-coins')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(random.consumed, 3);
      expect(feedback.intensities, isEmpty);
    },
  );

  testWidgets(
    'skip settles the same line and cancels delayed motion feedback',
    (tester) async {
      final random = _RecordingRandomSource(<int>[0, 0, 1]);
      final repository = _RecordingRepository();
      final feedback = _RecordingFeedbackService();
      await _pumpLiuyao(
        tester,
        random: random,
        repository: repository,
        feedback: feedback,
        reduceMotion: false,
      );

      await tester.tap(find.byKey(const Key('cast-next-liuyao-line-button')));
      await tester.pump();
      expect(repository.saved, hasLength(1));
      expect(random.consumed, 3);
      expect(feedback.intensities, <FeedbackIntensity>[
        FeedbackIntensity.medium,
      ]);

      final skip = find.byKey(const Key('skip-liuyao-animation-button'));
      await tester.ensureVisible(skip);
      await tester.tap(skip);
      await tester.pump();
      await _showDraftMeaning(tester);
      expect(find.text('初爻 · 8 · 少阴 · 静'), findsOneWidget);
      expect(
        find.byKey(const Key('skip-liuyao-animation-button')),
        findsNothing,
      );

      await tester.pump(const Duration(seconds: 2));
      expect(random.consumed, 3);
      expect(feedback.intensities, <FeedbackIntensity>[
        FeedbackIntensity.medium,
      ]);
      expect(repository.saved, hasLength(1));
    },
  );

  testWidgets('hiding while save is pending restores the same silent line', (
    tester,
  ) async {
    final random = _RecordingRandomSource(<int>[1, 0, 1]);
    final repository = _CommitControlledRepository();
    final feedback = _RecordingFeedbackService();
    await _pumpLiuyao(
      tester,
      random: random,
      repository: repository,
      feedback: feedback,
      reduceMotion: false,
    );

    await tester.tap(find.byKey(const Key('cast-next-liuyao-line-button')));
    await tester.pump();
    expect(repository.received, hasLength(1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    repository.commit();
    await tester.pump();
    await tester.pump();

    expect(random.consumed, 3);
    expect(feedback.intensities, isEmpty);
    await tester.pump(const Duration(seconds: 2));
    expect(random.consumed, 3);
    expect(feedback.intensities, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await _showDraftMeaning(tester);
    expect(find.text('初爻 · 7 · 少阳 · 静'), findsOneWidget);
    expect(random.consumed, 3);
    expect(feedback.intensities, isEmpty);
  });

  testWidgets('disposing an active timeline cancels timers and extra entropy', (
    tester,
  ) async {
    final random = _RecordingRandomSource(<int>[0, 1, 1]);
    final feedback = _RecordingFeedbackService();
    await _pumpLiuyao(
      tester,
      random: random,
      repository: _RecordingRepository(),
      feedback: feedback,
      reduceMotion: false,
    );

    await tester.tap(find.byKey(const Key('cast-next-liuyao-line-button')));
    await tester.pump();
    expect(random.consumed, 3);
    final feedbackAtDispose = feedback.intensities.length;

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(random.consumed, 3);
    expect(feedback.intensities, hasLength(feedbackAtDispose));
  });

  testWidgets('route leave during motion restores one frozen partial session', (
    tester,
  ) async {
    final random = _RecordingRandomSource(<int>[0, 1, 0]);
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

    await tester.ensureVisible(find.text('六爻起卦').first);
    await tester.tap(find.text('六爻起卦').first);
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('cast-next-liuyao-line-button')),
    );
    await tester.tap(find.byKey(const Key('cast-next-liuyao-line-button')));
    await tester.pump();
    expect(random.consumed, 3);

    await tester.tap(find.byIcon(Icons.home));
    await tester.pump();
    await tester.ensureVisible(find.text('六爻起卦').first);
    await tester.tap(find.text('六爻起卦').first);
    await tester.pump();
    await tester.pump();

    await _showDraftMeaning(tester);
    expect(find.text('初爻 · 8 · 少阴 · 静'), findsOneWidget);
    expect(find.textContaining('已确认 1/6 爻'), findsWidgets);
    expect(random.consumed, 3);
  });

  testWidgets(
    'hexagram graphics are top-down while process semantics are bottom-up',
    (tester) async {
      final reading = _manualReading(<int>[7, 8, 7, 8, 7, 8]);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: LiuyaoReadingView(reading: reading),
            ),
          ),
        ),
      );
      await tester.pump();

      final graphicOrder = tester
          .widgetList<LiuyaoLinePrimitive>(find.byType(LiuyaoLinePrimitive))
          .map((primitive) => primitive.line.index)
          .toList(growable: false);
      expect(graphicOrder, <int>[5, 4, 3, 2, 1, 0]);

      final semanticOrder = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(LiuyaoReadingView),
              matching: find.byType(Semantics),
            ),
          )
          .map((widget) => widget.properties.label)
          .whereType<String>()
          .where((label) => label.contains('和值'))
          .toList(growable: false);
      expect(semanticOrder, <String>[
        '上爻，和值8，少阴，静爻',
        '第五爻，和值7，少阳，静爻',
        '第四爻，和值8，少阴，静爻',
        '第三爻，和值7，少阳，静爻',
        '第二爻，和值8，少阴，静爻',
        '初爻，和值7，少阳，静爻',
      ]);
      expect(_semanticsWidgetWithLabel('初爻，和值7，少阳，静爻'), findsOneWidget);
      expect(_semanticsWidgetWithLabel('上爻，和值8，少阴，静爻'), findsOneWidget);
    },
  );

  testWidgets(
    'completed automatic line returns keyboard focus to cast next line',
    (tester) async {
      final random = _RecordingRandomSource(<int>[0, 1, 0]);
      await _pumpLiuyao(
        tester,
        random: random,
        repository: _RecordingRepository(),
        reduceMotion: true,
      );

      var cast = find.byKey(const Key('cast-next-liuyao-line-button'));
      await tester.ensureVisible(cast);
      await _focusWithTab(tester, cast);
      expect(_focusIsInside(tester, cast), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump();

      await _showDraftMeaning(tester);
      expect(find.text('初爻 · 8 · 少阴 · 静'), findsOneWidget);
      expect(find.byKey(const Key('liuyao-current-coins')), findsOneWidget);
      expect(random.consumed, 3);
      cast = find.byKey(const Key('cast-next-liuyao-line-button'));
      expect(_focusIsInside(tester, cast), isTrue);
    },
  );

  testWidgets('360px 200 percent keyboard flow keeps targets and semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final random = _RecordingRandomSource(const <int>[]);
    await _pumpLiuyao(
      tester,
      random: random,
      repository: _RecordingRepository(),
      reduceMotion: true,
      initialConfig: const LiuyaoConfig(mode: LiuyaoMode.manual),
      textScaler: const TextScaler.linear(2),
    );

    var confirm = find.byKey(const Key('confirm-liuyao-line-button'));
    await tester.ensureVisible(confirm);
    expect(tester.getSize(confirm).height, greaterThanOrEqualTo(48));
    expect(_semanticsWidgetWithLabel('手工录入，生成初爻并冻结结果'), findsOneWidget);
    await _focusWithTab(tester, confirm);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump();
    await _showDraftMeaning(tester);
    expect(find.text('初爻 · 6 · 老阴 · 动'), findsOneWidget);
    expect(random.consumed, 0);
    confirm = find.byKey(const Key('confirm-liuyao-line-button'));

    for (var index = 1; index < 6; index++) {
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      confirm = find.byKey(const Key('confirm-liuyao-line-button'));
    }

    expect(find.text('本卦 · 第 2 卦 坤'), findsOneWidget);
    expect(find.text('变卦 · 第 1 卦 乾'), findsOneWidget);
    expect(find.byKey(const Key('undo-liuyao-line-button')), findsNothing);
    expect(find.byType(LiuyaoLinePrimitive), findsNWidgets(12));
    // The result tree keeps one accessible label per rendered hexagram line;
    // the former standalone process layer is intentionally gone.
    expect(_semanticsWidgetWithLabel('初爻，和值6，老阴，动爻，将变为阳爻'), findsOneWidget);
    expect(find.text('安全提示'), findsNothing);
    final restart = find.byKey(const Key('restart-liuyao-button'));
    await tester.ensureVisible(restart);
    expect(tester.getSize(restart).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

Future<void> _showDraftMeaning(WidgetTester tester) async {
  final visual = find.byKey(const Key('liuyao-hexagram-visual'));
  await tester.ensureVisible(visual);
  await tester.tap(visual);
  await tester.pump();
}

Future<void> _pumpLiuyao(
  WidgetTester tester, {
  required RandomSource random,
  required SessionRepository repository,
  FeedbackService feedback = const NoopFeedbackService(),
  bool reduceMotion = true,
  LiuyaoConfig? initialConfig,
  TextScaler? textScaler,
}) async {
  final module = LiuyaoToolModule(sessionRepository: repository);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: textScaler == null
          ? null
          : (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: child!,
            ),
      home: LiuyaoToolPage(
        moduleContext: ToolModuleContext(
          randomSource: random,
          feedbackService: feedback,
          reduceMotion: reduceMotion,
          feedbackEnabled: feedback is! NoopFeedbackService,
        ),
        sessionRepository: repository,
        sessionAdapter: module.toolSessionAdapter,
        sessionIdSource: _SequenceIdSource(),
        initialConfig: initialConfig,
      ),
    ),
  );
  await tester.pump();
  final automaticAction = find.byKey(const Key('cast-next-liuyao-line-button'));
  if (automaticAction.evaluate().isNotEmpty) {
    await tester.ensureVisible(automaticAction);
  }
}

LiuyaoReading _manualReading(List<int> values) => LiuyaoReading(
  config: const LiuyaoConfig(mode: LiuyaoMode.manual),
  lines: <LiuyaoLine>[
    for (var index = 0; index < values.length; index++)
      LiuyaoLine(
        index: index,
        value: values[index],
        source: LiuyaoLineSource.manualValue,
      ),
  ],
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

final class _FailingRandomSource implements RandomSource {
  _FailingRandomSource({required this.failAt});

  final int failAt;
  var calls = 0;

  @override
  int nextInt(int maxExclusive) {
    final current = calls++;
    if (current == failAt) throw StateError('Injected entropy failure.');
    return 0;
  }
}

class _RecordingRepository implements SessionRepository {
  final List<SessionRecord> saved = <SessionRecord>[];

  @override
  Future<SessionRecord?> findById(String id) async {
    for (final session in saved.reversed) {
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
  final Completer<void> _gate = Completer<void>();

  void commit() => _gate.complete();

  @override
  Future<SessionRecord?> findById(String id) async => null;

  @override
  Future<List<SessionRecord>> findAll() async =>
      List<SessionRecord>.unmodifiable(committed.reversed);

  @override
  Future<void> save(SessionRecord session) async {
    received.add(session);
    await _gate.future;
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

final class _SequenceIdSource implements LiuyaoSessionIdSource {
  var sequence = 0;

  @override
  String next() => 'qa-liuyao-${++sequence}';
}
