import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../assets/runtime/runtime_asset_manifest.dart';
import '../../../../design_system/app_tokens.dart';
import '../../../../design_system/components/app_runtime_asset.dart';
import '../../domain/card_models.dart';
import '../card_labels.dart';

final class PlayingCardView extends StatelessWidget {
  const PlayingCardView({
    required this.card,
    required this.sequence,
    super.key,
  });

  final PlayingCard card;
  final int sequence;

  bool get _usesRedInk =>
      card.suit == CardSuit.hearts ||
      card.suit == CardSuit.diamonds ||
      card.joker == JokerKind.big;

  @override
  Widget build(BuildContext context) {
    final ink = _usesRedInk
        ? AppPhysicalColors.cardRed
        : AppPhysicalColors.cardInk;
    final label = playingCardLabel(card);
    return Semantics(
      label: '第$sequence张，$label',
      child: SizedBox(
        width: AppSizes.playingCardWidth,
        height: AppSizes.playingCardHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppPhysicalColors.cardPaper,
            borderRadius: BorderRadius.circular(AppRadii.medium),
            border: Border.all(color: AppPhysicalColors.cardBorder),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: context.appSurfaces.shadow,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  card.isJoker ? label : cardRankLabel(card.rank!),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: ink, fontWeight: FontWeight.w700),
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        card.isJoker
                            ? card.joker == JokerKind.small
                                  ? '☆'
                                  : '★'
                            : cardSuitSymbol(card.suit!),
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(color: ink),
                      ),
                    ),
                  ),
                ),
                if (!card.isJoker)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Transform.rotate(
                      angle: math.pi,
                      child: Text(
                        '${cardRankLabel(card.rank!)}\n${cardSuitSymbol(card.suit!)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ink,
                          height: 0.9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class CardBackStack extends StatelessWidget {
  const CardBackStack({this.animate = true, this.depth = 6, super.key});

  final bool animate;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final safeDepth = depth.clamp(1, 12).toInt();
    final child = SizedBox(
      width:
          AppSizes.playingCardWidth +
          AppSizes.cardStackOffset * (safeDepth - 1),
      height:
          AppSizes.playingCardHeight +
          AppSizes.cardStackOffset * (safeDepth - 1),
      child: Stack(
        children: <Widget>[
          for (var index = safeDepth - 1; index >= 0; index--)
            Positioned(
              left: AppSizes.cardStackOffset * index,
              top: AppSizes.cardStackOffset * index,
              child: _CardBack(key: ValueKey<int>(index)),
            ),
        ],
      ),
    );
    if (!animate) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: -1, end: 1),
      duration: context.appMotion.shuffle,
      curve: Curves.easeInOut,
      child: child,
      builder: (context, progress, stack) => Transform.translate(
        offset: Offset(progress * AppSizes.cardStackOffset, AppSpacing.zero),
        child: Transform.rotate(
          angle:
              progress *
              AppMotionValues.cardShuffleRotationDegrees *
              math.pi /
              180,
          child: stack,
        ),
      ),
    );
  }
}

final class _CardBack extends StatelessWidget {
  const _CardBack({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: AppSizes.playingCardWidth,
    height: AppSizes.playingCardHeight,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppPhysicalColors.cardPaper,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: AppPhysicalColors.cardBackBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: context.appSurfaces.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: RuntimeAssetSlot(
        key: const Key('playing-card-back-asset'),
        asset: RuntimeAssetManifest.playingCardBack(),
        fallback: CustomPaint(
          key: const Key('playing-card-back-pattern'),
          painter: _CardBackPainter(
            line: context.appColors.cardsSurface,
            accent: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    ),
  );
}

final class _CardBackPainter extends CustomPainter {
  const _CardBackPainter({required this.line, required this.accent});

  final Color line;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.shortestSide * 0.09;
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - inset * 2,
        size.height - inset * 2,
      ),
      Radius.circular(size.shortestSide * 0.07),
    );
    final framePaint = Paint()
      ..color = line.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(frame, framePaint);

    final latticePaint = Paint()
      ..color = line.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final rect = frame.outerRect.deflate(size.shortestSide * 0.035);
    const step = 14.0;
    for (var x = rect.left - rect.height; x < rect.right; x += step) {
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x + rect.height, rect.bottom),
        latticePaint,
      );
      canvas.drawLine(
        Offset(x, rect.bottom),
        Offset(x + rect.height, rect.top),
        latticePaint,
      );
    }

    final center = rect.center;
    final diamond = Path()
      ..moveTo(center.dx, center.dy - size.shortestSide * 0.16)
      ..lineTo(center.dx + size.shortestSide * 0.16, center.dy)
      ..lineTo(center.dx, center.dy + size.shortestSide * 0.16)
      ..lineTo(center.dx - size.shortestSide * 0.16, center.dy)
      ..close();
    canvas.drawPath(
      diamond,
      Paint()
        ..color = accent.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(_CardBackPainter oldDelegate) =>
      oldDelegate.line != line || oldDelegate.accent != accent;
}
