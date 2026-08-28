import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/pocketools_app.dart';
import 'package:pocketools/app/registry/default_tool_registry.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_id_source.dart';

void main() {
  testWidgets(
    'all tools stop before result entropy when session identity is unavailable',
    (tester) async {
      const cases = <({String toolId, Key actionKey})>[
        (toolId: 'tarot', actionKey: Key('tarot-deck')),
        (toolId: 'liuyao', actionKey: Key('cast-next-liuyao-line-button')),
        (toolId: 'd20', actionKey: Key('roll-button')),
        (toolId: 'coin', actionKey: Key('toss-coin-button')),
        (toolId: 'cards', actionKey: Key('cards-deck')),
        (toolId: 'multi_divination', actionKey: Key('multi-divination-deck')),
      ];

      for (final testCase in cases) {
        final repository = InMemorySessionRepository();
        final random = _RecordingRandomSource();
        final feedback = _RecordingFeedbackService();
        final idSource = _FailingSessionIdSource();
        final registry = buildDefaultToolRegistry(
          sessionRepository: repository,
          sessionIdSource: idSource,
        );

        await tester.pumpWidget(
          PocketoolsApp(
            registry: registry,
            randomSource: random,
            feedbackService: feedback,
            sessionRepository: repository,
            sessionIdSource: idSource,
          ),
        );
        final homeTool = find.byKey(Key('home-tool-${testCase.toolId}'));
        await tester.ensureVisible(homeTool);
        await tester.pump();
        await tester.tap(homeTool);
        await tester.pumpAndSettle();
        expect(find.byKey(testCase.actionKey), findsOneWidget);

        await tester.ensureVisible(find.byKey(testCase.actionKey));
        await tester.pump();
        await tester.tap(find.byKey(testCase.actionKey));
        await tester.pump();

        expect(find.textContaining('安全会话标识不可用'), findsOneWidget);
        expect(random.consumed, 0, reason: testCase.toolId);
        expect(feedback.emissions, isEmpty, reason: testCase.toolId);
        expect(await repository.findAll(), isEmpty, reason: testCase.toolId);
        expect(tester.takeException(), isNull, reason: testCase.toolId);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
}

final class _FailingSessionIdSource implements SessionIdSource {
  @override
  String next() => throw const SessionIdGenerationException(
    'Secure entropy is unavailable; no session was created.',
  );
}

final class _RecordingRandomSource implements RandomSource {
  var consumed = 0;

  @override
  int nextInt(int maxExclusive) {
    consumed++;
    return 0;
  }
}

final class _RecordingFeedbackService implements FeedbackService {
  final List<FeedbackIntensity> emissions = <FeedbackIntensity>[];

  @override
  Future<void> emit(FeedbackIntensity intensity) async {
    emissions.add(intensity);
  }
}
