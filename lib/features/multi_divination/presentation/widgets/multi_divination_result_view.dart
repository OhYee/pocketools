import 'package:flutter/material.dart';

import '../../../../design_system/app_tokens.dart';
import '../../../../design_system/components/app_surfaces.dart';
import '../../../liuyao/domain/liuyao_models.dart';
import '../../../liuyao/presentation/widgets/liuyao_line_primitive.dart';
import '../../../liuyao/presentation/widgets/liuyao_reading_view.dart';
import '../../content/multi_divination_interpretation.dart';
import '../../domain/multi_divination_models.dart';
import '../multi_divination_labels.dart';
import 'multi_divination_group_view.dart';

final class MultiDivinationResultView extends StatelessWidget {
  const MultiDivinationResultView({
    required this.reading,
    this.onCardTap,
    this.animateLatest = false,
    this.reducedMotion = false,
    super.key,
  });

  final MultiDivinationReading reading;
  final void Function(MultiDivinationGroup, MultiDivinationCard)? onCardTap;
  final bool animateLatest;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final explanation = const MultiDivinationInterpretationComposer().resolve(
      reading,
    );
    final progressReading = LiuyaoReading(
      config: const LiuyaoConfig(mode: LiuyaoMode.manual),
      lines: reading.liuyaoLines,
    );
    final priorGroups = reading.groups.isEmpty
        ? const <MultiDivinationGroup>[]
        : reading.groups.sublist(0, reading.groups.length - 1);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (priorGroups.isNotEmpty) ...<Widget>[
          AppSectionCard(
            key: const Key('multi-divination-group-history'),
            title: '已保存的组',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: priorGroups
                  .map(
                    (group) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            '${multiDivinationGroupLabel(group.index)} · '
                            '${multiDivinationLineLabel(group)}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          MultiDivinationGroupCardsView(
                            group: group,
                            compact: true,
                            onCardTap: onCardTap == null
                                ? null
                                : (card) => onCardTap!(group, card),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (reading.groups.isEmpty)
          AppSectionCard(
            key: const Key('multi-divination-progress'),
            child: Text(
              '尚未抽取；点击上方牌堆开始第一组 A/B/C。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          )
        else ...<Widget>[
          AppSectionCard(
            key: const Key('multi-divination-progress'),
            title: '六爻进度',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(multiDivinationProgressLabel(reading)),
                const SizedBox(height: AppSpacing.md),
                LiuyaoDraftLinesView(
                  reading: progressReading,
                  animateLatest: animateLatest,
                  compact: true,
                ),
              ],
            ),
          ),
          if (reading.isComplete) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            _buildCompleteOutcome(context, explanation),
          ],
        ],
      ],
    );
    if (!reducedMotion) return content;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: AppSpacing.zero, end: 1),
      duration: context.appMotion.reduced,
      curve: Curves.linear,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: content,
    );
  }

  Widget _buildCompleteOutcome(
    BuildContext context,
    MultiDivinationReadingInterpretation explanation,
  ) {
    final primary = explanation.primaryHexagram!;
    final changed = explanation.changedHexagram;
    final lines = reading.liuyaoLines;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionCard(
          key: const Key('multi-divination-primary-hexagram'),
          title: '本卦 · 第 ${primary.kingWenNumber} 卦 ${primary.name}',
          semanticLabel: '本卦第 ${primary.kingWenNumber} 卦${primary.name}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '上卦：${primary.upper.name}（${primary.upper.symbol}） · '
                '下卦：${primary.lower.name}（${primary.lower.symbol}）',
              ),
              const SizedBox(height: AppSpacing.md),
              for (final line in lines.reversed)
                LiuyaoLinePrimitive(line: line, compact: true),
              const SizedBox(height: AppSpacing.sm),
              Text(
                reading.movingLineIndexes.isEmpty
                    ? '动爻：无 · 本卦不变'
                    : '动爻：${reading.movingLineIndexes.map((index) => index + 1).join('、')}',
                key: const Key('multi-divination-moving-summary'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionCard(
          key: const Key('multi-divination-changed-hexagram'),
          title: changed == null
              ? '变卦 · 无（本卦不变）'
              : '变卦 · 第 ${changed.kingWenNumber} 卦 ${changed.name}',
          child: changed == null
              ? const Text('六组均为静爻，变卦不另行生成。')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '上卦：${changed.upper.name}（${changed.upper.symbol}） · '
                      '下卦：${changed.lower.name}（${changed.lower.symbol}）',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final line in lines.reversed)
                      LiuyaoLinePrimitive(
                        line: line,
                        changed: true,
                        compact: true,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionCard(
          key: const Key('multi-divination-a-summaries'),
          title: 'A1-A6 摘要',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: explanation.groups
                .map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${multiDivinationGroupLabel(group.group.index)} 摘要',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text('关键词：${group.primary.keywords.join('、')}'),
                        const SizedBox(height: AppSpacing.xs),
                        Text(multiDivinationLineLabel(group.group)),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionCard(
          key: const Key('multi-divination-fusion-explanation'),
          title: '融合解释',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[Text(explanation.combinationHint)],
          ),
        ),
      ],
    );
  }
}
