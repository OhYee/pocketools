import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final contract in _layoutContracts) {
    test(
      '${contract.name} simplified page keeps the core-first action shell contract',
      () {
        final source = File(contract.pagePath).readAsStringSync();
        final physicalEntityAction = contract.mainButtonTokens.any(
          (token) => token.endsWith('-deck'),
        );
        final coreIndex = _firstIndex(source, contract.coreTokens);
        final mainIndex = _firstIndex(source, contract.mainButtonTokens);

        expect(source, contains('AppToolScaffold('));
        expect(coreIndex, greaterThanOrEqualTo(0), reason: 'core entity');
        expect(mainIndex, greaterThanOrEqualTo(0), reason: 'main action');
        if (coreIndex < mainIndex) {
          expect(
            coreIndex,
            lessThan(mainIndex),
            reason: 'The core entity must be built before the primary action.',
          );
        } else {
          expect(
            source,
            contains('AppPhysicalDeck'),
            reason: 'Physical deck interaction is owned by the core entity.',
          );
        }

        final mainButton = physicalEntityAction
            ? null
            : _appButtonBlockContaining(source, contract.mainButtonTokens);
        if (mainButton != null) {
          expect(
            mainButton,
            contains('semanticLabel:'),
            reason: 'The primary action needs an accessible semantic label.',
          );
        } else {
          expect(
            source,
            contains('onTap:'),
            reason: 'The physical entity needs an accessible tap action.',
          );
        }

        final resetButton = _appButtonBlocks(source).firstWhere(
          (block) =>
              RegExp(r"Key\('reset-", caseSensitive: false).hasMatch(block),
          orElse: () => '',
        );
        if (contract.resetRequired) {
          expect(
            resetButton,
            isNotEmpty,
            reason: 'A reset action must sit beside the main action.',
          );
          expect(
            resetButton,
            contains('semanticLabel:'),
            reason: 'The reset action needs an accessible semantic label.',
          );

          final resetIndex = source.indexOf(resetButton);
          expect(resetIndex, greaterThanOrEqualTo(0));
          final actionStart =
              (mainIndex < resetIndex ? mainIndex : resetIndex) - 600;
          final actionEnd =
              (mainIndex > resetIndex ? mainIndex : resetIndex) + 500;
          final actionWindow = source.substring(
            actionStart < 0 ? 0 : actionStart,
            actionEnd > source.length ? source.length : actionEnd,
          );
          if (mainButton != null) {
            expect(
              actionWindow,
              contains('Row('),
              reason: 'Main and reset actions should be adjacent in one action row.',
            );
          } else {
            expect(source, contains('Align('));
          }
        } else {
          expect(
            resetButton,
            isEmpty,
            reason: 'One-shot tools reset as part of their primary action.',
          );
        }

        final advancedIndex = source.indexOf('高级选项');
        expect(advancedIndex, greaterThanOrEqualTo(0));
        final advancedTileIndex = source.lastIndexOf(
          'ExpansionTile(',
          advancedIndex,
        );
        expect(advancedTileIndex, greaterThanOrEqualTo(0));
        final nextTileIndex = source.indexOf(
          'ExpansionTile(',
          advancedTileIndex + 'ExpansionTile('.length,
        );
        final advancedWindow = source.substring(
          advancedTileIndex,
          nextTileIndex < 0 ? source.length : nextTileIndex,
        );
        expect(
          advancedWindow,
          contains('initiallyExpanded: false'),
          reason: 'Advanced options must be collapsed on first render.',
        );

        final resultIndex = _firstIndex(source, contract.resultTokens);
        expect(
          resultIndex,
          greaterThanOrEqualTo(coreIndex),
          reason: 'The result must be owned by the top entity stage.',
        );
        if (!physicalEntityAction) {
          expect(
            resultIndex,
            lessThan(mainIndex),
            reason: 'The result must be rendered before the primary action.',
          );
        }
      },
    );
  }
}

final class _LayoutContract {
  const _LayoutContract({
    required this.name,
    required this.pagePath,
    required this.coreTokens,
    required this.mainButtonTokens,
    required this.resultTokens,
    required this.resetRequired,
  });

  final String name;
  final String pagePath;
  final List<String> coreTokens;
  final List<String> mainButtonTokens;
  final List<String> resultTokens;
  final bool resetRequired;
}

const _layoutContracts = <_LayoutContract>[
  _LayoutContract(
    name: 'tarot',
    pagePath: 'lib/features/tarot/presentation/tarot_tool_page.dart',
    coreTokens: <String>[
      'tarot-core-entity',
      'TarotDeckStack',
      'TarotCardPrimitive',
    ],
    mainButtonTokens: <String>['tarot-deck'],
    resultTokens: <String>['TarotResultView'],
    resetRequired: true,
  ),
  _LayoutContract(
    name: 'liuyao',
    pagePath: 'lib/features/liuyao/presentation/liuyao_tool_page.dart',
    coreTokens: <String>[
      'liuyao-core-entity',
      'LiuyaoHexagramPrimitive',
      'LiuyaoCoinTossView',
      'LiuyaoDraftLinesView',
    ],
    mainButtonTokens: <String>[
      'cast-next-liuyao-line-button',
      'confirm-liuyao-line-button',
    ],
    resultTokens: <String>['LiuyaoReadingView'],
    resetRequired: true,
  ),
  _LayoutContract(
    name: 'dice',
    pagePath: 'lib/features/dice/presentation/dice_tool_page.dart',
    coreTokens: <String>['dice-core-entity', 'D20RollPrimitive'],
    mainButtonTokens: <String>['roll-button'],
    resultTokens: <String>['D20RollPrimitive'],
    resetRequired: false,
  ),
  _LayoutContract(
    name: 'coin',
    pagePath: 'lib/features/coin/presentation/coin_tool_page.dart',
    coreTokens: <String>[
      'coin-core-entity',
      'CoinPlaceholder',
      'CoinPrimitive',
      'CoinResultView',
    ],
    mainButtonTokens: <String>['toss-coin-button'],
    resultTokens: <String>['CoinResultView'],
    resetRequired: false,
  ),
  _LayoutContract(
    name: 'cards',
    pagePath: 'lib/features/cards/presentation/card_tool_page.dart',
    coreTokens: <String>[
      'cards-core-entity',
      'CardBackStack',
      'PlayingCardView',
    ],
    mainButtonTokens: <String>['cards-deck'],
    resultTokens: <String>['CardResultList'],
    resetRequired: true,
  ),
  _LayoutContract(
    name: 'multi-divination',
    pagePath: 'lib/features/multi_divination/presentation/multi_divination_tool_page.dart',
    coreTokens: <String>[
      'multi-divination-core-entity',
      'TarotDeckStack',
      'MultiDivinationGroupCardsView',
    ],
    mainButtonTokens: <String>['multi-divination-deck'],
    resultTokens: <String>['MultiDivinationResultView'],
    resetRequired: true,
  ),
];

int _firstIndex(String source, Iterable<String> tokens) {
  var result = -1;
  for (final token in tokens) {
    final index = source.indexOf(token);
    if (index >= 0 && (result < 0 || index < result)) result = index;
  }
  return result;
}

String? _appButtonBlockContaining(String source, Iterable<String> tokens) {
  for (final block in _appButtonBlocks(source)) {
    if (tokens.any(block.contains)) return block;
  }
  return null;
}

Iterable<String> _appButtonBlocks(String source) sync* {
  var start = source.indexOf('AppButton(');
  while (start >= 0) {
    final next = source.indexOf('AppButton(', start + 'AppButton('.length);
    yield source.substring(start, next < 0 ? source.length : next);
    start = next;
  }
}
