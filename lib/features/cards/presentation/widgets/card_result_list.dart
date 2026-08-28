import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/app_tokens.dart';
import '../../../../design_system/components/app_physical_deck.dart';
import '../../../../design_system/components/app_surfaces.dart';
import '../../domain/card_models.dart';
import '../card_labels.dart';
import 'playing_card_view.dart';

final class CardResultList extends StatelessWidget {
  const CardResultList({
    required this.deck,
    required this.cards,
    this.remainingCount,
    this.reveal = false,
    this.reducedMotion = false,
    this.settle = false,
    this.animateIndex,
    super.key,
  });

  final Widget deck;
  final List<PlayingCard> cards;
  final int? remainingCount;
  final bool reveal;
  final bool reducedMotion;
  final bool settle;
  final int? animateIndex;

  @override
  Widget build(BuildContext context) {
    final shouldAnimate =
        animateIndex != null && (reveal || settle) && !reducedMotion;
    if (!shouldAnimate) return _buildFrame(context, 1);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: context.appMotion.reveal,
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => _buildFrame(context, progress),
    );
  }

  Widget _buildFrame(BuildContext context, double progress) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (remainingCount != null) ...<Widget>[
        AppRevealDetailsSlot(
          visible: !reveal || reducedMotion,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.appColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadii.medium),
              border: Border.all(color: context.appColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _CardOutcomeMetric(
                      label: '已抽取',
                      value: '${cards.length} 张',
                    ),
                  ),
                  Expanded(
                    child: _CardOutcomeMetric(
                      label: '剩余',
                      value: '$remainingCount 张',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
      AppDeckResultFlow(
        deck: deck,
        cards: cards.indexed
            .map(
              (entry) => _buildCard(
                context,
                entry.$1,
                entry.$2,
                entry.$1 == animateIndex ? progress : 1,
              ),
            )
            .toList(growable: false),
      ),
    ],
  );

  Widget _buildCard(
    BuildContext context,
    int index,
    PlayingCard card,
    double progress,
  ) {
    final scale =
        AppMotionValues.cardRevealInitialScale +
        (1 - AppMotionValues.cardRevealInitialScale) * progress;
    final angle =
        (index.isEven ? 1 : -1) *
        AppMotionValues.cardRevealRotationDegrees *
        (1 - progress) *
        math.pi /
        180;
    return Opacity(
      key: ValueKey<String>('card-result-${card.id}'),
      opacity: progress,
      child: Transform.translate(
        offset: Offset(AppSizes.cardRevealTravel * (1 - progress), 0),
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: scale,
            child: Semantics(
              container: true,
              label: animateIndex == index && reveal
                  ? '第${index + 1}张扑克牌正在揭示'
                  : '第${index + 1}张，${playingCardLabel(card)}',
              child: SizedBox(
                width: AppSizes.playingCardWidth + AppSpacing.xl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '#${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    PlayingCardView(card: card, sequence: index + 1),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      playingCardLabel(card),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _CardOutcomeMetric extends StatelessWidget {
  const _CardOutcomeMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label $value',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: context.appColors.textSecondary),
        ),
      ],
    ),
  );
}
