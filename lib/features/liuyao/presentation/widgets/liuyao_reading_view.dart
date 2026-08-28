import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/app_tokens.dart';
import '../../../../design_system/components/app_surfaces.dart';
import '../../content/liuyao_content_catalog.dart';
import '../../domain/liuyao_hexagrams.dart';
import '../../domain/liuyao_models.dart';
import '../liuyao_labels.dart';
import 'liuyao_line_primitive.dart';

final class LiuyaoDraftLinesView extends StatelessWidget {
  const LiuyaoDraftLinesView({
    required this.reading,
    this.animateLatest = false,
    this.compact = false,
    super.key,
  });

  final LiuyaoReading reading;
  final bool animateLatest;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Text('已确认 ${reading.lines.length}/6 爻 · 记录顺序：自下而上'),
      const SizedBox(height: AppSpacing.md),
      if (compact)
        for (var index = LiuyaoReading.lineCapacity - 1; index >= 0; index--)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: index < reading.lines.length
                ? _CompactLiuyaoLine(line: reading.lines[index])
                : const _EmptyCompactLiuyaoLine(),
          )
      else if (reading.lines.isEmpty)
        const Text('尚未确认爻；下一次操作从初爻开始。')
      else
        for (final line in reading.lines.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                LiuyaoLinePrimitive(
                  line: line,
                  animate:
                      animateLatest && line.index == reading.lines.length - 1,
                ),
                Text(
                  '${liuyaoLinePositionLabel(line.index)} · ${line.value} · '
                  '${liuyaoLineKindLabel(line.kind)} · '
                  '${line.isMoving ? '动' : '静'}',
                ),
              ],
            ),
          ),
    ],
  );
}

final class _EmptyCompactLiuyaoLine extends StatelessWidget {
  const _EmptyCompactLiuyaoLine();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: AppSizes.liuyaoLineWidth,
    height: AppSizes.minimumTapTarget,
    child: Center(
      child: Container(
        height: AppSizes.liuyaoLineThickness,
        decoration: BoxDecoration(
          color: context.appColors.border,
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
      ),
    ),
  );
}

final class _CompactLiuyaoLine extends StatelessWidget {
  const _CompactLiuyaoLine({required this.line});

  final LiuyaoLine line;

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.liuyao;
    Widget bar(double width) => SizedBox(
      width: width,
      height: AppSizes.liuyaoLineThickness,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
      ),
    );
    final segment = bar((AppSizes.liuyaoLineWidth - AppSizes.liuyaoYinGap) / 2);
    final visual = SizedBox(
      width: AppSizes.liuyaoLineWidth,
      height: AppSizes.minimumTapTarget,
      child: Center(
        child: line.nature == LiuyaoLineNature.yang
            ? bar(AppSizes.liuyaoLineWidth)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  segment,
                  const SizedBox(width: AppSizes.liuyaoYinGap),
                  segment,
                ],
              ),
      ),
    );
    return Semantics(
      label: liuyaoLineSemanticLabel(line),
      child: ExcludeSemantics(child: visual),
    );
  }
}

final class LiuyaoReadingView extends StatefulWidget {
  const LiuyaoReadingView({
    required this.reading,
    this.animateLatest = false,
    this.reducedMotion = false,
    super.key,
  });

  final LiuyaoReading reading;
  final bool animateLatest;
  final bool reducedMotion;

  @override
  State<LiuyaoReadingView> createState() => _LiuyaoReadingViewState();
}

final class _LiuyaoReadingViewState extends State<LiuyaoReadingView> {
  void _showMeaning() {
    final explanation = const LiuyaoInterpretationComposer().compose(
      widget.reading,
    );
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _LiuyaoMeaningSheet(explanation: explanation),
      ),
    );
  }

  Widget _buildHexagramVisual({
    required String keyValue,
    required String semanticLabel,
    required Iterable<LiuyaoLine> lines,
    bool changed = false,
  }) => Semantics(
    key: Key(keyValue),
    button: true,
    label: '$semanticLabel，点击查看卦象含义',
    onTap: _showMeaning,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showMeaning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => LiuyaoLinePrimitive(
                line: line,
                changed: changed,
                compact: true,
                animate:
                    !changed &&
                    widget.animateLatest &&
                    line.index == LiuyaoReading.lineCapacity - 1,
              ),
            )
            .toList(growable: false),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final reading = widget.reading;
    if (!reading.isComplete) {
      throw ArgumentError('LiuyaoReadingView requires six lines.');
    }
    final primary = LiuyaoHexagrams.resolve(reading.lines);
    final hasMovingLines = reading.movingLineIndexes.isNotEmpty;
    final changed = hasMovingLines
        ? LiuyaoHexagrams.resolve(reading.lines, changed: true)
        : null;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionCard(
          key: const Key('liuyao-primary-hexagram'),
          onTap: _showMeaning,
          title: '本卦 · 第 ${primary.kingWenNumber} 卦 ${primary.name}',
          semanticLabel:
              '本卦第 ${primary.kingWenNumber} 卦${primary.name}，'
              '上卦${primary.upper.name}，下卦${primary.lower.name}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('稳定 ID：${primary.id}'),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '上卦：${primary.upper.name}（${primary.upper.symbol}） · '
                '下卦：${primary.lower.name}（${primary.lower.symbol}）',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildHexagramVisual(
                keyValue: 'liuyao-hexagram-visual',
                semanticLabel: '本卦第 ${primary.kingWenNumber} 卦${primary.name}',
                lines: reading.lines.reversed,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text('点击卦象查看含义'),
              Text(
                hasMovingLines
                    ? '动爻：${reading.movingLineIndexes.map((index) => liuyaoLinePositionLabel(index)).join('、')}'
                    : '无动爻，本卦不变。',
                key: const Key('liuyao-moving-summary'),
              ),
            ],
          ),
        ),
        if (changed != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          AppSectionCard(
            key: const Key('liuyao-changed-hexagram'),
            onTap: _showMeaning,
            title: '变卦 · 第 ${changed.kingWenNumber} 卦 ${changed.name}',
            semanticLabel:
                '变卦第 ${changed.kingWenNumber} 卦${changed.name}，'
                '上卦${changed.upper.name}，下卦${changed.lower.name}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('稳定 ID：${changed.id}'),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '上卦：${changed.upper.name}（${changed.upper.symbol}） · '
                  '下卦：${changed.lower.name}（${changed.lower.symbol}）',
                ),
                const SizedBox(height: AppSpacing.md),
                _buildHexagramVisual(
                  keyValue: 'liuyao-changed-hexagram-visual',
                  semanticLabel:
                      '变卦第 ${changed.kingWenNumber} 卦${changed.name}',
                  lines: reading.lines.reversed,
                  changed: true,
                ),
              ],
            ),
          ),
        ],
      ],
    );
    if (!widget.reducedMotion) return content;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: AppSpacing.zero, end: 1),
      duration: context.appMotion.reduced,
      curve: Curves.linear,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: content,
    );
  }
}

final class _LiuyaoMeaningSheet extends StatelessWidget {
  const _LiuyaoMeaningSheet({required this.explanation});

  final LiuyaoReadingExplanation explanation;

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
        key: const Key('liuyao-meaning-sheet'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('卦象释义', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            Text(
              explanation.primary.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(explanation.primary.structureSummary),
            if (explanation.changed case final changed?) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Text(
                changed.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(changed.structureSummary),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text('动爻关系', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(explanation.changeRelationship),
            const SizedBox(height: AppSpacing.lg),
            Text('反思提示', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(explanation.reflectionPrompt),
          ],
        ),
      ),
    ),
  );
}
