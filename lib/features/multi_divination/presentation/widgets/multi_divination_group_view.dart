import 'package:flutter/material.dart';

import '../../../../design_system/app_tokens.dart';
import '../../../../design_system/components/app_physical_action.dart';
import '../../domain/multi_divination_models.dart';
import '../../../tarot/domain/tarot_models.dart';
import '../../../tarot/presentation/tarot_labels.dart';
import '../../../tarot/presentation/widgets/tarot_card_primitive.dart';

/// Renders one physical A/B/C group. Each card can open its own Tarot meaning;
/// only A remains part of the standard Liuyao interpretation.
final class MultiDivinationGroupCardsView extends StatelessWidget {
  const MultiDivinationGroupCardsView({
    required this.group,
    this.onCardTap,
    this.animate = false,
    this.compact = false,
    super.key,
  });

  final MultiDivinationGroup group;
  final ValueChanged<MultiDivinationCard>? onCardTap;
  final bool animate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cards = group.cards
        .map((card) => _buildCard(context, card, animate: animate))
        .toList(growable: false);
    return SizedBox(
      width: double.infinity,
      height: compact
          ? AppSizes.tarotRevealSlotHeight * 0.72
          : AppSizes.tarotRevealSlotHeight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (var index = 0; index < cards.length; index++) ...<Widget>[
              if (index > 0) const SizedBox(width: AppSpacing.sm),
              cards[index],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    MultiDivinationCard card, {
    required bool animate,
  }) {
    final drawnCard = TarotDrawnCard(
      card: card.card,
      position: TarotPosition.coreMessage,
      orientation: card.orientation,
    );
    final keySuffix = '${group.index}-${card.slot.code}';
    final primitive = TarotCardPrimitive(
      key: Key('multi-divination-card-$keySuffix'),
      drawnCard: drawnCard,
      animate: animate,
    );
    final cardLabel = animate
        ? '${card.slot.code}牌正在翻面，动画完成后显示牌面'
        : '${card.slot.code}牌，${card.card.name}，'
              '${tarotOrientationLabel(card.orientation)}';
    final canTap = !animate && onCardTap != null;
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '${card.slot.code}牌',
          style: Theme.of(context).textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppPhysicalAction(
          key: Key('multi-divination-card-action-$keySuffix'),
          label: canTap ? '$cardLabel，点击查看释义' : cardLabel,
          hint: canTap ? '点击查看 ${card.slot.code} 牌释义' : null,
          onTap: canTap ? () => onCardTap!(card) : null,
          child: primitive,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          card.slot == MultiDivinationCardSlot.a ? '标准解释' : '辅助解释',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: context.appColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
    return SizedBox(
      width: AppSizes.tarotCardWidth + AppSpacing.lg,
      child: body,
    );
  }
}
