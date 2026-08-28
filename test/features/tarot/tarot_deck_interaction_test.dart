import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_session_adapter.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/features/tarot/presentation/tarot_session_codec.dart';
import 'package:pocketools/features/tarot/presentation/tarot_session_id_source.dart';
import 'package:pocketools/features/tarot/presentation/tarot_tool_page.dart';

void main() {
  testWidgets(
    'tarot starts with a tall deck, draws one card, and opens its meaning on tap',
    (tester) async {
      await _pumpTarot(tester);

      final deck = find.byKey(const Key('tarot-deck'));
      expect(deck, findsOneWidget);
      expect(tester.getSize(deck).height, greaterThan(216));
      expect(find.byKey(const Key('draw-tarot-button')), findsNothing);

      await tester.tap(deck);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tarot-deck')), findsOneWidget);
      expect(find.byKey(const Key('tarot-drawn-card-0')), findsOneWidget);
      expect(find.byKey(const Key('tarot-drawn-card-1')), findsNothing);
      expect(find.byKey(const Key('tarot-interpretation-0')), findsNothing);

      final drawnCard = find.byKey(const Key('tarot-drawn-card-0'));
      await tester.ensureVisible(drawnCard);
      await tester.tap(drawnCard);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('tarot-interpretation-sheet-0')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('tarot-interpretation-0')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('tarot-drawn-card-0')),
          matching: find.byKey(const Key('tarot-interpretation-0')),
        ),
        findsNothing,
      );
    },
  );
}

Future<void> _pumpTarot(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: TarotToolPage(
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
            id: 'tarot',
            name: '塔罗',
            description: 'interaction test',
            route: '/tools/tarot',
            icon: Icons.auto_awesome_outlined,
            accent: ToolAccent.tarot,
          ),
          codec: const TarotSessionCodec(),
        ),
        sessionIdSource: _TarotTestIdSource(),
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

final class _TarotTestIdSource implements TarotSessionIdSource {
  var _nextId = 0;

  @override
  String next() => 'tarot-interaction-${++_nextId}';
}
