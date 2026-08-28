import 'package:flutter/material.dart';

import '../../../../design_system/app_tokens.dart';
import '../../../../design_system/components/app_physical_action.dart';
import '../../../../design_system/components/app_runtime_asset.dart';
import '../../../../design_system/components/app_surfaces.dart';
import '../../domain/coin_models.dart';
import '../coin_labels.dart';
import 'coin_primitive.dart';

final class CoinResultView extends StatelessWidget {
  const CoinResultView({
    required this.result,
    required this.reveal,
    required this.reducedMotion,
    required this.settle,
    this.onTap,
    this.assetBuilder,
    super.key,
  });

  final CoinTossResult result;
  final bool reveal;
  final bool reducedMotion;
  final bool settle;
  final VoidCallback? onTap;
  final RuntimeAssetBuilder? assetBuilder;

  @override
  Widget build(BuildContext context) {
    final content = result.config.mode == CoinTossMode.single
        ? _buildSingle(context)
        : _buildBatch(context);
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

  Widget _buildSingle(BuildContext context) {
    final side = result.sequence.single;
    final label = result.config.labelFor(side);
    final detailsVisible = !reveal || reducedMotion;
    return Semantics(
      liveRegion: true,
      label: detailsVisible
          ? '抛硬币结果，$label，原始面值 '
                '${coinRawSideId(side)} ${coinOriginalSideLabel(side)}'
          : '硬币正在抛起、翻转并落定，动画完成后显示结果',
      child: Column(
        children: <Widget>[
          AppPhysicalAction(
            key: const Key('coin-result-physical-entity'),
            label: detailsVisible ? '抛硬币结果，$label，点击再抛一次' : '硬币正在翻转，请等待动画完成',
            hint: detailsVisible ? '点击再抛一次' : '等待动画完成',
            onTap: detailsVisible ? onTap : null,
            child: CoinPrimitive(
              side: side,
              label: label,
              animate: reveal,
              assetBuilder: assetBuilder,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppRevealDetailsSlot(
            visible: detailsVisible,
            child: Column(
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '原始面值：${coinRawSideId(side)}'
                  '（${coinOriginalSideLabel(side)}）',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: context.appColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatch(BuildContext context) {
    final duration = result.tossCount > AppSizes.coinDetailedRevealLimit
        ? context.appMotion.coinLargeBatchReveal
        : context.appMotion.reveal;
    final detailsVisible = !reveal || reducedMotion;
    return Semantics(
      container: true,
      label: detailsVisible
          ? '批量硬币结果，共抛 ${result.tossCount} 次，'
                '${result.config.headsLabel} ${result.headsCount}，'
                '${result.config.tailsLabel} ${result.tailsCount}，'
                '${coinStopReasonLabel(result)}'
          : '批量硬币正在抛起、翻转并落定，共 ${result.tossCount} 次',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppRevealDetailsSlot(
            visible: detailsVisible,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '共抛 ${result.tossCount} 次',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.xl,
                  runSpacing: AppSpacing.md,
                  children: <Widget>[
                    CoinResultMetric(
                      label: result.config.headsLabel,
                      value: '${result.headsCount}',
                    ),
                    CoinResultMetric(
                      label: result.config.tailsLabel,
                      value: '${result.tailsCount}',
                    ),
                    CoinResultMetric(
                      label: '${result.config.headsLabel}比例',
                      value: _percentage(result.headsCount),
                    ),
                    CoinResultMetric(
                      label: '${result.config.tailsLabel}比例',
                      value: _percentage(result.tailsCount),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(coinStopReasonLabel(result)),
                const SizedBox(height: AppSpacing.xl),
                Text('按产生顺序', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          AppPhysicalAction(
            key: const Key('coin-result-physical-entity'),
            label: '批量抛硬币结果，点击再抛一次',
            hint: '点击再抛一次',
            onTap: onTap,
            child: reveal
                ? TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: AppSpacing.zero, end: 1),
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    builder: (context, progress, child) => _CoinSequence(
                      result: result,
                      progress: progress,
                      streamReveal:
                          result.tossCount <= AppSizes.coinDetailedRevealLimit,
                      animate: reveal,
                      animationDuration: duration,
                      assetBuilder: assetBuilder,
                    ),
                  )
                : _CoinSequence(
                    result: result,
                    progress: 1,
                    assetBuilder: assetBuilder,
                  ),
          ),
        ],
      ),
    );
  }

  String _percentage(int count) {
    final value = count * 100 / result.tossCount;
    return value == value.roundToDouble()
        ? '${value.toStringAsFixed(0)}%'
        : '${value.toStringAsFixed(1)}%';
  }
}

final class CoinResultMetric extends StatelessWidget {
  const CoinResultMetric({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label $value',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: context.appColors.textSecondary),
        ),
      ],
    ),
  );
}

final class _CoinSequence extends StatelessWidget {
  const _CoinSequence({
    required this.result,
    required this.progress,
    this.animate = false,
    this.animationDuration,
    this.streamReveal = false,
    this.assetBuilder,
  });

  final CoinTossResult result;
  final double progress;
  final bool animate;
  final Duration? animationDuration;
  final bool streamReveal;
  final RuntimeAssetBuilder? assetBuilder;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.md,
    runSpacing: AppSpacing.lg,
    children: result.sequence.indexed
        .map((entry) {
          final localProgress =
              (streamReveal
                      ? ((progress -
                                    (entry.$1 / result.tossCount) *
                                        AppMotionValues.coinStreamWindow) /
                                (1 - AppMotionValues.coinStreamWindow))
                            .clamp(AppSpacing.zero, 1)
                      : progress)
                  .toDouble();
          return Semantics(
            label: animate
                ? '第${entry.$1 + 1}次硬币正在翻转'
                : '第${entry.$1 + 1}次，'
                      '${result.config.labelFor(entry.$2)}，原始面值 '
                      '${coinRawSideId(entry.$2)}',
            child: ExcludeSemantics(
              child: Opacity(
                opacity: localProgress,
                child: Transform.translate(
                  offset: Offset(
                    AppSpacing.zero,
                    streamReveal
                        ? AppSpacing.md * (1 - localProgress)
                        : AppSpacing.zero,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('#${entry.$1 + 1}'),
                      const SizedBox(height: AppSpacing.xs),
                      CoinPrimitive(
                        side: entry.$2,
                        label: result.config.labelFor(entry.$2),
                        compact: true,
                        animate: animate,
                        animationDuration: animationDuration,
                        assetBuilder: assetBuilder,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        })
        .toList(growable: false),
  );
}
