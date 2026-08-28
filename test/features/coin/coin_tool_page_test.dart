import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_session_adapter.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/design_system/components/app_button.dart';
import 'package:pocketools/features/coin/domain/coin_models.dart';
import 'package:pocketools/features/coin/presentation/coin_session_codec.dart';
import 'package:pocketools/features/coin/presentation/coin_session_id_source.dart';
import 'package:pocketools/features/coin/presentation/coin_tool_page.dart';

void main() {
  testWidgets('entity and completed primary action both toss without reset', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
    await _pumpCoinPage(
      tester,
      randomSource: SequenceRandomSource(const <int>[0, 1]),
      repository: repository,
      idSource: _SequenceCoinSessionIdSource(<String>[
        'coin-first',
        'coin-second',
      ]),
    );

    expect(find.byKey(const Key('coin-ready-physical-entity')), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const Key('coin-ready-physical-entity')))
          .flagsCollection
          .isButton,
      isTrue,
    );
    expect(find.text('点击硬币或下方按钮抛掷'), findsOneWidget);

    await tester.tap(find.byKey(const Key('coin-ready-physical-entity')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(repository.saved, hasLength(1));
    expect(find.byKey(const Key('reset-coin-button')), findsNothing);
    expect(
      tester
          .widget<AppButton>(find.byKey(const Key('toss-coin-button')))
          .onPressed,
      isNotNull,
    );

    await tester.ensureVisible(find.byKey(const Key('toss-coin-button')));
    await tester.tap(find.byKey(const Key('toss-coin-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(repository.saved, hasLength(2));
    expect(repository.saved.last.parentSessionId, 'coin-first');
  });

  testWidgets('completed toss uses the edited config on the next toss', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
    await _pumpCoinPage(
      tester,
      randomSource: _RecordingRandomSource(List<int>.filled(20, 0)),
      repository: repository,
      idSource: _SequenceCoinSessionIdSource(<String>[
        'coin-config-first',
        'coin-config-second',
      ]),
    );

    await tester.tap(find.byKey(const Key('toss-coin-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await _openCoinAdvancedOptions(tester);
    await tester.tap(find.text('批量'));
    await tester.pump();
    final batchFive = find.descendant(
      of: find.byKey(const Key('coin-batch-shortcuts')),
      matching: find.text('5'),
    );
    await tester.ensureVisible(batchFive);
    await tester.tap(batchFive);
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('toss-coin-button')));
    await tester.tap(find.byKey(const Key('toss-coin-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(repository.saved, hasLength(2));
    expect(repository.saved.last.input['mode'], 'batch');
    expect(repository.saved.last.input['batchCount'], 5);
  });

  testWidgets('explicit coin launch does not restore the latest result', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
    await _pumpCoinPage(
      tester,
      randomSource: SequenceRandomSource(const <int>[0]),
      repository: repository,
      idSource: _SequenceCoinSessionIdSource(<String>['coin-existing']),
    );
    await tester.tap(find.byKey(const Key('toss-coin-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await _pumpCoinPage(
      tester,
      randomSource: _RecordingRandomSource(const <int>[]),
      repository: repository,
      initialConfig: const CoinTossConfig(mode: CoinTossMode.batch),
      initialParentSessionId: 'coin-existing',
    );

    expect(find.text('准备就绪'), findsOneWidget);
    expect(find.text('结果已完成'), findsNothing);
    expect(find.text('抛 3 次'), findsOneWidget);
  });

  testWidgets(
    'entity stays actionable while local session restore is pending',
    (tester) async {
      final repository = _BlockingRestoreSessionRepository();
      await _pumpCoinPage(
        tester,
        randomSource: SequenceRandomSource(const <int>[0]),
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('coin-ready-physical-entity')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(repository.saved, hasLength(1));
      repository.allowRestore();
      await tester.pump();
      expect(find.text('结果已完成'), findsOneWidget);
    },
  );

  testWidgets('top entity owns status and result without a process layer', (
    tester,
  ) async {
    await _pumpCoinPage(
      tester,
      randomSource: SequenceRandomSource(const <int>[0]),
    );

    await tester.tap(find.byKey(const Key('toss-coin-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final entity = find.byKey(const Key('coin-core-entity'));
    expect(
      find.descendant(of: entity, matching: find.text('结果已完成')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: entity, matching: find.text('原始面值：heads（正面）')),
      findsOneWidget,
    );
    expect(find.text('生成状态'), findsNothing);
    expect(find.text('查看过程'), findsNothing);
    expect(find.byKey(const Key('coin-process-details')), findsNothing);

    await tester.tap(find.byKey(const Key('coin-result-physical-entity')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byKey(const Key('coin-process-details')), findsNothing);
  });

  testWidgets(
    'Android starts optional motion input without blocking manual use',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      var starts = 0;
      const channel = MethodChannel('pocketools/motion_sensor');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'start') starts++;
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );

      await _pumpCoinPage(
        tester,
        randomSource: SequenceRandomSource(const <int>[0]),
        reduceMotion: false,
      );
      await tester.pump();

      expect(starts, 1);
      expect(
        tester
            .widget<AppButton>(find.byKey(const Key('toss-coin-button')))
            .onPressed,
        isNotNull,
      );
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('offers single and batch defaults 3 5 10 with range 1 to 100', (
    tester,
  ) async {
    await _pumpCoinPage(
      tester,
      randomSource: SequenceRandomSource(const <int>[0]),
    );
    await _openCoinAdvancedOptions(tester);

    expect(find.text('单次 · 正面 / 反面；原始值 heads / tails'), findsOneWidget);
    expect(find.text('抛一次'), findsOneWidget);
    expect(find.byKey(const Key('coin-batch-count-stepper')), findsNothing);

    await tester.tap(find.text('批量'));
    await tester.pump();

    for (final shortcut in <String>['3', '5', '10']) {
      expect(find.text(shortcut), findsWidgets);
    }
    expect(find.text('范围：1～100'), findsOneWidget);
    expect(find.text('抛 3 次'), findsOneWidget);
    expect(find.byKey(const Key('coin-race-switch')), findsOneWidget);
  });

  testWidgets('invalid visible config disables generation without random use', (
    tester,
  ) async {
    final random = _RecordingRandomSource(const <int>[0]);
    final repository = _RecordingSessionRepository();
    await _pumpCoinPage(tester, randomSource: random, repository: repository);
    await _openCoinAdvancedOptions(tester);

    await tester.tap(find.text('批量'));
    await tester.pump();
    final countField = find.descendant(
      of: find.byKey(const Key('coin-batch-count-stepper')),
      matching: find.byType(TextField),
    );
    await tester.enterText(countField, '101');
    await tester.pump();

    expect(find.text('请输入 1～100 的整数。'), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(find.byKey(const Key('toss-coin-button')))
          .onPressed,
      isNull,
    );

    await tester.ensureVisible(
      find.byKey(const Key('custom-coin-labels-switch')),
    );
    await tester.tap(find.byKey(const Key('custom-coin-labels-switch')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('coin-heads-label-field')));
    await tester.enterText(
      find.byKey(const Key('coin-heads-label-field')),
      ' same ',
    );
    await tester.ensureVisible(find.byKey(const Key('coin-tails-label-field')));
    await tester.enterText(
      find.byKey(const Key('coin-tails-label-field')),
      'same',
    );
    await tester.pump();

    expect(find.text('两个标签不能相同。'), findsNWidgets(2));
    expect(random.consumed, 0);
    expect(repository.saved, isEmpty);
  });

  testWidgets('advanced editing stays enabled during and after coin motion', (
    tester,
  ) async {
    await _pumpCoinPage(
      tester,
      randomSource: SequenceRandomSource(const <int>[0]),
      reduceMotion: false,
    );

    await tester.tap(find.byKey(const Key('toss-coin-button')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('coin-advanced-options')));
    await tester.tap(find.byKey(const Key('coin-advanced-options')));
    await tester.pump();

    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('custom-coin-labels-switch')),
          )
          .onChanged,
      isNotNull,
    );

    await tester.pump(const Duration(seconds: 2));
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('custom-coin-labels-switch')),
          )
          .onChanged,
      isNotNull,
    );
  });

  testWidgets('persists frozen result before motion and feedback', (
    tester,
  ) async {
    final random = _RecordingRandomSource(const <int>[0]);
    final repository = _DeferredSessionRepository();
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
    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.status, SessionStatus.completed);
    expect(repository.saved.single.outcome['sequence'], const <Object?>[
      'heads',
    ]);
    expect(feedback.intensities, isEmpty);
    expect(find.text('设置已冻结'), findsOneWidget);

    repository.allowSave();
    await tester.pump();
    expect(feedback.intensities, <FeedbackIntensity>[FeedbackIntensity.medium]);
    expect(feedback.savedCountsAtEmit, <int>[1]);

    await tester.pump(const Duration(milliseconds: 90));
    expect(find.text('结果已冻结，准备抛起'), findsOneWidget);
    expect(find.text('硬币结果已经冻结，面值尚未揭示'), findsNothing);

    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('结果已生成，正在抛起、翻转并落定'), findsOneWidget);
    expect(find.text('正面'), findsOneWidget);
    expect(feedback.intensities, <FeedbackIntensity>[
      FeedbackIntensity.medium,
      FeedbackIntensity.light,
    ]);

    await tester.pump(const Duration(milliseconds: 720));
    expect(find.text('结果已完成'), findsOneWidget);
    expect(find.text('原始面值：heads（正面）'), findsOneWidget);
    expect(random.consumed, 1);
    expect(repository.saved, hasLength(1));
    expect(feedback.intensities, <FeedbackIntensity>[
      FeedbackIntensity.medium,
      FeedbackIntensity.light,
      FeedbackIntensity.light,
    ]);
  });

  testWidgets('custom batch keeps raw sequence counts labels and proportions', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
    await _pumpCoinPage(
      tester,
      randomSource: SequenceRandomSource(const <int>[0, 1, 0]),
      repository: repository,
      initialConfig: const CoinTossConfig(
        mode: CoinTossMode.batch,
        batchCount: 3,
        headsLabel: ' 甲 ',
        tailsLabel: ' 乙 ',
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('toss-coin-button')));
    await tester.tap(find.byKey(const Key('toss-coin-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('共抛 3 次'), findsOneWidget);
    expect(find.text('66.7%'), findsOneWidget);
    expect(find.text('33.3%'), findsOneWidget);
    expect(find.text('已完成配置的 3 次'), findsWidgets);
    expect(repository.saved.single.input['headsLabel'], '甲');
    expect(repository.saved.single.input['tailsLabel'], '乙');
    expect(repository.saved.single.outcome['sequence'], const <Object?>[
      'heads',
      'tails',
      'heads',
    ]);
  });

  testWidgets('race stops immediately and reports its stopping reason', (
    tester,
  ) async {
    final random = _RecordingRandomSource(const <int>[0, 1, 0, 1, 0, 1]);
    await _pumpCoinPage(
      tester,
      randomSource: random,
      initialConfig: const CoinTossConfig(
        mode: CoinTossMode.batch,
        raceTarget: 3,
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('toss-coin-button')));
    await tester.tap(find.byKey(const Key('toss-coin-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('正面率先达到 3 次，共抛 5 次'), findsWidgets);
    expect(random.consumed, 5);
  });

  testWidgets('retoss creates a child session and preserves first record', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
    final random = _RecordingRandomSource(const <int>[0, 1]);
    await _pumpCoinPage(
      tester,
      randomSource: random,
      repository: repository,
      idSource: _SequenceCoinSessionIdSource(<String>[
        'coin-first',
        'coin-second',
      ]),
    );

    await tester.tap(find.byKey(const Key('toss-coin-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final first = repository.saved.single;

    await tester.ensureVisible(find.byKey(const Key('toss-coin-button')));
    await tester.tap(find.byKey(const Key('toss-coin-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(repository.saved, hasLength(2));
    expect(repository.saved.first, same(first));
    expect(repository.saved.first.id, 'coin-first');
    expect(repository.saved.first.parentSessionId, isNull);
    expect(repository.saved.last.id, 'coin-second');
    expect(repository.saved.last.parentSessionId, 'coin-first');
    expect(repository.saved.first.outcome['sequence'], const <Object?>[
      'heads',
    ]);
    expect(repository.saved.last.outcome['sequence'], const <Object?>['tails']);
  });

  testWidgets('page hide skips visual timeline without redraw or old haptics', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
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
    expect(feedback.intensities, <FeedbackIntensity>[FeedbackIntensity.medium]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();

    expect(find.text('结果已完成'), findsOneWidget);
    expect(find.text('原始面值：tails（反面）'), findsOneWidget);
    expect(random.consumed, 1);
    expect(repository.saved, hasLength(1));
    expect(feedback.intensities, <FeedbackIntensity>[FeedbackIntensity.medium]);

    await tester.pump(const Duration(seconds: 2));
    expect(feedback.intensities, <FeedbackIntensity>[FeedbackIntensity.medium]);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('hide while save is pending completes frozen result silently', (
    tester,
  ) async {
    final repository = _DeferredSessionRepository();
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
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    repository.allowSave();
    await tester.pump();

    expect(find.text('结果已完成'), findsOneWidget);
    expect(find.text('原始面值：heads（正面）'), findsOneWidget);
    expect(random.consumed, 1);
    expect(repository.saved, hasLength(1));
    expect(feedback.intensities, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('skip reveals the same saved result and cancels later feedback', (
    tester,
  ) async {
    final repository = _RecordingSessionRepository();
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
    await tester.ensureVisible(
      find.byKey(const Key('skip-coin-animation-button')),
    );
    await tester.tap(find.byKey(const Key('skip-coin-animation-button')));
    await tester.pump();

    expect(find.text('结果已完成'), findsOneWidget);
    expect(find.text('原始面值：tails（反面）'), findsOneWidget);
    expect(random.consumed, 1);
    expect(repository.saved, hasLength(1));
    expect(feedback.intensities, <FeedbackIntensity>[FeedbackIntensity.medium]);

    await tester.pump(const Duration(seconds: 2));
    expect(feedback.intensities, <FeedbackIntensity>[FeedbackIntensity.medium]);
  });

  testWidgets('360px viewport at 200 percent text completes without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpCoinPage(
      tester,
      randomSource: SequenceRandomSource(const <int>[0]),
      textScaler: const TextScaler.linear(2),
    );

    await tester.ensureVisible(find.byKey(const Key('toss-coin-button')));
    await tester.tap(find.byKey(const Key('toss-coin-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(tester.takeException(), isNull);
    expect(find.text('结果已完成'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label?.contains('原始面值 heads') == true,
      ),
      findsWidgets,
    );
  });
}

Future<void> _pumpCoinPage(
  WidgetTester tester, {
  required RandomSource randomSource,
  SessionRepository? repository,
  ToolSessionAdapter? adapter,
  CoinSessionIdSource? idSource,
  FeedbackService feedbackService = const NoopFeedbackService(),
  bool reduceMotion = true,
  CoinTossConfig? initialConfig,
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
      home: CoinToolPage(
        moduleContext: ToolModuleContext(
          randomSource: randomSource,
          feedbackService: feedbackService,
          reduceMotion: reduceMotion,
          feedbackEnabled: feedbackService is! NoopFeedbackService,
        ),
        sessionRepository: repository ?? _RecordingSessionRepository(),
        sessionAdapter: adapter ?? _coinAdapter(),
        sessionIdSource:
            idSource ?? _SequenceCoinSessionIdSource(<String>['coin-default']),
        initialConfig: initialConfig,
        initialParentSessionId: initialParentSessionId,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _openCoinAdvancedOptions(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('coin-advanced-options')));
  await tester.tap(find.byKey(const Key('coin-advanced-options')));
  await tester.pumpAndSettle();
}

ToolSessionAdapter _coinAdapter() => ToolSessionAdapter(
  descriptor: const ToolDescriptor(
    id: 'coin',
    name: '抛硬币',
    description: 'Coin test module',
    route: '/tools/coin',
    icon: Icons.circle_outlined,
    accent: ToolAccent.coin,
  ),
  codec: const CoinSessionCodec(),
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

final class _BlockingRestoreSessionRepository
    extends _RecordingSessionRepository {
  final Completer<List<SessionRecord>> _restoreCompleter =
      Completer<List<SessionRecord>>();

  void allowRestore() => _restoreCompleter.complete(const <SessionRecord>[]);

  @override
  Future<List<SessionRecord>> findAll() => _restoreCompleter.future;
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

final class _SequenceCoinSessionIdSource implements CoinSessionIdSource {
  _SequenceCoinSessionIdSource(Iterable<String> ids)
    : _ids = List<String>.unmodifiable(ids);

  final List<String> _ids;
  var _index = 0;

  @override
  String next() => _ids[_index++];
}
