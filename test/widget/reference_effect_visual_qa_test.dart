import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_id_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/design_system/app_tokens.dart';
import 'package:pocketools/design_system/components/app_generation_state_view.dart';
import 'package:pocketools/design_system/components/app_surfaces.dart';
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
  test('light and dark themes install the complete shared extension set', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    for (final theme in <ThemeData>[light, dark]) {
      expect(theme.extension<AppMotionTokens>(), isNotNull);
      expect(theme.extension<AppSurfaceTokens>(), isNotNull);
      expect(theme.extension<AppSemanticColors>(), isNotNull);
      expect(theme.colorScheme.brightness, theme.brightness);
    }
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.scaffoldBackgroundColor, AppSurfaceTokens.light.canvas);
    expect(dark.scaffoldBackgroundColor, AppSurfaceTokens.dark.canvas);
  });

  test(
    'tool text colors keep WCAG AA contrast on the surfaces they actually use',
    () {
      final lightColors = AppSemanticColors.light;
      final darkColors = AppSemanticColors.dark;
      final lightSurface = AppSurfaceTokens.light.surface;
      final darkSurface = AppSurfaceTokens.dark.surface;
      final pairs = <({String name, Color foreground, Color background})>[
        (
          name: 'light playing-card ink',
          foreground: lightColors.cards,
          background: lightSurface,
        ),
        (
          name: 'dark playing-card ink',
          foreground: darkColors.cards,
          background: darkSurface,
        ),
        (
          name: 'light D20 ink',
          foreground: lightColors.d20,
          background: lightColors.d20Surface,
        ),
        (
          name: 'dark D20 ink',
          foreground: darkColors.d20,
          background: darkColors.d20Surface,
        ),
        (
          name: 'light tarot ink',
          foreground: lightColors.tarot,
          background: lightColors.tarotSurface,
        ),
        (
          name: 'dark tarot ink',
          foreground: darkColors.tarot,
          background: darkColors.tarotSurface,
        ),
        (
          name: 'light coin tails ink',
          foreground: lightColors.coin,
          background: lightColors.coinSurface,
        ),
        (
          name: 'dark coin tails ink',
          foreground: darkColors.coin,
          background: darkColors.coinSurface,
        ),
      ];
      final failures = <String>[];
      for (final pair in pairs) {
        final ratio = _contrastRatio(pair.foreground, pair.background);
        if (ratio < 4.5) {
          failures.add('${pair.name}: ${ratio.toStringAsFixed(2)}:1');
        }
      }
      expect(
        failures,
        isEmpty,
        reason:
            'Normal-size tool labels need at least 4.5:1 contrast:\n'
            '${failures.join('\n')}',
      );
    },
  );

  testWidgets('surface tones preserve depth and semantics in both themes', (
    tester,
  ) async {
    for (final themeCase in <({String name, ThemeData theme})>[
      (name: 'light', theme: AppTheme.light()),
      (name: 'dark', theme: AppTheme.dark()),
    ]) {
      for (final tone in AppSurfaceTone.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: themeCase.theme,
            home: Scaffold(
              body: AppSectionCard(
                key: ValueKey<String>('${themeCase.name}-${tone.name}'),
                tone: tone,
                semanticLabel: '${tone.name} surface',
                child: const Text('surface content'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final card = tester.widget<Card>(
          find.descendant(
            of: find.byType(AppSectionCard),
            matching: find.byType(Card),
          ),
        );
        final surfaces = themeCase.theme.extension<AppSurfaceTokens>()!;
        final expectedColor = tone == AppSurfaceTone.inset
            ? surfaces.surfaceInset
            : surfaces.surface;
        final expectedElevation = switch (tone) {
          AppSurfaceTone.entity => AppElevation.entity,
          AppSurfaceTone.result => AppElevation.result,
          _ => AppElevation.section,
        };
        expect(card.color, expectedColor, reason: '${themeCase.name}/$tone');
        expect(
          card.elevation,
          expectedElevation,
          reason: '${themeCase.name}/$tone',
        );
        expect(card.shadowColor, surfaces.shadow);
        expect(
          tester.getSemantics(find.byType(AppSectionCard)).label,
          '${tone.name} surface',
        );
      }
    }
  });

  testWidgets('generation states are announced and honor reduced motion', (
    tester,
  ) async {
    const labels = <GenerationPhase, String>{
      GenerationPhase.ready: '准备就绪',
      GenerationPhase.pressed: '设置已冻结',
      GenerationPhase.generating: '正在生成结果',
      GenerationPhase.revealing: '结果已生成，正在揭示',
      GenerationPhase.completed: '结果已完成',
      GenerationPhase.reduced: '减少动态：结果已生成',
    };

    for (final phase in GenerationPhase.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(body: AppGenerationStateView(phase: phase)),
        ),
      );
      await tester.pump();
      final state = find.byType(AppGenerationStateView);
      expect(find.text(labels[phase]!), findsOneWidget, reason: phase.name);
      expect(
        tester.getSemantics(state).label,
        labels[phase],
        reason: phase.name,
      );
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        container.duration,
        const AppMotionTokens.standard().base,
        reason: phase.name,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(body: AppGenerationStateView(phase: phase)),
          ),
        ),
      );
      await tester.pump();
      final reducedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        reducedContainer.duration,
        const AppMotionTokens.standard().reduced,
        reason: '${phase.name}/reduced',
      );
    }
  });

  for (final themeCase in <({String name, ThemeData theme})>[
    (name: 'light', theme: AppTheme.light()),
    (name: 'dark', theme: AppTheme.dark()),
  ]) {
    for (final page in _pages) {
      testWidgets(
        '${page.name} keeps the shared reference-effect shell in ${themeCase.name} mode',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: themeCase.theme,
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
          expect(find.byType(AppEntityStage), findsOneWidget);
          expect(find.byType(AppGenerationStateView), findsOneWidget);
          expect(
            tester.getTopLeft(core).dy,
            lessThan(tester.getTopLeft(main).dy),
            reason: '${page.name}: core must precede primary action',
          );
          if (page.resetKey != null) {
            expect(
              tester.getTopLeft(reset).dy,
              greaterThanOrEqualTo(tester.getTopLeft(main).dy),
              reason:
                  '${page.name}: reset must remain below the entity interaction',
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
          expect(find.byKey(Key(page.configKey)), findsNothing);

          final innerTheme = tester.widget<Theme>(find.byType(Theme).last);
          final semanticColors = themeCase.theme
              .extension<AppSemanticColors>()!;
          expect(
            innerTheme.data.colorScheme.primary,
            semanticColors.accentFor(page.accent),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final page in _pages) {
    testWidgets(
      '${page.name} primary action still enters a generated visual state',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: page.build(_testModuleContext()),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.ensureVisible(find.byKey(Key(page.mainKey)));
        await tester.tap(find.byKey(Key(page.mainKey)));
        await tester.pump(const Duration(milliseconds: 120));
        await tester.pump(const Duration(milliseconds: 120));

        expect(find.byType(AppGenerationStateView), findsOneWidget);
        expect(
          tester.getSemantics(find.byType(AppGenerationStateView)).label,
          isNot('准备就绪'),
          reason: '${page.name}: primary action must leave ready state',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

final class _PageCase {
  const _PageCase({
    required this.name,
    required this.accent,
    required this.build,
    required this.coreKey,
    required this.mainKey,
    required this.resetKey,
    required this.advancedKey,
    required this.configKey,
  });

  final String name;
  final ToolAccent accent;
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
    accent: ToolAccent.tarot,
    build: (context) {
      final module = TarotToolModule();
      return TarotToolPage(
        moduleContext: context,
        sessionRepository: InMemorySessionRepository(),
        sessionAdapter: module.toolSessionAdapter,
        sessionIdSource: _FixedSessionIdSource('reference-tarot'),
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
    accent: ToolAccent.liuyao,
    build: (context) {
      final module = LiuyaoToolModule();
      return LiuyaoToolPage(
        moduleContext: context,
        sessionRepository: InMemorySessionRepository(),
        sessionAdapter: module.toolSessionAdapter,
        sessionIdSource: _FixedSessionIdSource('reference-liuyao'),
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
    accent: ToolAccent.d20,
    build: (context) => DiceToolPage(moduleContext: context),
    coreKey: 'dice-core-entity',
    mainKey: 'roll-button',
    resetKey: null,
    advancedKey: 'dice-advanced-options',
    configKey: 'dice-count-stepper',
  ),
  _PageCase(
    name: 'coin',
    accent: ToolAccent.coin,
    build: (context) {
      final module = CoinToolModule();
      return CoinToolPage(
        moduleContext: context,
        sessionRepository: InMemorySessionRepository(),
        sessionAdapter: module.toolSessionAdapter,
        sessionIdSource: _FixedSessionIdSource('reference-coin'),
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
    accent: ToolAccent.cards,
    build: (context) {
      final module = CardToolModule();
      return CardToolPage(
        moduleContext: context,
        sessionRepository: InMemorySessionRepository(),
        sessionAdapter: module.toolSessionAdapter,
        sessionIdSource: _FixedSessionIdSource('reference-cards'),
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

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
