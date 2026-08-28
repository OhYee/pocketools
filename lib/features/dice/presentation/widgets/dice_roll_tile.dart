import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../assets/runtime/runtime_asset_manifest.dart';
import '../../../../design_system/app_tokens.dart';
import '../../../../design_system/components/app_physics_motion.dart';
import '../../../../design_system/components/app_runtime_asset.dart';
import '../../domain/dice_models.dart';

final class D20RollPrimitive extends StatelessWidget {
  const D20RollPrimitive({
    required this.value,
    this.diceSides = 20,
    this.animate = false,
    this.size = 52,
    this.showValue = true,
    this.assetBuilder,
    super.key,
  });

  final int value;
  final int diceSides;
  final bool animate;
  final double size;
  final bool showValue;
  final RuntimeAssetBuilder? assetBuilder;

  @override
  Widget build(BuildContext context) {
    final stopFace = _D20Face(
      value: value,
      diceSides: diceSides,
      size: size,
      showValue: showValue,
      assetBuilder: assetBuilder,
    );
    if (!animate) return stopFace;
    return Semantics(
      label: showValue ? 'D$diceSides 停在 $value 点' : '中性实体 D$diceSides',
      child: ExcludeSemantics(
        child: AppPhysicsMotion(
          key: const Key('d20-physics-motion'),
          duration: context.appMotion.reveal,
          builder: (context, progress, child) {
            final stopped = progress >= AppMotionValues.d20StopProgress;
            final displayed = stopped
                ? stopFace
                : _D20RollingFace(size: size, assetBuilder: assetBuilder);
            final rotation = _rotationAt(progress);
            final pitch = math.sin(rotation * 0.55) * 0.24;
            final yaw = math.cos(rotation * 0.7) * 0.16;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, AppMotionValues.d20Perspective)
              // The artwork is a real die sprite. Keep the silhouette visible
              // while rocking it in depth instead of rotating the flat image
              // edge-on and turning it into a paper-thin streak.
              ..rotateX(pitch)
              ..rotateY(yaw)
              ..rotateZ(rotation);
            return Transform.translate(
              offset: Offset(0, AppPhysics.d20Landing(progress)),
              child: Transform.scale(
                scale: AppPhysics.settleScale(progress, amount: 0.02),
                child: Transform(
                  alignment: Alignment.center,
                  transform: transform,
                  child: displayed,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _rotationAt(double progress) {
    final stop = AppMotionValues.d20StopProgress;
    if (progress <= stop) {
      return AppPhysics.spin(
        progress / stop,
        turns: AppMotionValues.d20RollTurns,
      );
    }
    final settle = 1 - ((progress - stop) / (1 - stop)).clamp(0.0, 1.0);
    return AppPhysics.spin(1, turns: AppMotionValues.d20RollTurns) * settle;
  }
}

final class _D20Face extends StatelessWidget {
  const _D20Face({
    required this.value,
    required this.diceSides,
    required this.size,
    required this.showValue,
    required this.assetBuilder,
  });

  final int value;
  final int diceSides;
  final double size;
  final bool showValue;
  final RuntimeAssetBuilder? assetBuilder;

  @override
  Widget build(BuildContext context) {
    final fallback = _D20FallbackFace(value: '');
    // There is no honest way to make a 1000-sided physical sprite legible.
    // Once the configured die is D20 or larger, use the same recognizable
    // physical die artwork and keep the actual rolled value as text.
    final useGenericArtwork = diceSides >= 20;
    final face = useGenericArtwork
        ? RuntimeAssetSlot(
            asset: RuntimeAssetManifest.d20Face(
              value: 20,
              semanticLabel: showValue
                  ? '实体 D$diceSides，结果 $value'
                  : '中性实体 D$diceSides',
            ),
            fallback: fallback,
            assetBuilder: assetBuilder,
          )
        : fallback;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: <Widget>[
          face,
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                showValue ? '$value' : 'D$diceSides',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.appColors.d20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _D20RollingFace extends StatelessWidget {
  const _D20RollingFace({required this.size, required this.assetBuilder});

  final double size;
  final RuntimeAssetBuilder? assetBuilder;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        RuntimeAssetSlot(
          asset: RuntimeAssetManifest.d20Face(
            value: 20,
            semanticLabel: '正在滚动的实体骰子',
          ),
          fallback: _D20FallbackFace(value: '实体骰子'),
          assetBuilder: assetBuilder,
        ),
        Center(
          child: Text(
            '骰子',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.appColors.d20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

final class _D20FallbackFace extends StatelessWidget {
  const _D20FallbackFace({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _D20Painter(
      fill: context.appColors.d20Surface,
      edge: context.appColors.d20,
    ),
    child: Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.appColors.d20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

final class _D20Painter extends CustomPainter {
  const _D20Painter({required this.fill, required this.edge});

  final Color fill;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final top = center.translate(0, -radius * 0.94);
    final left = center.translate(-radius * 0.86, radius * 0.48);
    final right = center.translate(radius * 0.86, radius * 0.48);
    final bottom = center.translate(0, radius * 0.94);
    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[fill, Color.lerp(fill, edge, 0.28)!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, fillPaint);
    final edgePaint = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, edgePaint);
    canvas.drawLine(top, center, edgePaint);
    canvas.drawLine(left, center, edgePaint);
    canvas.drawLine(right, center, edgePaint);
    canvas.drawLine(bottom, center, edgePaint);
  }

  @override
  bool shouldRepaint(_D20Painter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.edge != edge;
}

final class DiceRollTile extends StatelessWidget {
  const DiceRollTile({
    required this.roll,
    this.diceSides = 20,
    this.animate = false,
    this.assetBuilder,
    super.key,
  });

  final DiceRoll roll;
  final int diceSides;
  final bool animate;
  final RuntimeAssetBuilder? assetBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = roll.isKept ? colors.d20 : colors.textSecondary;
    final background = roll.isKept ? colors.d20Surface : colors.surfaceMuted;
    return Semantics(
      label: '第 ${roll.index} 枚，${roll.value} 点，${roll.isKept ? '保留' : '舍弃'}',
      child: AnimatedContainer(
        key: ValueKey<String>('dice-roll-${roll.index}'),
        duration: context.appMotion.base,
        constraints: const BoxConstraints(
          minWidth: AppSizes.minimumTapTarget * 1.5,
          minHeight: AppSizes.minimumTapTarget * 1.5,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.large),
          border: Border.all(color: roll.isKept ? colors.d20 : colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('#${roll.index}'),
            D20RollPrimitive(
              value: roll.value,
              diceSides: diceSides,
              animate: animate,
              assetBuilder: assetBuilder,
            ),
            Text(
              roll.isKept ? '保留' : '舍弃',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
