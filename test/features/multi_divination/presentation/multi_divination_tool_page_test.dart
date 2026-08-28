import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_id_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/features/multi_divination/domain/multi_divination_models.dart';
import 'package:pocketools/features/multi_divination/presentation/multi_divination_tool_module.dart';
import 'package:pocketools/features/multi_divination/presentation/multi_divination_tool_page.dart';

void main() {
  testWidgets('initial deck is a clickable physical entity', (tester) async {
    final random = _RecordingRandomSource(_entropyForGroups(1));
    await _pumpPage(tester, random: random);

    expect(
      find.byKey(const Key('multi-divination-core-entity')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('multi-divination-deck')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('multi-divination-deck')));
    await tester.tap(find.byKey(const Key('multi-divination-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(random.consumed, 80);
    expect(find.byKey(const Key('multi-divination-card-0-A')), findsOneWidget);
    expect(find.byKey(const Key('multi-divination-card-0-B')), findsOneWidget);
    expect(find.byKey(const Key('multi-divination-card-0-C')), findsOneWidget);
    expect(find.textContaining('已完成 1/6 组'), findsWidgets);
  });

  testWidgets('each deck tap appends three cards and keeps prior groups', (
    tester,
  ) async {
    final random = _RecordingRandomSource(_entropyForGroups(2));
    await _pumpPage(tester, random: random);

    await _tapDeck(tester);
    expect(find.byKey(const Key('multi-divination-card-0-A')), findsOneWidget);

    await _tapDeck(tester);
    expect(random.consumed, 83);
    for (final slot in <String>['A', 'B', 'C']) {
      expect(find.byKey(Key('multi-divination-card-0-$slot')), findsOneWidget);
      expect(find.byKey(Key('multi-divination-card-1-$slot')), findsOneWidget);
    }
    expect(find.textContaining('A1'), findsWidgets);
    expect(find.textContaining('A2'), findsWidgets);
  });

  testWidgets(
    'six groups show primary, moving lines, changed hexagram, and A summaries',
    (tester) async {
      final repository = _RecordingRepository();
      await _pumpPage(
        tester,
        random: _RecordingRandomSource(_entropyForGroups(6)),
        repository: repository,
      );

      for (
        var index = 0;
        index < MultiDivinationReading.groupCapacity;
        index++
      ) {
        await _tapDeck(tester);
      }

      expect(repository.latest, isNotNull);
      expect(repository.latest!.status, SessionStatus.completed);
      expect(
        find.byKey(const Key('multi-divination-primary-hexagram')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('multi-divination-entity-primary-summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('multi-divination-entity-moving-summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('multi-divination-entity-changed-summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('multi-divination-entity-a-summaries')),
        findsOneWidget,
      );
      expect(find.textContaining('本卦 · 第'), findsOneWidget);
      expect(find.textContaining('动爻：'), findsOneWidget);
      expect(
        find.byKey(const Key('multi-divination-changed-hexagram')),
        findsOneWidget,
      );
      expect(find.text('A1 摘要'), findsOneWidget);
      expect(find.text('A6 摘要'), findsOneWidget);
      expect(find.text('融合解释'), findsOneWidget);
    },
  );

  testWidgets('A card opens the existing Tarot interpretation sheet', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      random: _RecordingRandomSource(_entropyForGroups(1)),
    );
    await _tapDeck(tester);

    await tester.ensureVisible(
      find.byKey(const Key('multi-divination-card-action-0-A')),
    );
    await tester.tap(find.byKey(const Key('multi-divination-card-action-0-A')));
    await tester.pump();

    expect(
      find.byKey(const Key('tarot-interpretation-sheet-0')),
      findsOneWidget,
    );
    expect(find.textContaining('关键词：'), findsOneWidget);
  });

  testWidgets('B and C cards also open their Tarot interpretation sheets', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      random: _RecordingRandomSource(_entropyForGroups(1)),
    );
    await _tapDeck(tester);

    for (final entry in <String, int>{'B': 1, 'C': 2}.entries) {
      final action = find.byKey(
        Key('multi-divination-card-action-0-${entry.key}'),
      );
      expect(action, findsOneWidget);
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(
        find.byKey(Key('tarot-interpretation-sheet-${entry.value}')),
        findsOneWidget,
      );
      expect(find.textContaining('关键词：'), findsOneWidget);

      Navigator.of(
        tester.element(
          find.byKey(Key('tarot-interpretation-sheet-${entry.value}')),
        ),
      ).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('back button delegates to the module context', (tester) async {
    var didBack = false;
    await _pumpPage(
      tester,
      random: _RecordingRandomSource(const <int>[]),
      onBack: () => didBack = true,
    );

    await tester.tap(find.byKey(const Key('tool-back-button')));
    expect(didBack, isTrue);
  });

  testWidgets('editing intention applies to the next new reading', (
    tester,
  ) async {
    final repository = _RecordingRepository();
    final random = _RecordingRandomSource(<int>[
      ..._entropyForGroups(6),
      ..._entropyForGroups(1),
    ]);
    await _pumpPage(
      tester,
      random: random,
      repository: repository,
      initialConfig: const MultiDivinationConfig(intention: 'first question'),
      idSource: _SequenceIdSource(<String>['first', 'second']),
    );

    for (var index = 0; index < MultiDivinationReading.groupCapacity; index++) {
      await _tapDeck(tester);
    }
    expect(repository.latest!.input['intention'], 'first question');

    await tester.ensureVisible(
      find.byKey(const Key('multi-divination-advanced-options')),
    );
    await tester.tap(
      find.byKey(const Key('multi-divination-advanced-options')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('multi-divination-intention-field')),
      'second question',
    );
    await tester.pump();

    await _tapDeck(tester);
    expect(repository.records, hasLength(2));
    expect(repository.latest!.id, 'second');
    expect(repository.latest!.parentSessionId, 'first');
    expect(repository.latest!.input['intention'], 'second question');
    expect(repository.latest!.status, SessionStatus.ready);
  });

  testWidgets(
    'restores a partial group without reshuffling or consuming random',
    (tester) async {
      final repository = _RecordingRepository();
      await _pumpPage(
        tester,
        random: _RecordingRandomSource(_entropyForGroups(1)),
        repository: repository,
      );
      await _tapDeck(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      final restoredRandom = _RecordingRandomSource(const <int>[]);
      await _pumpPage(tester, random: restoredRandom, repository: repository);

      expect(
        find.byKey(const Key('multi-divination-card-0-A')),
        findsOneWidget,
      );
      expect(find.textContaining('已完成 1/6 组'), findsWidgets);
      expect(restoredRandom.consumed, 0);
    },
  );

  testWidgets(
    'explicit multi-divination launch does not restore the latest draft',
    (tester) async {
      final repository = _RecordingRepository();
      await _pumpPage(
        tester,
        random: _RecordingRandomSource(_entropyForGroups(1)),
        repository: repository,
        idSource: _SequenceIdSource(<String>['multi-existing']),
      );
      await _tapDeck(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await _pumpPage(
        tester,
        random: _RecordingRandomSource(const <int>[]),
        repository: repository,
        initialConfig: const MultiDivinationConfig(
          intention: 'explicit launch',
        ),
        initialParentSessionId: 'multi-existing',
      );

      expect(find.byKey(const Key('multi-divination-card-0-A')), findsNothing);
      expect(find.textContaining('已完成 1/6 组'), findsNothing);
    },
  );

  testWidgets('invalid configuration does not consume random entropy', (
    tester,
  ) async {
    final random = _RecordingRandomSource(const <int>[]);
    await _pumpPage(
      tester,
      random: random,
      initialConfig: MultiDivinationConfig(
        intention: 'x' * (MultiDivinationConfig.maximumIntentionLength + 1),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('multi-divination-deck')));
    await tester.tap(find.byKey(const Key('multi-divination-deck')));
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const Key('multi-divination-advanced-options')),
    );
    await tester.tap(
      find.byKey(const Key('multi-divination-advanced-options')),
    );
    await tester.pumpAndSettle();

    expect(random.consumed, 0);
    expect(find.textContaining('不能超过'), findsOneWidget);
  });

  testWidgets('skip and lifecycle hide reveal only the saved group', (
    tester,
  ) async {
    final random = _RecordingRandomSource(_entropyForGroups(1));
    final repository = _RecordingRepository();
    await _pumpPage(
      tester,
      random: random,
      repository: repository,
      reduceMotion: false,
    );

    await tester.ensureVisible(find.byKey(const Key('multi-divination-deck')));
    await tester.tap(find.byKey(const Key('multi-divination-deck')));
    await tester.pump();
    expect(repository.latest, isNotNull);
    expect(repository.latest!.status, SessionStatus.ready);

    await tester.ensureVisible(
      find.byKey(const Key('skip-multi-divination-animation-button')),
    );
    await tester.tap(
      find.byKey(const Key('skip-multi-divination-animation-button')),
    );
    await tester.pump();
    expect(find.textContaining('第 1 组已完成'), findsOneWidget);
    expect(random.consumed, 80);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump(const Duration(seconds: 2));
    expect(random.consumed, 80);
  });

  testWidgets('restart saves a parent-linked draft without consuming random', (
    tester,
  ) async {
    final repository = _RecordingRepository();
    final random = _RecordingRandomSource(_entropyForGroups(6));
    await _pumpPage(
      tester,
      random: random,
      repository: repository,
      idSource: _SequenceIdSource(<String>['first', 'draft']),
    );
    for (var index = 0; index < MultiDivinationReading.groupCapacity; index++) {
      await _tapDeck(tester);
    }

    await tester.ensureVisible(
      find.byKey(const Key('restart-multi-divination-button')),
    );
    await tester.tap(find.byKey(const Key('restart-multi-divination-button')));
    await tester.pump();

    expect(repository.records, hasLength(2));
    expect(repository.latest!.id, 'draft');
    expect(repository.latest!.parentSessionId, 'first');
    expect(repository.latest!.status, SessionStatus.draft);
    expect(repository.latest!.outcome['groupCount'], 0);
    expect(random.consumed, 95);
  });
}

Future<void> _tapDeck(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('multi-divination-deck')));
  await tester.tap(find.byKey(const Key('multi-divination-deck')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required RandomSource random,
  SessionRepository? repository,
  SessionIdSource? idSource,
  MultiDivinationConfig? initialConfig,
  String? initialParentSessionId,
  VoidCallback? onBack,
  bool reduceMotion = true,
}) async {
  final resolvedRepository = repository ?? _RecordingRepository();
  final module = MultiDivinationToolModule(
    sessionRepository: resolvedRepository,
    sessionIdSource:
        idSource ??
        _SequenceIdSource(
          List<String>.generate(16, (index) => 'reading-$index'),
        ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MultiDivinationToolPage(
        moduleContext: ToolModuleContext(
          randomSource: random,
          feedbackService: const NoopFeedbackService(),
          reduceMotion: reduceMotion,
          feedbackEnabled: false,
          onBack: onBack,
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

List<int> _entropyForGroups(int groupCount) => <int>[
  ...List<int>.filled(77, 0),
  ...List<int>.filled(groupCount * MultiDivinationReading.cardsPerGroup, 0),
];

final class _RecordingRandomSource implements RandomSource {
  _RecordingRandomSource(Iterable<int> values)
    : _delegate = SequenceRandomSource(values);

  final SequenceRandomSource _delegate;

  int get consumed => _delegate.consumed;

  @override
  int nextInt(int maxExclusive) => _delegate.nextInt(maxExclusive);
}

final class _SequenceIdSource implements SessionIdSource {
  _SequenceIdSource(Iterable<String> ids) : _ids = List<String>.of(ids);

  final List<String> _ids;
  var _index = 0;

  @override
  String next() => _ids[_index++];
}

final class _RecordingRepository implements SessionRepository {
  final List<SessionRecord> writes = <SessionRecord>[];
  final Map<String, SessionRecord> _records = <String, SessionRecord>{};

  List<SessionRecord> get records =>
      List<SessionRecord>.unmodifiable(_records.values.toList());

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
