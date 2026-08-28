import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../assets/runtime/runtime_asset_manifest.dart';
import '../../../../design_system/app_tokens.dart';
import '../../../../design_system/components/app_physics_motion.dart';
import '../../../../design_system/components/app_runtime_asset.dart';
import '../../domain/coin_models.dart';
import '../coin_labels.dart';

final class CoinPrimitive extends StatelessWidget {
  const CoinPrimitive({
    required this.side,
    required this.label,
    this.animate = false,
    this.compact = false,
    this.size,
    this.animationDuration,
    this.assetBuilder,
    super.key,
  });

  final CoinSide side;
  final String label;
  final bool animate;
  final bool compact;
  final double? size;
  final Duration? animationDuration;
  final RuntimeAssetBuilder? assetBuilder;

  @override
  Widget build(BuildContext context) {
    final face = _CoinFace(
      side: side,
      label: label,
      compact: compact,
      size: size,
      assetBuilder: assetBuilder,
    );
    if (!animate) return face;
    return AppPhysicsMotion(
      key: const Key('coin-motion-layer'),
      duration: animationDuration ?? context.appMotion.coinReveal,
      builder: (context, progress, child) {
        final rotation = AppPhysics.spin(
          progress,
          turns: AppMotionValues.coinRotationTurns,
        );
        final visibleSide = math.cos(rotation) >= 0 ? side : _opposite(side);
        final visibleLabel = visibleSide == side
            ? label
            : coinOriginalSideLabel(visibleSide);
        final transform = Matrix4.identity()
          ..setEntry(3, 2, AppMotionValues.coinPerspective)
          ..rotateX(rotation);
        final landing = AppPhysics.coinLanding(progress);
        final settleScale = AppPhysics.settleScale(progress, amount: 0.03);
        final edgeVisibility = math.sin(rotation).abs();
        final resolvedSize =
            size ??
            (compact ? AppSizes.coinSequenceSize : AppSizes.coinSingleSize);
        return SizedBox(
          width: resolvedSize,
          height: resolvedSize,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: resolvedSize * 0.12,
                right: resolvedSize * 0.12,
                bottom: resolvedSize * 0.02,
                child: _CoinShadow(
                  opacity: 0.12 + 0.08 * (1 - edgeVisibility),
                  scale:
                      0.72 +
                      0.28 *
                          (1 - landing.abs() / 52).clamp(0.0, 1.0).toDouble(),
                ),
              ),
              if (edgeVisibility > 0.02)
                Opacity(
                  opacity: edgeVisibility.clamp(0, 1),
                  child: Transform.translate(
                    offset: Offset(AppSpacing.zero, landing),
                    child: Transform.rotate(
                      // coin_edge.png is a portrait strip. The coin flips
                      // around the horizontal X axis, so its physical rim
                      // must be horizontal when the face reaches edge-on.
                      angle: math.pi / 2,
                      child: Transform.scale(
                        scale: settleScale,
                        child: RuntimeAssetSlot(
                          asset: RuntimeAssetManifest.coinEdge(
                            semanticLabel: '硬币侧面边缘',
                          ),
                          fallback: const SizedBox.expand(),
                          assetBuilder: assetBuilder,
                        ),
                      ),
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(AppSpacing.zero, landing),
                child: Transform.scale(
                  scale: settleScale,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: transform,
                    child: _CoinFace(
                      side: visibleSide,
                      label: visibleLabel,
                      compact: compact,
                      size: resolvedSize,
                      assetBuilder: assetBuilder,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  CoinSide _opposite(CoinSide value) =>
      value == CoinSide.heads ? CoinSide.tails : CoinSide.heads;
}

final class _CoinShadow extends StatelessWidget {
  const _CoinShadow({required this.opacity, required this.scale});

  final double opacity;
  final double scale;

  @override
  Widget build(BuildContext context) => Transform.scale(
    scaleX: scale,
    child: Opacity(
      opacity: opacity,
      child: Container(
        height: AppSpacing.sm,
        decoration: BoxDecoration(
          color: context.appColors.textSecondary,
          borderRadius: BorderRadius.circular(AppRadii.full),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: context.appColors.textSecondary.withAlpha(85),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    ),
  );
}

final class CoinPlaceholder extends StatelessWidget {
  const CoinPlaceholder({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final resolvedSize = compact
        ? AppSizes.coinSequenceSize
        : AppSizes.coinSingleSize;
    return Semantics(
      label: '待抛实体硬币',
      child: ExcludeSemantics(
        child: CoinPrimitive(
          side: CoinSide.heads,
          label: '待抛硬币',
          compact: compact,
          size: resolvedSize,
        ),
      ),
    );
  }
}

final class _CoinFace extends StatelessWidget {
  const _CoinFace({
    required this.side,
    required this.label,
    required this.compact,
    required this.size,
    required this.assetBuilder,
  });

  final CoinSide side;
  final String label;
  final bool compact;
  final double? size;
  final RuntimeAssetBuilder? assetBuilder;

  @override
  Widget build(BuildContext context) {
    final resolvedSize =
        size ?? (compact ? AppSizes.coinSequenceSize : AppSizes.coinSingleSize);
    final isHeads = side == CoinSide.heads;
    final semanticsLabel =
        '$label，原始面值 ${coinRawSideId(side)} ${coinOriginalSideLabel(side)}';
    final artwork = Container(
      width: resolvedSize,
      height: resolvedSize,
      decoration: BoxDecoration(
        color: isHeads
            ? Theme.of(context).colorScheme.primary
            : context.appColors.coinSurface,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      alignment: Alignment.center,
    );
    final labelArtwork = Text(
      compact ? (isHeads ? '正' : '反') : label,
      textAlign: TextAlign.center,
      maxLines: compact ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style:
          (compact
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.titleLarge)
              ?.copyWith(
                color: isHeads
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
    );
    final fallback = Stack(
      alignment: Alignment.center,
      children: <Widget>[artwork, labelArtwork],
    );
    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: resolvedSize,
          height: resolvedSize,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              RuntimeAssetSlot(
                asset: RuntimeAssetManifest.coinFace(
                  side: side.name,
                  semanticLabel: semanticsLabel,
                ),
                fallback: fallback,
                assetBuilder: assetBuilder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
