import 'dart:async';

import 'package:flutter/material.dart';

import '../../../assets/runtime/runtime_asset_manifest.dart';
import '../../../core/tools/tool_module.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/components/app_button.dart';
import '../../../design_system/components/app_runtime_asset.dart';
import '../../../design_system/components/app_surfaces.dart';
import '../../../design_system/components/app_tool_scaffold.dart';
import '../../liuyao/content/liuyao_content_catalog.dart';
import '../../liuyao/domain/liuyao_hexagrams.dart';
import '../../liuyao/domain/liuyao_models.dart';
import '../../tarot/content/tarot_content_catalog.dart';
import '../../tarot/domain/tarot_deck.dart';
import '../../tarot/domain/tarot_models.dart';
import '../domain/encyclopedia_models.dart';

final class EncyclopediaToolPage extends StatefulWidget {
  const EncyclopediaToolPage({required this.moduleContext, super.key});

  final ToolModuleContext moduleContext;

  @override
  State<EncyclopediaToolPage> createState() => _EncyclopediaToolPageState();
}

final class _EncyclopediaToolPageState extends State<EncyclopediaToolPage> {
  final _searchController = TextEditingController();
  EncyclopediaSection _section = EncyclopediaSection.tarot;
  TarotCard? _selectedTarot;
  LiuyaoHexagram? _selectedHexagram;
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TarotCard> get _filteredTarotCards => TarotDeck.standard
      .where((card) => _matchesTarot(card, _query))
      .toList(growable: false);

  void _selectSection(EncyclopediaSection section) {
    if (_section == section) return;
    _searchController.clear();
    setState(() {
      _section = section;
      _query = '';
      _selectedTarot = null;
      _selectedHexagram = null;
    });
  }

  void _updateQuery(String value) {
    setState(() {
      _query = value;
      _selectedTarot = null;
      _selectedHexagram = null;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _updateQuery('');
  }

  void _selectTarot(TarotCard card) {
    setState(() {
      _selectedTarot = card;
      _selectedHexagram = null;
    });
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _TarotMeaningSheet(card: card),
      ),
    );
  }

  void _selectHexagram(LiuyaoHexagram hexagram) {
    setState(() {
      _selectedHexagram = hexagram;
      _selectedTarot = null;
    });
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _HexagramMeaningSheet(hexagram: hexagram),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppToolScaffold(
    key: const Key('encyclopedia-page'),
    title: '塔罗/周易图鉴',
    subtitle: '浏览牌面与卦象，点击任意条目查看释义',
    onBack: widget.moduleContext.onBack,
    primary: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSectionTabs(),
        const SizedBox(height: AppSpacing.lg),
        _buildSearch(),
        const SizedBox(height: AppSpacing.lg),
        if (_section == EncyclopediaSection.tarot)
          _buildTarotGrid()
        else
          _buildHexagramTable(),
      ],
    ),
  );

  Widget _buildSectionTabs() => Semantics(
    container: true,
    label: '图鉴类型',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('图鉴类型', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            _EncyclopediaTab(
              key: const Key('encyclopedia-tab-tarot'),
              label: '塔罗牌图鉴',
              icon: Icons.auto_awesome_outlined,
              selected: _section == EncyclopediaSection.tarot,
              onTap: () => _selectSection(EncyclopediaSection.tarot),
            ),
            _EncyclopediaTab(
              key: const Key('encyclopedia-tab-liuyao'),
              label: '周易图鉴',
              icon: Icons.change_history_outlined,
              selected: _section == EncyclopediaSection.liuyao,
              onTap: () => _selectSection(EncyclopediaSection.liuyao),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildSearch() => AppSectionCard(
    title: '搜索',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          key: const Key('encyclopedia-search-field'),
          controller: _searchController,
          onChanged: _updateQuery,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: _section == EncyclopediaSection.tarot
                ? '输入牌名、牌组或关键词'
                : '输入卦名、序号或上下卦',
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        if (_query.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppButton(
              key: const Key('encyclopedia-clear-search'),
              label: '清除搜索',
              leading: Icons.clear,
              variant: AppButtonVariant.quiet,
              onPressed: _clearSearch,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _buildTarotGrid() {
    final cards = _filteredTarotCards;
    return AppSectionCard(
      key: const Key('encyclopedia-tarot-grid'),
      title: '塔罗牌 · ${cards.length} 张',
      child: cards.isEmpty
          ? const Text('没有找到匹配的塔罗牌。')
          : LayoutBuilder(
              builder: (context, constraints) {
                final spacing = AppSpacing.md;
                final columns =
                    ((constraints.maxWidth + spacing) /
                            (AppSizes.tarotCardWidth + AppSpacing.sm + spacing))
                        .floor()
                        .clamp(2, 6)
                        .toInt();
                final cardWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: cards
                      .map(
                        (card) => SizedBox(
                          width: cardWidth,
                          child: _buildTarotCardTile(card),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
    );
  }

  Widget _buildTarotCardTile(TarotCard card) {
    final selected = _selectedTarot?.id == card.id;
    return AppSectionCard(
      key: ValueKey<String>('encyclopedia-tarot-${card.id}'),
      tone: selected ? AppSurfaceTone.result : AppSurfaceTone.inset,
      semanticLabel: '${card.name}牌面，点击查看释义',
      onTap: () => _selectTarot(card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _TarotCardArtwork(card: card),
          const SizedBox(height: AppSpacing.sm),
          Text(
            card.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildHexagramTable() {
    final trigrams = LiuyaoTrigrams.all;
    final query = _query.trim();
    return AppSectionCard(
      key: const Key('encyclopedia-liuyao-table'),
      title: '周易卦象 · 64 卦',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('行：上卦 · 列：下卦'),
          if (query.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            const Text('搜索结果保留原有行列位置。'),
          ],
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: AppSpacing.sm,
              dataRowMinHeight: AppSizes.minimumTapTarget * 2,
              dataRowMaxHeight: double.infinity,
              headingRowHeight: AppSizes.minimumTapTarget * 2,
              horizontalMargin: AppSpacing.sm,
              columns: <DataColumn>[
                const DataColumn(label: Text('上卦')),
                for (final lower in trigrams)
                  DataColumn(label: _TrigramHeader(trigram: lower)),
              ],
              rows: <DataRow>[
                for (final upper in trigrams)
                  DataRow(
                    cells: <DataCell>[
                      DataCell(_TrigramHeader(trigram: upper, row: true)),
                      for (final lower in trigrams)
                        DataCell(
                          _buildHexagramCell(
                            LiuyaoHexagrams.fromTrigrams(
                              upper: upper,
                              lower: lower,
                            ),
                            visible:
                                query.isEmpty ||
                                _matchesHexagram(
                                  LiuyaoHexagrams.fromTrigrams(
                                    upper: upper,
                                    lower: lower,
                                  ),
                                  query,
                                ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHexagramCell(LiuyaoHexagram hexagram, {required bool visible}) {
    final number = hexagram.kingWenNumber.toString().padLeft(2, '0');
    if (!visible) {
      return const SizedBox(
        width: AppSizes.minimumTapTarget * 1.25,
        height: AppSizes.minimumTapTarget * 1.5,
      );
    }
    final selected = _selectedHexagram?.id == hexagram.id;
    return Semantics(
      key: ValueKey<String>('encyclopedia-hexagram-$number'),
      button: true,
      label:
          '第 ${hexagram.kingWenNumber} 卦${hexagram.name}，'
          '上卦${hexagram.upper.name}，下卦${hexagram.lower.name}，点击查看释义',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.small),
          onTap: () => _selectHexagram(hexagram),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSizes.minimumTapTarget * 1.25,
              minHeight: AppSizes.minimumTapTarget * 1.5,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.small),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _HexagramGlyph(hexagram: hexagram, compact: true),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hexagram.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
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

  bool _matchesTarot(TarotCard card, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    final content = TarotContentCatalog.entryFor(card.id);
    final searchable = <String>[
      card.id,
      card.name,
      card.arcana == TarotArcana.major ? '大阿尔卡那' : '小阿尔卡那',
      ...content.uprightKeywords,
      ...content.reversedKeywords,
      ...content.traditionalSymbols,
      content.uprightMeaning,
      content.reversedMeaning,
    ].join(' ').toLowerCase();
    return searchable.contains(normalizedQuery);
  }

  bool _matchesHexagram(LiuyaoHexagram hexagram, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    final content = LiuyaoContentCatalog.forHexagram(hexagram);
    final searchable = <String>[
      hexagram.id,
      hexagram.kingWenNumber.toString(),
      hexagram.name,
      hexagram.upper.name,
      hexagram.upper.symbol,
      hexagram.lower.name,
      hexagram.lower.symbol,
      content.title,
      content.classicText,
      content.structureSummary,
      content.reflectionPrompt,
    ].join(' ').toLowerCase();
    return searchable.contains(normalizedQuery);
  }
}

final class _EncyclopediaTab extends StatelessWidget {
  const _EncyclopediaTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      minWidth: AppSizes.minimumTapTarget,
      minHeight: AppSizes.minimumTapTarget,
    ),
    child: Semantics(
      selected: selected,
      button: true,
      label: label,
      child: ChoiceChip(
        avatar: Icon(icon),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    ),
  );
}

final class _TarotCardArtwork extends StatelessWidget {
  const _TarotCardArtwork({required this.card, this.large = false});

  final TarotCard card;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final asset = RuntimeAssetManifest.tarotFace(
      cardId: card.id,
      orientation: RuntimeAssetOrientation.upright,
      semanticLabel: '${card.name}牌面',
    );
    final image = AspectRatio(
      aspectRatio: 2 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.appColors.tarotSurface,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          border: Border.all(color: context.appColors.tarot),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          child: RuntimeAssetSlot(
            asset: asset,
            fit: BoxFit.cover,
            fallback: _TarotImageFallback(card: card),
          ),
        ),
      ),
    );
    return large
        ? SizedBox(width: AppSizes.tarotCardWidth * 0.82, child: image)
        : image;
  }
}

final class _TarotImageFallback extends StatelessWidget {
  const _TarotImageFallback({required this.card});

  final TarotCard card;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.auto_awesome, color: context.appColors.tarot),
          const SizedBox(height: AppSpacing.sm),
          Text(
            card.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: context.appColors.tarot),
          ),
        ],
      ),
    ),
  );
}

final class _TrigramHeader extends StatelessWidget {
  const _TrigramHeader({required this.trigram, this.row = false});

  final LiuyaoTrigram trigram;
  final bool row;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${row ? '上' : '下'}卦${trigram.name}，${trigram.symbol}',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(trigram.name, style: Theme.of(context).textTheme.labelLarge),
        Text(trigram.symbol),
      ],
    ),
  );
}

final class _HexagramGlyph extends StatelessWidget {
  const _HexagramGlyph({required this.hexagram, this.compact = false});

  final LiuyaoHexagram hexagram;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${hexagram.name}卦象',
    child: ExcludeSemantics(
      child: CustomPaint(
        size: Size(
          compact
              ? AppSizes.minimumTapTarget * 1.2
              : AppSizes.liuyaoLineWidth * 0.72,
          compact
              ? AppSizes.minimumTapTarget * 1.25
              : AppSizes.minimumTapTarget * 3.5,
        ),
        painter: _HexagramGlyphPainter(
          natures: <LiuyaoLineNature>[
            ...hexagram.upper.lines.reversed.map(_natureFor),
            ...hexagram.lower.lines.reversed.map(_natureFor),
          ],
          color: context.appColors.liuyao,
        ),
      ),
    ),
  );

  static LiuyaoLineNature _natureFor(int value) =>
      value == 1 ? LiuyaoLineNature.yang : LiuyaoLineNature.yin;
}

final class _HexagramGlyphPainter extends CustomPainter {
  const _HexagramGlyphPainter({required this.natures, required this.color});

  final List<LiuyaoLineNature> natures;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = AppSizes.liuyaoLineThickness * 0.45
      ..strokeCap = StrokeCap.round;
    final step = size.height / natures.length;
    final yinGap = size.width * 0.22;
    final segmentWidth = (size.width - yinGap) / 2;
    for (var index = 0; index < natures.length; index++) {
      final y = step * (index + 0.5);
      if (natures[index] == LiuyaoLineNature.yang) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      } else {
        canvas.drawLine(Offset(0, y), Offset(segmentWidth, y), paint);
        canvas.drawLine(
          Offset(segmentWidth + yinGap, y),
          Offset(size.width, y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HexagramGlyphPainter oldDelegate) =>
      oldDelegate.natures != natures || oldDelegate.color != color;
}

final class _TarotMeaningSheet extends StatelessWidget {
  const _TarotMeaningSheet({required this.card});

  final TarotCard card;

  @override
  Widget build(BuildContext context) {
    final content = TarotContentCatalog.entryFor(card.id);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: KeyedSubtree(
          key: const Key('encyclopedia-tarot-detail'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(child: _TarotCardArtwork(card: card, large: true)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                card.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                card.arcana == TarotArcana.major ? '大阿尔卡那' : '小阿尔卡那',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              _EncyclopediaDetailField(
                label: '正位关键词',
                value: content.uprightKeywords.join(' · '),
              ),
              _EncyclopediaDetailField(
                label: '逆位关键词',
                value: content.reversedKeywords.join(' · '),
              ),
              _EncyclopediaDetailField(
                label: '传统牌义（Rider–Waite–Smith 体系）',
                value: content.traditionalSymbols.join('；'),
              ),
              _EncyclopediaDetailField(
                label: '常见正位解读',
                value: content.uprightMeaning,
              ),
              _EncyclopediaDetailField(
                label: '常见逆位解读',
                value: content.reversedMeaning,
              ),
              _EncyclopediaBulletField(
                label: '观察问题',
                values: content.reflectionQuestions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _HexagramMeaningSheet extends StatelessWidget {
  const _HexagramMeaningSheet({required this.hexagram});

  final LiuyaoHexagram hexagram;

  @override
  Widget build(BuildContext context) {
    final content = LiuyaoContentCatalog.forHexagram(hexagram);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: KeyedSubtree(
          key: const Key('encyclopedia-liuyao-detail'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(child: _HexagramGlyph(hexagram: hexagram)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                content.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '上卦${hexagram.upper.name}（${hexagram.upper.symbol}） · '
                '下卦${hexagram.lower.name}（${hexagram.lower.symbol}）',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              _EncyclopediaDetailField(
                label: '《周易》卦辞原文',
                value: content.classicText,
              ),
              _EncyclopediaDetailField(
                label: '常见结构解读',
                value: content.structureSummary,
              ),
              _EncyclopediaDetailField(
                label: '观察提示',
                value: content.reflectionPrompt,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _EncyclopediaDetailField extends StatelessWidget {
  const _EncyclopediaDetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(value),
      ],
    ),
  );
}

final class _EncyclopediaBulletField extends StatelessWidget {
  const _EncyclopediaBulletField({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        for (final value in values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text('· $value'),
          ),
      ],
    ),
  );
}
