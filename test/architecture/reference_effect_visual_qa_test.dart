import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/design_system/app_tokens.dart';
import 'package:pocketools/design_system/components/app_generation_state_view.dart';

void main() {
  test(
    'shared colors and motion tokens match the accepted design token source',
    () {
      final tokens = _asMap(
        jsonDecode(File('docs/design/tokens.json').readAsStringSync()),
      );
      final colors = _asMap(tokens['colors']);
      final lightColors = _asMap(colors['light']);
      final darkColors = _asMap(colors['dark']);
      final lightTools = _asMap(lightColors['tools']);
      final darkTools = _asMap(darkColors['tools']);
      final lightTheme = AppSemanticColors.light;
      final darkTheme = AppSemanticColors.dark;
      final lightSurfaces = AppSurfaceTokens.light;
      final darkSurfaces = AppSurfaceTokens.dark;
      final mismatches = <String>[];

      void compare(String name, Color actual, Object? expected) {
        final expectedColor = _color(expected);
        if (actual != expectedColor) {
          mismatches.add(
            '$name: actual ${_hex(actual)}, expected ${_hex(expectedColor)}',
          );
        }
      }

      compare('light.canvas', lightSurfaces.canvas, lightColors['background']);
      compare('light.surface', lightSurfaces.surface, lightColors['surface']);
      compare(
        'light.surfaceRaised',
        lightSurfaces.surfaceRaised,
        lightColors['surfaceElevated'],
      );
      compare(
        'light.surfaceInset',
        lightSurfaces.surfaceInset,
        lightColors['surfaceInset'],
      );
      compare('dark.canvas', darkSurfaces.canvas, darkColors['background']);
      compare('dark.surface', darkSurfaces.surface, darkColors['surface']);
      compare(
        'dark.surfaceRaised',
        darkSurfaces.surfaceRaised,
        darkColors['surfaceElevated'],
      );
      compare(
        'dark.surfaceInset',
        darkSurfaces.surfaceInset,
        darkColors['surfaceInset'],
      );

      for (final theme
          in <
            ({
              String name,
              AppSemanticColors actual,
              Map<String, dynamic> source,
            })
          >[
            (name: 'light', actual: lightTheme, source: lightColors),
            (name: 'dark', actual: darkTheme, source: darkColors),
          ]) {
        compare(
          '${theme.name}.surfaceMuted',
          theme.actual.surfaceMuted,
          theme.source['surfaceMuted'],
        );
        compare(
          '${theme.name}.surfaceInset',
          theme.actual.surfaceInset,
          theme.source['surfaceInset'],
        );
        compare(
          '${theme.name}.border',
          theme.actual.border,
          theme.source['border'],
        );
        compare(
          '${theme.name}.borderStrong',
          theme.actual.borderStrong,
          theme.source['borderStrong'],
        );
        compare(
          '${theme.name}.textSecondary',
          theme.actual.textSecondary,
          theme.source['textSecondary'],
        );
        compare(
          '${theme.name}.success',
          theme.actual.success,
          theme.source['success'],
        );
        compare(
          '${theme.name}.successSurface',
          theme.actual.successSurface,
          theme.source['successSurface'],
        );
        compare(
          '${theme.name}.neutral',
          theme.actual.neutral,
          theme.source['brand'],
        );
      }

      final toolComparisons =
          <
            ({
              String name,
              AppSemanticColors actual,
              Map<String, dynamic> source,
            })
          >[
            (
              name: 'light.tarot',
              actual: lightTheme,
              source: _asMap(lightTools['tarot']),
            ),
            (
              name: 'light.liuyao',
              actual: lightTheme,
              source: _asMap(lightTools['liuyao']),
            ),
            (
              name: 'light.d20',
              actual: lightTheme,
              source: _asMap(lightTools['d20']),
            ),
            (
              name: 'light.coin',
              actual: lightTheme,
              source: _asMap(lightTools['coin']),
            ),
            (
              name: 'light.playingCards',
              actual: lightTheme,
              source: _asMap(lightTools['playingCards']),
            ),
            (
              name: 'dark.tarot',
              actual: darkTheme,
              source: _asMap(darkTools['tarot']),
            ),
            (
              name: 'dark.liuyao',
              actual: darkTheme,
              source: _asMap(darkTools['liuyao']),
            ),
            (
              name: 'dark.d20',
              actual: darkTheme,
              source: _asMap(darkTools['d20']),
            ),
            (
              name: 'dark.coin',
              actual: darkTheme,
              source: _asMap(darkTools['coin']),
            ),
            (
              name: 'dark.playingCards',
              actual: darkTheme,
              source: _asMap(darkTools['playingCards']),
            ),
          ];
      for (final comparison in toolComparisons) {
        final prefix = comparison.name;
        final actual = comparison.actual;
        final source = comparison.source;
        final tool = prefix.substring(prefix.indexOf('.') + 1);
        final accent = switch (tool) {
          'tarot' => actual.tarot,
          'liuyao' => actual.liuyao,
          'd20' => actual.d20,
          'coin' => actual.coin,
          'playingCards' => actual.cards,
          _ => actual.neutral,
        };
        final surface = switch (tool) {
          'tarot' => actual.tarotSurface,
          'liuyao' => actual.liuyaoSurface,
          'd20' => actual.d20Surface,
          'coin' => actual.coinSurface,
          'playingCards' => actual.cardsSurface,
          _ => actual.surfaceMuted,
        };
        compare('$prefix.primary', accent, source['primary']);
        compare('$prefix.surface', surface, source['surface']);
        if (tool == 'tarot') {
          compare('$prefix.accent', actual.tarotAccent, source['accent']);
        }
        final onAccent = switch (tool) {
          'tarot' => actual.tarotOnAccent,
          'liuyao' => actual.liuyaoOnAccent,
          'd20' => actual.d20OnAccent,
          'coin' => actual.coinOnAccent,
          'playingCards' => actual.cardsOnAccent,
          _ => actual.neutral,
        };
        compare('$prefix.onPrimary', onAccent, source['onPrimary']);
      }

      final motion = _asMap(tokens['motion']);
      final durations = _asMap(motion['duration']);
      final toolLimits = _asMap(motion['toolLimits']);
      final toolProfiles = _asMap(motion['toolProfiles']);
      final coinProfile = _asMap(toolProfiles['coin']);
      final cardsProfile = _asMap(toolProfiles['playingCards']);
      final standard = const AppMotionTokens.standard();
      final durationChecks = <String, int>{
        'press': standard.press.inMilliseconds,
        'reduced': standard.reduced.inMilliseconds,
        'base': standard.base.inMilliseconds,
        'complete': standard.complete.inMilliseconds,
        'generate': standard.generate.inMilliseconds,
        'reveal': standard.reveal.inMilliseconds,
        'tarotCard': standard.tarotCard.inMilliseconds,
        'tarotStagger': standard.tarotStagger.inMilliseconds,
        'tarotRitual': standard.tarotRitual.inMilliseconds,
        'coinGenerate': standard.coinGenerate.inMilliseconds,
        'coinReveal': standard.coinReveal.inMilliseconds,
        'shuffle': standard.shuffle.inMilliseconds,
        'revealStagger': standard.revealStagger.inMilliseconds,
      };
      for (final entry in durationChecks.entries) {
        final expected = switch (entry.key) {
          'tarotCard' => toolLimits['tarotCardDuration'],
          'tarotStagger' => toolLimits['tarotStagger'],
          'tarotRitual' => durations['ritual'],
          'coinGenerate' => coinProfile['generate'],
          'coinReveal' => coinProfile['reveal'],
          'shuffle' => cardsProfile['generate'],
          'revealStagger' => toolLimits['playingCardStagger'],
          _ => durations[entry.key],
        };
        if (expected is num && entry.value != expected) {
          mismatches.add(
            'motion.${entry.key}: actual ${entry.value}, expected $expected',
          );
        }
      }

      expect(
        mismatches,
        isEmpty,
        reason:
            'Shared visual tokens drifted from docs/design/tokens.json:\n'
            '${mismatches.join('\n')}',
      );
    },
  );

  test('all six tool pages use the shared visual flow and state contract', () {
    const pages = <String>[
      'tarot',
      'liuyao',
      'dice',
      'coin',
      'cards',
      'multi_divination',
    ];
    final violations = <String>[];
    for (final page in pages) {
      final fileName = switch (page) {
        'cards' => 'card',
        'multi_divination' => 'multi_divination',
        _ => page,
      };
      final path = 'lib/features/$page/presentation/${fileName}_tool_page.dart';
      final source = File(path).readAsStringSync();
      for (final sharedType in <String>[
        'AppToolTheme(',
        'AppToolFlowLayout(',
        'AppSectionCard(',
        'AppButton(',
        'AppEntityStateView(',
      ]) {
        if (!source.contains(sharedType)) {
          violations.add('$path is missing $sharedType');
        }
      }
      if (RegExp(r'\b(?:Filled|Outlined|Text|Elevated)Button\s*\(')
          .hasMatch(source)) {
        violations.add('$path bypasses AppButton with a raw Material button');
      }
      if (RegExp(r'\bColor\s*\(').hasMatch(source) ||
          RegExp(r'\bDuration\s*\(').hasMatch(source) ||
          RegExp(r'BorderRadius\.circular\s*\(\s*\d').hasMatch(source)) {
        violations.add('$path contains local visual constants');
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test(
    'multi-divination does not reserve a second hidden full-stage region',
    () {
      final source = File(
        'lib/features/multi_divination/presentation/multi_divination_tool_page.dart',
      ).readAsStringSync();

      expect(
        source,
        isNot(contains('height: AppSizes.entityStageSlotHeight,')),
      );
    },
  );

  test('shared flow and generation state keep their canonical ordering', () {
    final flow = File('lib/design_system/components/app_tool_flow_layout.dart')
        .readAsStringSync();
    final state = File(
      'lib/design_system/components/app_generation_state_view.dart',
    ).readAsStringSync();
    final violations = <String>[];

    final order = <String>[
      'this.coreEntity',
      'this.actionBar',
      'this.advancedOptions',
      'this.outcome',
    ];
    for (var index = 1; index < order.length; index++) {
      if (flow.indexOf(order[index - 1]) >= flow.indexOf(order[index])) {
        violations.add(
          'AppToolFlowLayout field order is not core/action/advanced/outcome',
        );
      }
    }
    for (final token in <String>[
      'AppEntityStage(child: coreEntity)',
      'AppSpacing.lg',
      'AppSpacing.xl',
    ]) {
      if (!flow.contains(token)) violations.add('flow is missing $token');
    }
    for (final phase in GenerationPhase.values) {
      if (!state.contains('GenerationPhase.${phase.name}')) {
        violations.add('state view is missing ${phase.name}');
      }
    }
    for (final token in <String>[
      'liveRegion: true',
      'context.appMotion',
      'disableAnimations',
      'AppRadii.full',
    ]) {
      if (!state.contains(token)) {
        violations.add('state view is missing $token');
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}

Map<String, dynamic> _asMap(Object? value) =>
    (value as Map).cast<String, dynamic>();

Color _color(Object? value) {
  final raw = (value as String).replaceFirst('#', '');
  final parsed = int.parse(raw, radix: 16);
  return Color(raw.length == 6 ? 0xFF000000 | parsed : parsed);
}

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
