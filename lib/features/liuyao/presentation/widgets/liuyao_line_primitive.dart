import 'package:flutter/material.dart';

import '../../../../design_system/app_tokens.dart';
import '../../../../design_system/components/app_runtime_asset.dart';
import '../../../coin/domain/coin_models.dart';
import '../../../coin/presentation/widgets/coin_primitive.dart';
import '../../domain/liuyao_models.dart';
import '../liuyao_labels.dart';

final class LiuyaoLinePrimitive extends StatelessWidget {
  const LiuyaoLinePrimitive({
    required this.line,
    this.changed = false,
    this.animate = false,
    this.compact = false,
    super.key,
  });

  final LiuyaoLine line;
  final bool changed;
  final bool animate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final nature = changed ? line.changedNature : line.nature;
    final visual = Semantics(
      label: changed
          ? '${liuyaoLinePositionLabel(line.index)}变爻，${liuyaoNatureLabel(nature)}'
          : liuyaoLineSemanticLabel(line),
      child: ExcludeSemantics(
        child: CustomPaint(
          size: Size(
            compact
                ? AppSizes.liuyaoLineWidth * 0.72
                : AppSizes.liuyaoLineWidth,
            AppSizes.minimumTapTarget,
          ),
          painter: _LiuyaoLinePainter(
            nature: nature,
            color: context.appColors.liuyao,
          ),
        ),
      ),
    );
    if (!animate) return visual;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: AppSpacing.zero, end: 1),
      duration: context.appMotion.reveal,
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Transform.translate(
        offset: Offset(
          AppSpacing.zero,
          AppSizes.liuyaoLineLift * (1 - progress),
        ),
        child: Opacity(opacity: progress, child: child),
      ),
      child: visual,
    );
  }
}

final class _LiuyaoLinePainter extends CustomPainter {
  const _LiuyaoLinePainter({required this.nature, required this.color});

  final LiuyaoLineNature nature;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = AppSizes.liuyaoLineThickness
      ..strokeCap = StrokeCap.round;
    final centerY = size.height / 2;
    if (nature == LiuyaoLineNature.yang) {
      canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), paint);
      return;
    }
    final segmentWidth = (size.width - AppSizes.liuyaoYinGap) / 2;
    canvas.drawLine(Offset(0, centerY), Offset(segmentWidth, centerY), paint);
    canvas.drawLine(
      Offset(segmentWidth + AppSizes.liuyaoYinGap, centerY),
      Offset(size.width, centerY),
      paint,
    );
  }

  @override
  bool shouldRepaint(_LiuyaoLinePainter oldDelegate) =>
      oldDelegate.nature != nature || oldDelegate.color != color;
}

final class LiuyaoCoinTossView extends StatelessWidget {
  const LiuyaoCoinTossView({
    required this.coins,
    required this.animate,
    this.preview = false,
    this.assetBuilder,
    super.key,
  });

  final List<LiuyaoCoinSide> coins;
  final bool animate;
  final bool preview;
  final RuntimeAssetBuilder? assetBuilder;

  @override
  Widget build(BuildContext context) {
    final tokens = Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: coins
          .map((side) => _coin(context, side))
          .toList(growable: false),
    );
    return tokens;
  }

  Widget _coin(BuildContext context, LiuyaoCoinSide side) => Semantics(
    label: preview ? '待抛硬币' : '${liuyaoCoinLabel(side)}面，记 ${side.points} 点',
    child: ExcludeSemantics(
      child: CoinPrimitive(
        side: side == LiuyaoCoinSide.heads ? CoinSide.heads : CoinSide.tails,
        label: preview ? '待抛' : liuyaoCoinLabel(side),
        size: preview ? 76 : AppSizes.liuyaoCoinSize,
        animate: animate && !preview,
        animationDuration: context.appMotion.generate,
        assetBuilder: assetBuilder,
      ),
    ),
  );
}
