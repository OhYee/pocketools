import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_id_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/features/cards/presentation/card_tool_module.dart';
import 'package:pocketools/features/cards/presentation/card_tool_page.dart';
import 'package:pocketools/features/coin/presentation/coin_tool_module.dart';
import 'package:pocketools/features/coin/presentation/coin_tool_page.dart';
import 'package:pocketools/features/dice/presentation/dice_tool_page.dart';
import 'package:pocketools/features/liuyao/presentation/liuyao_tool_module.dart';
import 'package:pocketools/features/liuyao/presentation/liuyao_tool_page.dart';
import 'package:pocketools/features/tarot/presentation/tarot_tool_module.dart';
import 'package:pocketools/features/tarot/presentation/tarot_tool_page.dart';

void main() {
  for (final page in _pages) {
    testWidgets(
      '${page.name} first screen exposes the simplified accessible shell',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: page.build(_testModuleContext()),
          ),
        );
        await tester.pump();
        await tester.pump();

        final core = find.byKey(Key(page.coreKey));
        final main = find.byKey(Key(page.mainKey));
        final reset = page.resetKey == null
            ? find.byWidgetPredicate((_) => false)
            : find.byKey(Key(page.resetKey!));
        final advanced = find.byKey(Key(page.advancedKey));

        expect(core, findsOneWidget);
        expect(main, findsOneWidget);
        if (page.resetKey == null) {
          expect(reset, findsNothing);
        } else {
          expect(reset, findsOneWidget);
        }
        expect(advanced, findsOneWidget);
        expect(
          tester.getTopLeft(core).dy,
          lessThan(tester.getTopLeft(main).dy),
          reason: 'The core entity must be above the primary action.',
        );
        if (page.resetKey != null) {
          expect(
            tester.getTopLeft(reset).dy,
            greaterThanOrEqualTo(tester.getTopLeft(main).dy),
            reason: 'Reset must remain below the primary entity interaction.',
          );
        }

        expect(tester.getSemantics(main).label, isNotEmpty);
        if (page.resetKey != null) {
          expect(tester.getSemantics(reset).label, contains('重置'));
        }
        expect(
          tester.widget<ExpansionTile>(advanced).initiallyExpanded,
          isFalse,
        );
        if (page.name == 'dice') {
          expect(find.byKey(Key(page.configKey)), findsOneWidget);
        } else {
          expect(find.byKey(Key(page.configKey)), findsNothing);
        }

        await tester.ensureVisible(advanced);
        await tester.tap(advanced);
        await tester.pumpAndSettle();
        expect(find.byKey(Key(page.configKey)), findsOneWidget);
      },
    );

    testWidgets('${page.name} core entity activates the same primary action', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: page.build(_testModuleContext()),
        ),
      );
      await tester.pump();

      final core = find.byKey(Key(page.coreKey));
      await tester.ensureVisible(core);
      await tester.tap(core);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.byKey(Key(page.mainKey)), findsOneWidget);
    });
  }
}

final class _PageCase {
  const _PageCase({
    required this.name,
    required this.build,
    required this.coreKey,
    required this.mainKey,
    required this.resetKey,
    required this.advancedKey,
    required this.configKey,
  });

  final String name;
  final Widget Function(ToolModuleContext) build;
  final String coreKey;
  final String mainKey;
  final String? resetKey;
  final String advancedKey;
  final String configKey;
}

final _pages = <_PageCase>[
  _PageCase(
    name: 'tarot',
    build: (context) {
      final repository = InMemorySessionRepository();
      final module = TarotToolModule();
      return TarotToolPage(
        moduleContext: context,
        sessionRepository: repository,
        sessionAdapter: module.toolSessionAdapter,
        sessionIdSource: _FixedSessionIdSource('tarot-layout'),
      );
    },
    coreKey: 'tarot-core-entity',
    mainKey: 'tarot-deck',
    resetKey: 'reset-tarot-button',
    advancedKey: 'tarot-advanced-options',
    configKey: 'tarot-minor-arcana-switch',
  ),
  _PageCase(
    name: 'liuyao',
    build: (context) {
      final repository = InMemorySessionRepository();
      final module = LiuyaoToolModule();
      return LiuyaoToolPage(
        moduleContext: context,
        sessionRepository: repository,
        sessionAdapter: module.toolSessionAdapter,
        sessionIdSource: _FixedSessionIdSource('liuyao-layout'),
      );
    },
    coreKey: 'liuyao-core-entity',
    mainKey: 'cast-next-liuyao-line-button',
    resetKey: 'reset-liuyao-button',
    advancedKey: 'liuyao-advanced-options',
    configKey: 'liuyao-mode-control',
  ),
  _PageCase(
    name: 'dice',
    build: (context) => DiceToolPage(moduleContext: context),
    coreKey: 'dice-core-entity',
    mainKey: 'roll-button',
    resetKey: null,
    advancedKey: 'dice-advanced-options',
    configKey: 'dice-quick-count-stepper',
  ),
  _PageCase(
    name: 'coin',
    build: (context) {
      final repository = InMemorySessionRepository();
      final module = CoinToolModule();
      return CoinToolPage(
        moduleContext: context,
        sessionRepository: repository,
        sessionAdapter: module.toolSessionAdapter,
        sessionIdSource: _FixedSessionIdSource('coin-layout'),
      );
    },
    coreKey: 'coin-core-entity',
    mainKey: 'toss-coin-button',
    resetKey: null,
    advancedKey: 'coin-advanced-options',
    configKey: 'coin-mode-control',
  ),
  _PageCase(
    name: 'cards',
    build: (context) {
      final repository = InMemorySessionRepository();
      final module = CardToolModule();
      return CardToolPage(
        moduleContext: context,
        sessionRepository: repository,
        sessionAdapter: module.toolSessionAdapter,
        sessionIdSource: _FixedSessionIdSource('cards-layout'),
      );
    },
    coreKey: 'cards-core-entity',
    mainKey: 'cards-deck',
    resetKey: 'reset-cards-button',
    advancedKey: 'cards-advanced-options',
    configKey: 'include-jokers-switch',
  ),
];

ToolModuleContext _testModuleContext() => ToolModuleContext(
  randomSource: SequenceRandomSource(List<int>.filled(256, 0)),
  feedbackService: const NoopFeedbackService(),
  reduceMotion: true,
  feedbackEnabled: false,
);

final class _FixedSessionIdSource implements SessionIdSource {
  _FixedSessionIdSource(this._prefix);

  final String _prefix;
  var _counter = 0;

  @override
  String next() => '$_prefix-${_counter++}';
}
