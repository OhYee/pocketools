import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/app_tokens.dart';
import '../../../../design_system/components/app_physical_action.dart';
import '../../../../design_system/components/app_physical_deck.dart';
import '../../../../design_system/components/app_surfaces.dart';
import '../../content/tarot_content_catalog.dart';
import '../../content/tarot_content_models.dart';
import '../../domain/tarot_models.dart';
import '../tarot_labels.dart';
import 'tarot_card_primitive.dart';

final class TarotResultView extends StatelessWidget {
  const TarotResultView({
    required this.result,
    required this.revealedCount,
    required this.animateAll,
    required this.reducedMotion,
    required this.settle,
    this.showSupplementalContent = true,
    this.onRevealNext,
    this.onDeckTap,
    this.onCardTap,
    this.animateIndex,
    this.deckFocusNode,
    super.key,
  });

  final TarotReadingResult result;
  final int revealedCount;
  final bool animateAll;
  final bool reducedMotion;
  final bool settle;
  final bool showSupplementalContent;
  final VoidCallback? onRevealNext;
  final VoidCallback? onDeckTap;
  final ValueChanged<int>? onCardTap;
  final int? animateIndex;
  final FocusNode? deckFocusNode;

  @override
  Widget build(BuildContext context) {
    final composer = const TarotInterpretationComposer();
    final cards = result.cards.indexed
        .map((entry) {
          final index = entry.$1;
          final drawn = entry.$2;
          final revealed = index < revealedCount;
          final canReveal =
              result.config.revealMode == TarotRevealMode.sequential &&
              index == revealedCount &&
              onRevealNext != null;
          if (!revealed && !animateAll) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  tarotPositionLabel(drawn.position),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                TarotCardBack(
                  onReveal: canReveal ? onRevealNext : null,
                  semanticLabel: canReveal
                      ? '揭示${tarotPositionLabel(drawn.position)}位置的牌，'
                            '第 ${index + 1} 张，共 ${result.cards.length} 张'
                      : '${tarotPositionLabel(drawn.position)}位置的牌，'
                            '请先按顺序揭示前一张',
                ),
              ],
            );
          }
          final interpretation = composer.resolve(drawn);
          final animate =
              !reducedMotion &&
              revealed &&
              (animateIndex == index ||
                  (animateIndex == null &&
                      result.config.revealMode == TarotRevealMode.sequential &&
                      index == revealedCount - 1));
          final delayedReveal = animateAll && animateIndex == null;
          return _TarotOutcomeCard(
            key: Key('tarot-drawn-card-$index'),
            interpretationIndex: index,
            interpretation: interpretation,
            animate: animate,
            delayedReveal: delayedReveal,
            revealOrder: index,
            showDetails: !animate && !delayedReveal,
            canOpenDetails: revealed && !delayedReveal,
            onTap: onCardTap == null ? null : () => onCardTap!(index),
          );
        })
        .toList(growable: false);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppDeckResultFlow(
          deck: AppPhysicalDeck(
            key: const Key('tarot-deck'),
            label: onDeckTap == null ? '塔罗牌堆，当前不可操作' : '塔罗牌堆，点击抽一张牌',
            hint: '点击抽一张牌',
            onTap: onDeckTap,
            focusNode: deckFocusNode,
            child: const TarotDeckStack(),
          ),
          cards: cards,
        ),
        if (showSupplementalContent &&
            revealedCount == result.cards.length) ...<Widget>[
          if (composer.combinationHint(result) case final hint?) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            AppSectionCard(title: '组合提示', child: Text(hint)),
          ],
        ],
      ],
    );
    if (settle) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: AppMotionValues.completeInitialScale,
          end: 1,
        ),
        duration: context.appMotion.complete,
        builder: (context, value, child) =>
            Transform.scale(scale: value, child: child),
        child: content,
      );
    }
    if (reducedMotion) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: AppSpacing.zero, end: 1),
        duration: context.appMotion.reduced,
        curve: Curves.linear,
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child),
        child: content,
      );
    }
    return content;
  }
}

final class _TarotOutcomeCard extends StatelessWidget {
  const _TarotOutcomeCard({
    required this.interpretationIndex,
    required this.interpretation,
    required this.animate,
    required this.delayedReveal,
    required this.revealOrder,
    required this.showDetails,
    required this.canOpenDetails,
    this.onTap,
    super.key,
  });

  final int interpretationIndex;
  final TarotCardInterpretation interpretation;
  final bool animate;
  final bool delayedReveal;
  final int revealOrder;
  final bool showDetails;
  final bool canOpenDetails;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: showDetails
        ? '${tarotPositionLabel(interpretation.drawnCard.position)}位置，'
              '${interpretation.drawnCard.card.name}，'
              '${tarotOrientationLabel(interpretation.drawnCard.orientation)}，'
              '点击查看释义'
        : canOpenDetails
        ? '${tarotPositionLabel(interpretation.drawnCard.position)}位置，'
              '${interpretation.drawnCard.card.name}正在翻面，点击查看释义'
        : '${tarotPositionLabel(interpretation.drawnCard.position)}位置的塔罗牌正在翻面，'
              '动画完成后可查看释义',
    child: SizedBox(
      width: AppSizes.tarotCardWidth + AppSpacing.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: AppPhysicalAction(
              key: Key('tarot-card-action-$interpretationIndex'),
              label: showDetails
                  ? '${interpretation.drawnCard.card.name}，点击查看释义'
                  : canOpenDetails
                  ? '${interpretation.drawnCard.card.name}正在翻面，点击查看释义'
                  : '塔罗牌正在翻面，请等待动画完成',
              hint: canOpenDetails ? '点击查看释义' : '等待动画完成',
              onTap: canOpenDetails ? onTap : null,
              child: delayedReveal
                  ? _DelayedTarotReveal(
                      drawnCard: interpretation.drawnCard,
                      revealOrder: revealOrder,
                    )
                  : TarotCardPrimitive(
                      drawnCard: interpretation.drawnCard,
                      animate: animate,
                    ),
            ),
          ),
          AppRevealDetailsSlot(
            visible: showDetails,
            child: Column(
              children: <Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${tarotPositionLabel(interpretation.drawnCard.position)} · '
                  '${interpretation.drawnCard.card.name} · '
                  '${tarotOrientationLabel(interpretation.drawnCard.orientation)}',
                  style: Theme.of(context).textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
                Text(
                  '点击牌面查看释义',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: context.appColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

final class TarotInterpretationSheet extends StatelessWidget {
  const TarotInterpretationSheet({
    required this.interpretationIndex,
    required this.interpretation,
    required this.useReversals,
    super.key,
  });

  final int interpretationIndex;
  final TarotCardInterpretation interpretation;
  final bool useReversals;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: KeyedSubtree(
        key: Key('tarot-interpretation-sheet-$interpretationIndex'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '${interpretation.drawnCard.card.name} · '
              '${tarotOrientationLabel(interpretation.drawnCard.orientation)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            KeyedSubtree(
              key: Key('tarot-interpretation-$interpretationIndex'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('关键词：${interpretation.keywords.join('、')}'),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '传统牌义（Rider–Waite–Smith 体系）',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(interpretation.traditionalSymbols.join('；')),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    useReversals ? '常见解读（正位／逆位）' : '常见解读',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    useReversals
                        ? '正位：${interpretation.uprightMeaning}\n'
                              '逆位：${interpretation.reversedMeaning}\n'
                              '本次方向：${interpretation.currentDirectionMeaning}'
                        : '本次关闭逆位，未请求方向随机值；仅显示正位解释：'
                              '${interpretation.currentDirectionMeaning}',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '当前位置解释',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(interpretation.positionMeaning),
                  const SizedBox(height: AppSpacing.lg),
                  Text('反思问题', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  for (final question in interpretation.reflectionQuestions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text('· $question'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _DelayedTarotReveal extends StatefulWidget {
  const _DelayedTarotReveal({
    required this.drawnCard,
    required this.revealOrder,
  });

  final TarotDrawnCard drawnCard;
  final int revealOrder;

  @override
  State<_DelayedTarotReveal> createState() => _DelayedTarotRevealState();
}

final class _DelayedTarotRevealState extends State<_DelayedTarotReveal> {
  var _started = false;
  var _scheduled = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    _timer = Timer(context.appMotion.tarotStagger * widget.revealOrder, () {
      if (mounted) setState(() => _started = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _started
      ? TarotCardPrimitive(drawnCard: widget.drawnCard, animate: true)
      : const TarotCardBack();
}
