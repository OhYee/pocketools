import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../assets/runtime/runtime_asset_manifest.dart';
import '../../../../design_system/app_tokens.dart';
import '../../../../design_system/components/app_physics_motion.dart';
import '../../../../design_system/components/app_runtime_asset.dart';
import '../../domain/tarot_models.dart';
import '../tarot_labels.dart';

final class TarotCardPrimitive extends StatelessWidget {
  const TarotCardPrimitive({
    required this.drawnCard,
    this.animate = false,
    this.assetBuilder,
    super.key,
  });

  final TarotDrawnCard drawnCard;
  final bool animate;
  final RuntimeAssetBuilder? assetBuilder;

  @override
  Widget build(BuildContext context) {
    if (!animate) return _TarotCardRevealSlot(child: _front(context));
    return AppPhysicsMotion(
      key: const Key('tarot-draw-flip-motion'),
      duration: context.appMotion.tarotCard,
      builder: (context, progress, child) {
        final showingFront = progress >= AppMotionValues.tarotFlipProgress;
        final localProgress = showingFront
            ? ((progress - AppMotionValues.tarotFlipProgress) * 2).clamp(
                0.0,
                1.0,
              )
            : (progress * 2).clamp(0.0, 1.0);
        final angle =
            math.pi / 2 * (showingFront ? 1 - localProgress : localProgress);
        final transform = Matrix4.identity()
          ..setEntry(3, 2, AppMotionValues.tarotPerspective)
          ..rotateY(angle);
        final face = showingFront
            ? _front(context)
            : TarotCardBack(assetBuilder: assetBuilder);
        return _TarotCardRevealSlot(
          child: Transform.translate(
            offset: Offset(0, AppPhysics.tarotLanding(progress)),
            child: Transform.scale(
              scale:
                  AppMotionValues.tarotRevealInitialScale +
                  (1 - AppMotionValues.tarotRevealInitialScale) * progress,
              child: Transform(
                alignment: Alignment.center,
                transform: transform,
                child: face,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _front(BuildContext context) {
    final orientation = drawnCard.orientation == TarotOrientation.reversed
        ? RuntimeAssetOrientation.reversed
        : RuntimeAssetOrientation.upright;
    final semanticsLabel =
        '${tarotPositionLabel(drawnCard.position)}位置，${drawnCard.card.name}，'
        '${tarotOrientationLabel(drawnCard.orientation)}，经典 Rider–Waite–Smith 牌面';
    final artwork = _TarotFallbackArtwork(drawnCard: drawnCard);
    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: AppSizes.tarotCardWidth,
              height: AppSizes.tarotCardHeight,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.appColors.tarotSurface,
                borderRadius: BorderRadius.circular(AppRadii.large),
                border: Border.all(color: context.appColors.tarot),
              ),
              child: Transform.rotate(
                angle: drawnCard.orientation == TarotOrientation.reversed
                    ? math.pi
                    : AppSpacing.zero,
                child: RuntimeAssetSlot(
                  asset: RuntimeAssetManifest.tarotFace(
                    cardId: drawnCard.card.id,
                    orientation: orientation,
                    semanticLabel: semanticsLabel,
                  ),
                  fallback: artwork,
                  assetBuilder: assetBuilder,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.appColors.tarotSurface,
                borderRadius: BorderRadius.circular(AppRadii.full),
                border: Border.all(color: context.appColors.tarot),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(tarotOrientationLabel(drawnCard.orientation)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class TarotCardBack extends StatelessWidget {
  const TarotCardBack({
    this.onReveal,
    this.semanticLabel,
    this.assetBuilder,
    this.reserveRevealSlot = true,
    super.key,
  });

  final VoidCallback? onReveal;
  final String? semanticLabel;
  final RuntimeAssetBuilder? assetBuilder;
  final bool reserveRevealSlot;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: AppSizes.tarotCardWidth,
      height: AppSizes.tarotCardHeight,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appColors.surfaceInset,
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(color: context.appColors.borderStrong),
      ),
      child: RuntimeAssetSlot(
        asset: RuntimeAssetManifest.tarotBack(
          semanticLabel: semanticLabel ?? '塔罗牌背',
        ),
        fallback: const _TarotBackArtwork(),
        assetBuilder: assetBuilder,
      ),
    );
    if (onReveal == null) {
      final back = Semantics(
        label: semanticLabel ?? '塔罗牌背，尚未揭示',
        enabled: false,
        child: ExcludeSemantics(child: card),
      );
      return reserveRevealSlot ? _TarotCardRevealSlot(child: back) : back;
    }
    final back = Semantics(
      button: true,
      enabled: true,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.large),
          onTap: onReveal,
          child: ExcludeSemantics(child: card),
        ),
      ),
    );
    return reserveRevealSlot ? _TarotCardRevealSlot(child: back) : back;
  }
}

final class TarotCardBackStack extends StatelessWidget {
  const TarotCardBackStack({required this.count, this.assetBuilder, super.key});

  final int count;
  final RuntimeAssetBuilder? assetBuilder;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$count 张塔罗牌结果已冻结，身份和尚未揭示的方向保持隐藏',
    child: ExcludeSemantics(
      child: SizedBox(
        width: AppSizes.tarotCardWidth + AppSizes.cardStackOffset * (count - 1),
        height:
            AppSizes.tarotCardHeight + AppSizes.cardStackOffset * (count - 1),
        child: Stack(
          children: <Widget>[
            for (var index = count - 1; index >= 0; index--)
              Positioned(
                left: AppSizes.cardStackOffset * index,
                top: AppSizes.cardStackOffset * index,
                child: TarotCardBack(
                  assetBuilder: assetBuilder,
                  reserveRevealSlot: false,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// The first-run tarot entity: a visibly deep, physical deck that remains in
/// place after each draw so the next card always has one obvious entry point.
final class TarotDeckStack extends StatelessWidget {
  const TarotDeckStack({this.depth = 7, this.assetBuilder, super.key});

  final int depth;
  final RuntimeAssetBuilder? assetBuilder;

  @override
  Widget build(BuildContext context) {
    final safeDepth = depth.clamp(1, 12).toInt();
    return SizedBox(
      width:
          AppSizes.tarotCardWidth + AppSizes.cardStackOffset * (safeDepth - 1),
      height:
          AppSizes.tarotCardHeight + AppSizes.cardStackOffset * (safeDepth - 1),
      child: Stack(
        children: <Widget>[
          for (var index = safeDepth - 1; index >= 0; index--)
            Positioned(
              left: AppSizes.cardStackOffset * index,
              top: AppSizes.cardStackOffset * index,
              child: TarotCardBack(
                assetBuilder: assetBuilder,
                reserveRevealSlot: false,
              ),
            ),
        ],
      ),
    );
  }
}

final class _TarotCardRevealSlot extends StatelessWidget {
  const _TarotCardRevealSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipRect(
      child: SizedBox(
        width: AppSizes.tarotCardWidth,
        height: AppSizes.tarotRevealSlotHeight,
        child: Align(alignment: Alignment.center, child: child),
      ),
    ),
  );
}

final class _TarotFallbackArtwork extends StatelessWidget {
  const _TarotFallbackArtwork({required this.drawnCard});

  final TarotDrawnCard drawnCard;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          drawnCard.card.name,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: context.appColors.tarot,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        height: AppSizes.tarotSymbolSize * 1.6,
        child: const _AbstractTarotGeometry(),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        drawnCard.card.id,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: context.appColors.textSecondary),
      ),
    ],
  );
}

final class _TarotBackArtwork extends StatelessWidget {
  const _TarotBackArtwork();

  @override
  Widget build(BuildContext context) =>
      const _AbstractTarotGeometry(muted: true);
}

final class _AbstractTarotGeometry extends StatelessWidget {
  const _AbstractTarotGeometry({this.muted = false});

  final bool muted;

  @override
  Widget build(BuildContext context) {
    final primary = muted
        ? context.appColors.borderStrong
        : context.appColors.tarot;
    final accent = muted
        ? context.appColors.border
        : context.appColors.tarotAccent;
    return Column(
      children: <Widget>[
        Container(height: AppSpacing.xs, color: primary),
        const Spacer(),
        Center(
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: AppSizes.tarotSymbolSize,
              height: AppSizes.tarotSymbolSize,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(AppRadii.small),
                border: Border.all(color: primary),
              ),
            ),
          ),
        ),
        const Spacer(),
        Row(
          children: <Widget>[
            Expanded(
              child: Container(height: AppSpacing.xs, color: accent),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Container(height: AppSpacing.xs, color: primary),
            ),
          ],
        ),
      ],
    );
  }
}
