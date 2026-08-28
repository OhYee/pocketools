import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_id_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/features/dice/domain/dice_models.dart';
import 'package:pocketools/features/dice/domain/dice_roller.dart';
import 'package:pocketools/features/dice/presentation/dice_tool_module.dart';
import 'package:pocketools/features/dice/presentation/dice_tool_page.dart';

void main() {
  testWidgets('D20 commits its frozen session before feedback or reveal', (
    tester,
  ) async {
    final repository = _DeferredRepository();
    final feedback = _RecordingFeedback();
    final idSource = _SequenceIdSource(<String>['dice-commit']);
    final module = DiceToolModule(
      sessionRepository: repository,
      sessionIdSource: idSource,
    );
    await _pumpPage(
      tester,
      module: module,
      random: SequenceRandomSource(const <int>[0]),
      feedback: feedback,
      reduceMotion: false,
    );

    await tester.ensureVisible(find.byKey(const Key('roll-button')));
    await tester.tap(find.byKey(const Key('roll-button')));
    await tester.pump();

    expect(repository.writes, hasLength(1));
    expect(repository.writes.single.status, SessionStatus.completed);
    expect(feedback.values, isEmpty);
    expect(find.text('总值'), findsNothing);

    repository.allowSave();
    await tester.pump();
    expect(feedback.values, <FeedbackIntensity>[FeedbackIntensity.light]);
    await tester.pumpAndSettle();
    expect(find.text('总值'), findsOneWidget);
  });

  testWidgets('D20 restores total 41 without entropy and reroll links parent', (
    tester,
  ) async {
    final repository = InMemorySessionRepository();
    final idSource = _SequenceIdSource(<String>['dice-parent', 'dice-child']);
    final module = DiceToolModule(
      sessionRepository: repository,
      sessionIdSource: idSource,
    );
    const config = DicePoolConfig(
      diceCount: 4,
      diceSides: 20,
      aggregation: DiceAggregation.keepHighest,
      keepCount: 3,
      modifier: 5,
      dc: 35,
    );
    final parentResult = DiceRoller(
      SequenceRandomSource(const <int>[7, 15, 3, 11]),
    ).roll(config);
    final parent = module.toolSessionAdapter.createSession(
      id: idSource.next(),
      schemaVersion: 1,
      ruleVersion: DiceRoller.ruleVersion,
      algorithmVersion: DiceRoller.algorithmVersion,
      status: SessionStatus.completed,
      input: config,
      outcome: parentResult,
    );
    await repository.save(parent);
    final random = _RecordingRandom();

    await _pumpPage(
      tester,
      module: module,
      random: random,
      feedback: const NoopFeedbackService(),
      reduceMotion: true,
    );
    await tester.pumpAndSettle();

    expect(find.text('41'), findsOneWidget);
    expect(random.consumed, 0);
    await tester.ensureVisible(find.text('再来一次'));
    await tester.tap(find.text('再来一次'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('roll-button')));
    await tester.tap(find.byKey(const Key('roll-button')));
    await tester.pumpAndSettle();

    final sessions = await repository.findAll();
    expect(sessions, hasLength(2));
    expect(sessions.first.id, 'dice-child');
    expect(sessions.first.parentSessionId, parent.id);
    expect(random.consumed, 4);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required DiceToolModule module,
  required RandomSource random,
  required FeedbackService feedback,
  required bool reduceMotion,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: DiceToolPage(
        moduleContext: ToolModuleContext(
          randomSource: random,
          feedbackService: feedback,
          reduceMotion: reduceMotion,
          feedbackEnabled: feedback is! NoopFeedbackService,
        ),
        sessionRepository: module.sessionRepository,
        sessionAdapter: module.toolSessionAdapter,
        sessionIdSource: module.sessionIdSource,
      ),
    ),
  );
  await tester.pump();
}

final class _DeferredRepository implements SessionRepository {
  final List<SessionRecord> writes = <SessionRecord>[];
  final Completer<void> _save = Completer<void>();

  void allowSave() => _save.complete();

  @override
  Future<void> save(SessionRecord session) {
    writes.add(session);
    return _save.future;
  }

  @override
  Future<SessionRecord?> findById(String id) async => null;

  @override
  Future<List<SessionRecord>> findAll() async => const <SessionRecord>[];
}

final class _RecordingFeedback implements FeedbackService {
  final List<FeedbackIntensity> values = <FeedbackIntensity>[];

  @override
  Future<void> emit(FeedbackIntensity intensity) async => values.add(intensity);
}

final class _SequenceIdSource implements SessionIdSource {
  _SequenceIdSource(Iterable<String> values)
    : _values = List<String>.of(values);

  final List<String> _values;
  var _index = 0;

  @override
  String next() => _values[_index++];
}

final class _RecordingRandom implements RandomSource {
  var consumed = 0;

  @override
  int nextInt(int maxExclusive) {
    consumed++;
    return 0;
  }
}
