import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_session_adapter.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/features/cards/domain/card_models.dart';
import 'package:pocketools/features/cards/presentation/card_session_codec.dart';
import 'package:pocketools/features/cards/presentation/card_session_id_source.dart';
import 'package:pocketools/features/cards/presentation/card_tool_page.dart';
import 'package:pocketools/features/cards/presentation/widgets/playing_card_view.dart';

void main() {
  testWidgets('advanced options support drawing from multiple decks', (
    tester,
  ) async {
    await _pumpCards(tester);

    final advancedOptions = find.byKey(const Key('cards-advanced-options'));
    await tester.ensureVisible(advancedOptions);
    await tester.tap(advancedOptions);
    await tester.pumpAndSettle();

    final deckCountStepper = find.byKey(const Key('card-deck-count-stepper'));
    expect(deckCountStepper, findsOneWidget);
    await tester.tap(
      find.descendant(of: deckCountStepper, matching: find.byIcon(Icons.add)),
    );
    await tester.pump();

    expect(find.textContaining('2 副牌'), findsWidgets);
    expect(find.textContaining('104 张'), findsWidgets);
  });

  testWidgets(
    'cards draw one card from the deck and keep the deck available for the next draw',
    (tester) async {
      await _pumpCards(tester);

      final deck = find.byKey(const Key('cards-deck'));
      expect(deck, findsOneWidget);
      expect(tester.getSize(deck).height, greaterThan(156));
      expect(find.byKey(const Key('draw-cards-button')), findsNothing);

      await tester.tap(deck);
      await tester.pumpAndSettle();
      expect(find.byType(PlayingCardView), findsOneWidget);

      await tester.tap(deck);
      await tester.pumpAndSettle();
      expect(find.byType(PlayingCardView), findsNWidgets(2));
    },
  );

  testWidgets(
    'configured n stays in the session while each tap adds one card',
    (tester) async {
      await _pumpCards(
        tester,
        initialConfig: const CardDrawConfig(drawCount: 3),
      );

      final deck = find.byKey(const Key('cards-deck'));
      await tester.tap(deck);
      await tester.pumpAndSettle();
      expect(find.byType(PlayingCardView), findsOneWidget);
      expect(find.text('51 张'), findsOneWidget);

      await tester.tap(deck);
      await tester.pumpAndSettle();
      expect(find.byType(PlayingCardView), findsNWidgets(2));
      expect(find.text('50 张'), findsOneWidget);
    },
  );
}

Future<void> _pumpCards(
  WidgetTester tester, {
  CardDrawConfig initialConfig = const CardDrawConfig(drawCount: 1),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: CardToolPage(
        moduleContext: ToolModuleContext(
          randomSource: SequenceRandomSource(<int>[
            ...List<int>.filled(160, 0),
          ]),
          feedbackService: const NoopFeedbackService(),
          reduceMotion: true,
          feedbackEnabled: false,
        ),
        sessionRepository: _EmptySessionRepository(),
        sessionAdapter: ToolSessionAdapter(
          descriptor: const ToolDescriptor(
            id: 'cards',
            name: '抽扑克牌',
            description: 'interaction test',
            route: '/tools/cards',
            icon: Icons.style_outlined,
            accent: ToolAccent.cards,
          ),
          codec: const CardSessionCodec(),
        ),
        sessionIdSource: _CardTestIdSource(),
        initialConfig: initialConfig,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _EmptySessionRepository implements SessionRepository {
  @override
  Future<SessionRecord?> findById(String id) async => null;

  @override
  Future<List<SessionRecord>> findAll() async => const <SessionRecord>[];

  @override
  Future<void> save(SessionRecord session) async {}
}

final class _CardTestIdSource implements CardSessionIdSource {
  var _nextId = 0;

  @override
  String next() => 'cards-interaction-${++_nextId}';
}
