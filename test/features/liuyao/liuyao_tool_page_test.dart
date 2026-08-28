import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  testWidgets(
    'automatic line saves three frozen coins before motion and feedback',
    (tester) async {
      final random = _RecordingRandomSource(<int>[0, 1, 0]);
      final repository = _DeferredRepository();
      final feedback = _RecordingFeedbackService(repository);
      await _pumpLiuyao(
        tester,
        random: random,
        repository: repository,
        feedback: feedback,
        reduceMotion: false,
      );

      expect(find.byKey(const Key('liuyao-ready-coins')), findsOneWidget);
      expect(find.text('三枚硬币'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('cast-next-liuyao-line-button')),
      );
      await tester.tap(find.byKey(const Key('cast-next-liuyao-line-button')));
      await tester.pump();

      expect(random.consumed, 3);
      expect(repository.writes, hasLength(1));
      expect(repository.writes.single.status, SessionStatus.ready);
      final lines = repository.writes.single.outcome['lines']! as List<Object?>;
      expect((lines.single! as Map<Object?, Object?>)['coins'], <Object?>[
        'heads',
        'tails',
        'heads',
      ]);
      expect(feedback.intensities, isEmpty);

      repository.allowSave();
      await tester.pump();
      expect(find.text('当前爻已冻结保存'), findsOneWidget);
      expect(feedback.intensities, <FeedbackIntensity>[
        FeedbackIntensity.medium,
      ]);
      expect(feedback.writeCountsAtEmit, <int>[1]);

      await tester.pump(const Duration(milliseconds: 90));
      expect(find.textContaining('三枚硬币翻转中'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 360));
      expect(find.textContaining('当前爻正在揭示'), findsOneWidget);
      await _showDraftMeaning(tester);
      expect(find.text('初爻 · 8 · 少阴 · 静'), findsNothing);
      await tester.pump(const Duration(milliseconds: 640));
      expect(find.text('初爻 · 8 · 少阴 · 静'), findsOneWidget);
      expect(random.consumed, 3);
    },
  );

  testWidgets('automatic casting is activated only by the coin stage', (
    tester,
  ) async {
    final random = _RecordingRandomSource(<int>[0, 1, 0]);
    await _pumpLiuyao(tester, random: random);

    await tester.tap(find.text('准备初爻'));
    await tester.pump();
    expect(random.consumed, 0);

    final coins = find.byKey(const Key('liuyao-ready-coins'));
    final emptyLineInfo = find.text('尚未确认爻；下一次操作从初爻开始。');
    expect(
      tester.getTopLeft(coins).dy,
      lessThan(tester.getTopLeft(emptyLineInfo).dy),
    );

    await tester.tap(coins);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(random.consumed, 3);
    expect(find.text('初爻 · 8 · 少阴 · 静'), findsNothing);
    await _showDraftMeaning(tester);
    expect(find.text('初爻 · 8 · 少阴 · 静'), findsOneWidget);
  });

  testWidgets(
    'manual values use no entropy and undo only the incomplete draft',
    (tester) async {
      final random = _RecordingRandomSource(const <int>[0]);
      final repository = _RecordingRepository();
      await _pumpLiuyao(
        tester,
        random: random,
        repository: repository,
        initialConfig: const LiuyaoConfig(mode: LiuyaoMode.manual),
      );

      await _openLiuyaoAdvancedOptions(tester);
      await tester.ensureVisible(find.text('9 · 老阳 · 动'));
      await tester.tap(find.text('9 · 老阳 · 动'));
      await tester.pump();
      await _tapCurrentLine(tester, manual: true);

      expect(random.consumed, 0);
      await _showDraftMeaning(tester);
      expect(find.text('初爻 · 9 · 老阳 · 动'), findsOneWidget);
      expect(repository.latest!.status, SessionStatus.ready);

      await tester.ensureVisible(
        find.byKey(const Key('undo-liuyao-line-button')),
      );
      await tester.tap(find.byKey(const Key('undo-liuyao-line-button')));
      await tester.pump();
      expect(find.textContaining('已确认 0/6 爻'), findsWidgets);
      expect(repository.latest!.status, SessionStatus.draft);
      expect(random.consumed, 0);
    },
  );

  testWidgets('undo creates a new immutable Liuyao draft session', (
    tester,
  ) async {
    final repository = _RecordingRepository();
    await _pumpLiuyao(
      tester,
      random: _RecordingRandomSource(const <int>[]),
      repository: repository,
      initialConfig: const LiuyaoConfig(mode: LiuyaoMode.manual),
      idSource: _SequenceIdSource(<String>['first', 'undo-draft']),
    );

    await _openLiuyaoAdvancedOptions(tester);
    final oldYang = find.text('9 · 老阳 · 动');
    await tester.ensureVisible(oldYang);
    await tester.tap(oldYang);
    await tester.pump();
    await _tapCurrentLine(tester, manual: true);
    final firstId = repository.latest!.id;

    await tester.ensureVisible(
      find.byKey(const Key('undo-liuyao-line-button')),
    );
    await tester.tap(find.byKey(const Key('undo-liuyao-line-button')));
    await tester.pump();

    expect(repository.latest!.id, isNot(firstId));
    expect(repository.latest!.id, 'undo-draft');
    expect(repository.latest!.parentSessionId, firstId);
    expect(repository.latest!.status, SessionStatus.draft);
  });

  testWidgets('changing Liuyao mode starts a parent-linked new draft', (
    tester,
  ) async {
    final repository = _RecordingRepository();
    await _pumpLiuyao(
      tester,
      random: _RecordingRandomSource(<int>[0, 1, 0]),
      repository: repository,
      initialConfig: const LiuyaoConfig(mode: LiuyaoMode.manual),
      idSource: _SequenceIdSource(<String>['manual-first', 'automatic-next']),
    );

    await _openLiuyaoAdvancedOptions(tester);
    final oldYang = find.text('9 · 老阳 · 动');
    await tester.ensureVisible(oldYang);
    await tester.tap(oldYang);
    await tester.pump();
    await _tapCurrentLine(tester, manual: true);
    final firstId = repository.latest!.id;

    final automaticMode = find.text('自动投币');
    await tester.ensureVisible(automaticMode);
    await tester.tap(automaticMode);
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('cast-next-liuyao-line-button')),
    );
    await tester.tap(find.byKey(const Key('cast-next-liuyao-line-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(repository.latest!.id, 'automatic-next');
    expect(repository.latest!.id, isNot(firstId));
    expect(repository.latest!.parentSessionId, firstId);
    expect(repository.latest!.input['mode'], 'automatic');
  });

  testWidgets('explicit Liuyao launch does not restore the latest draft', (
    tester,
  ) async {
    final repository = _RecordingRepository();
    await _pumpLiuyao(
      tester,
      random: _RecordingRandomSource(<int>[0, 1, 0]),
      repository: repository,
      idSource: _SequenceIdSource(<String>['liuyao-existing']),
    );
    await _tapCurrentLine(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await _pumpLiuyao(
      tester,
      random: _RecordingRandomSource(const <int>[]),
      repository: repository,
      initialConfig: const LiuyaoConfig(mode: LiuyaoMode.manual),
      initialParentSessionId: 'liuyao-existing',
    );

    await _openLiuyaoAdvancedOptions(tester);
    final progress = tester.widget<Text>(
      find.byKey(const Key('liuyao-progress-summary')),
    );
    expect(progress.data, contains('已确认 0/6 爻'));
    expect(progress.data, isNot(contains('已确认 1/6 爻')));
  });

  testWidgets(
    'six automatic lines preserve order and show primary and changed hexagrams',
    (tester) async {
      final random = _RecordingRandomSource(List<int>.filled(18, 0));
      final repository = _RecordingRepository();
      await _pumpLiuyao(tester, random: random, repository: repository);

      for (var index = 0; index < 6; index++) {
        await _tapCurrentLine(tester);
      }

      expect(random.consumed, 18);
      expect(repository.latest!.status, SessionStatus.completed);
      expect(find.text('本卦 · 第 1 卦 乾'), findsOneWidget);
      expect(find.text('变卦 · 第 2 卦 坤'), findsOneWidget);
      expect(find.byKey(const Key('liuyao-moving-summary')), findsOneWidget);
      expect(find.byType(LiuyaoLinePrimitive), findsNWidgets(12));
      expect(find.text('形成过程'), findsNothing);
      expect(find.text('内容边界'), findsNothing);
      expect(find.textContaining('不扩展到纳甲'), findsNothing);
    },
  );

  testWidgets(
    'hexagram meaning opens in a sheet without formation or source details',
    (tester) async {
      await _pumpLiuyao(
        tester,
        random: _RecordingRandomSource(const <int>[]),
        initialConfig: const LiuyaoConfig(mode: LiuyaoMode.manual),
      );

      for (var index = 0; index < 6; index++) {
        await _tapCurrentLine(tester, manual: true);
      }

      expect(find.text('卦象释义'), findsNothing);
      expect(find.text('来源与许可'), findsNothing);
      expect(find.textContaining('Pocketools original'), findsNothing);

      final hexagramInfo = find.textContaining('上卦：').first;
      expect(hexagramInfo, findsOneWidget);
      await tester.tap(hexagramInfo);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('liuyao-meaning-sheet')), findsOneWidget);
      expect(find.text('卦象释义'), findsOneWidget);
      expect(find.textContaining('数据按初爻到上爻'), findsNothing);
      expect(find.text('来源与许可'), findsNothing);
      expect(find.text('开源许可'), findsNothing);
    },
  );

  testWidgets('liuyao advanced editing stays enabled during motion', (
    tester,
  ) async {
    await _pumpLiuyao(
      tester,
      random: _RecordingRandomSource(<int>[0, 1, 0]),
      reduceMotion: false,
    );

    await tester.ensureVisible(
      find.byKey(const Key('cast-next-liuyao-line-button')),
    );
    await tester.tap(find.byKey(const Key('cast-next-liuyao-line-button')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('liuyao-advanced-options')),
    );
    await tester.tap(find.byKey(const Key('liuyao-advanced-options')));
    await tester.pump();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('liuyao-intention-field')))
          .enabled,
      isTrue,
    );
  });

  testWidgets('liuyao advanced editing stays enabled after completion', (
    tester,
  ) async {
    await _pumpLiuyao(
      tester,
      random: _RecordingRandomSource(const <int>[]),
      initialConfig: const LiuyaoConfig(mode: LiuyaoMode.manual),
    );

    for (var index = 0; index < 6; index++) {
      await _tapCurrentLine(tester, manual: true);
    }
    await _openLiuyaoAdvancedOptions(tester);

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('liuyao-intention-field')))
          .enabled,
      isTrue,
    );
  });

  testWidgets('app hide keeps the one saved line without extra random use', (
    tester,
  ) async {
    final random = _RecordingRandomSource(<int>[1, 1, 1]);
    final repository = _RecordingRepository();
    final feedback = _RecordingFeedbackService(repository);
    await _pumpLiuyao(
      tester,
      random: random,
      repository: repository,
      feedback: feedback,
      reduceMotion: false,
    );

    await tester.ensureVisible(
      find.byKey(const Key('cast-next-liuyao-line-button')),
    );
    await tester.tap(find.byKey(const Key('cast-next-liuyao-line-button')));
    await tester.pump();
    expect(repository.latest, isNotNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();

    expect(random.consumed, 3);
    final feedbackCount = feedback.intensities.length;
    await tester.pump(const Duration(seconds: 2));
    expect(random.consumed, 3);
    expect(feedback.intensities, hasLength(feedbackCount));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await _showDraftMeaning(tester);
    expect(find.text('初爻 · 6 · 老阴 · 动'), findsOneWidget);
  });

  testWidgets('restores partial draft without pre-generating the next line', (
    tester,
  ) async {
    final repository = _RecordingRepository();
    final firstRandom = _RecordingRandomSource(<int>[0, 0, 1]);
    await _pumpLiuyao(tester, random: firstRandom, repository: repository);
    await _tapCurrentLine(tester);
    expect(firstRandom.consumed, 3);

    await tester.pumpWidget(const SizedBox.shrink());
    final restoreRandom = _RecordingRandomSource(const <int>[]);
    await _pumpLiuyao(tester, random: restoreRandom, repository: repository);

    expect(find.textContaining('已确认 1/6 爻'), findsWidgets);
    await _showDraftMeaning(tester);
    expect(find.text('初爻 · 8 · 少阴 · 静'), findsOneWidget);
    expect(find.byKey(const Key('liuyao-current-coins')), findsOneWidget);
    expect(restoreRandom.consumed, 0);
  });

  testWidgets('restart creates a parent-linked private-free draft', (
    tester,
  ) async {
    final repository = _RecordingRepository();
    final ids = _SequenceIdSource(<String>['first-reading', 'linked-draft']);
    await _pumpLiuyao(
      tester,
      random: _RecordingRandomSource(const <int>[]),
      repository: repository,
      idSource: ids,
      initialConfig: const LiuyaoConfig(
        mode: LiuyaoMode.manual,
        intention: 'private question',
      ),
    );
    for (var index = 0; index < 6; index++) {
      await _tapCurrentLine(tester, manual: true);
    }

    await tester.ensureVisible(find.byKey(const Key('restart-liuyao-button')));
    await tester.tap(find.byKey(const Key('restart-liuyao-button')));
    await tester.pump();

    expect(repository.records, hasLength(2));
    final linked = repository.latest!;
    expect(linked.id, 'linked-draft');
    expect(linked.parentSessionId, 'first-reading');
    expect(linked.status, SessionStatus.draft);
    expect(linked.input['intention'], isNull);
    expect(linked.outcome['lineCount'], 0);
    expect(find.textContaining('已确认 0/6 爻'), findsWidgets);
  });

  testWidgets('360px at 200 percent completes a readable static result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpLiuyao(
      tester,
      random: _RecordingRandomSource(const <int>[]),
      initialConfig: const LiuyaoConfig(mode: LiuyaoMode.manual),
      textScaler: const TextScaler.linear(2),
    );

    for (var index = 0; index < 6; index++) {
      await _tapCurrentLine(tester, manual: true);
    }

    expect(tester.takeException(), isNull);
    expect(find.text('本卦 · 第 2 卦 坤'), findsOneWidget);
    expect(find.text('变卦 · 第 1 卦 乾'), findsOneWidget);
    expect(find.text('内容边界'), findsNothing);
  });
}

Future<void> _tapCurrentLine(WidgetTester tester, {bool manual = false}) async {
  final key = manual
      ? const Key('confirm-liuyao-line-button')
      : const Key('cast-next-liuyao-line-button');
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
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
  SessionRepository? repository,
  FeedbackService feedback = const NoopFeedbackService(),
  LiuyaoSessionIdSource? idSource,
  LiuyaoConfig? initialConfig,
  String? initialParentSessionId,
  bool reduceMotion = true,
  TextScaler? textScaler,
}) async {
  final resolvedRepository = repository ?? _RecordingRepository();
  final resolvedIdSource =
      idSource ??
      _SequenceIdSource(
        List<String>.generate(16, (index) => 'liuyao-default-$index'),
      );
  final module = LiuyaoToolModule(
    sessionRepository: resolvedRepository,
    sessionIdSource: resolvedIdSource,
  );
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
        sessionRepository: module.sessionRepository,
        sessionAdapter: module.toolSessionAdapter,
        sessionIdSource: module.sessionIdSource,
        initialConfig: initialConfig,
        initialParentSessionId: initialParentSessionId,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _openLiuyaoAdvancedOptions(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('liuyao-advanced-options')));
  await tester.tap(find.byKey(const Key('liuyao-advanced-options')));
  await tester.pumpAndSettle();
}

final class _RecordingRandomSource implements RandomSource {
  _RecordingRandomSource(Iterable<int> values)
    : _delegate = SequenceRandomSource(values);

  final SequenceRandomSource _delegate;

  int get consumed => _delegate.consumed;

  @override
  int nextInt(int maxExclusive) => _delegate.nextInt(maxExclusive);
}

class _RecordingRepository implements SessionRepository {
  final List<SessionRecord> writes = <SessionRecord>[];
  final Map<String, SessionRecord> _records = <String, SessionRecord>{};

  List<SessionRecord> get records =>
      List<SessionRecord>.unmodifiable(_records.values);
  SessionRecord? get latest =>
      _records.isEmpty ? null : _records.values.toList().last;

  @override
  Future<SessionRecord?> findById(String id) async => _records[id];

  @override
  Future<List<SessionRecord>> findAll() async =>
      List<SessionRecord>.unmodifiable(_records.values.toList().reversed);

  @override
  Future<void> save(SessionRecord session) async {
    writes.add(session);
    _records[session.id] = session;
  }
}

final class _DeferredRepository extends _RecordingRepository {
  final Completer<void> _completer = Completer<void>();

  void allowSave() => _completer.complete();

  @override
  Future<void> save(SessionRecord session) {
    writes.add(session);
    _records[session.id] = session;
    return _completer.future;
  }
}

final class _RecordingFeedbackService implements FeedbackService {
  _RecordingFeedbackService(this.repository);

  final _RecordingRepository repository;
  final List<FeedbackIntensity> intensities = <FeedbackIntensity>[];
  final List<int> writeCountsAtEmit = <int>[];

  @override
  Future<void> emit(FeedbackIntensity intensity) async {
    intensities.add(intensity);
    writeCountsAtEmit.add(repository.writes.length);
  }
}

final class _SequenceIdSource implements LiuyaoSessionIdSource {
  _SequenceIdSource(Iterable<String> ids)
    : _ids = List<String>.unmodifiable(ids);

  final List<String> _ids;
  var _index = 0;

  @override
  String next() => _ids[_index++];
}
