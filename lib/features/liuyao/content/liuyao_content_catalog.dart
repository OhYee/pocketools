import '../domain/liuyao_hexagrams.dart';
import '../domain/liuyao_models.dart';

final class LiuyaoHexagramContent {
  const LiuyaoHexagramContent({
    required this.hexagramId,
    required this.title,
    required this.structureSummary,
    required this.reflectionPrompt,
  });

  final String hexagramId;
  final String title;
  final String structureSummary;
  final String reflectionPrompt;
}

final class LiuyaoReadingExplanation {
  const LiuyaoReadingExplanation({
    required this.primary,
    required this.changeRelationship,
    required this.reflectionPrompt,
    required this.changed,
  });

  final LiuyaoHexagramContent primary;
  final String changeRelationship;
  final String reflectionPrompt;
  final LiuyaoHexagramContent? changed;
}

/// Pocketools-authored structural prompts. No classic line text or third-party
/// modern interpretation is embedded in this package.
abstract final class LiuyaoContentCatalog {
  static const contentVersion = '1.0.0';

  static final List<LiuyaoHexagramContent> all = List.unmodifiable(
    LiuyaoHexagrams.all.map(_buildContent),
  );

  static LiuyaoHexagramContent forHexagram(LiuyaoHexagram hexagram) {
    for (final content in all) {
      if (content.hexagramId == hexagram.id) return content;
    }
    throw StateError('Missing original content for ${hexagram.id}.');
  }

  static List<String> validate() {
    final errors = <String>[];
    if (all.length != LiuyaoHexagrams.all.length) {
      errors.add('Liuyao content must cover all 64 hexagrams.');
    }
    final ids = <String>{};
    for (final content in all) {
      if (!ids.add(content.hexagramId)) {
        errors.add('Duplicate Liuyao content id: ${content.hexagramId}.');
      }
      if (content.title.trim().isEmpty ||
          content.structureSummary.trim().isEmpty ||
          content.reflectionPrompt.trim().isEmpty) {
        errors.add('Liuyao content ${content.hexagramId} has an empty field.');
      }
    }
    return List<String>.unmodifiable(errors);
  }

  static LiuyaoHexagramContent _buildContent(LiuyaoHexagram hexagram) {
    final upper = hexagram.upper;
    final lower = hexagram.lower;
    return LiuyaoHexagramContent(
      hexagramId: hexagram.id,
      title: '第 ${hexagram.kingWenNumber} 卦 · ${hexagram.name}',
      structureSummary:
          '上卦${upper.name}（${upper.symbol}）强调${upper.theme}；'
          '下卦${lower.name}（${lower.symbol}）提供${lower.theme}的起点。'
          '“${hexagram.name}”在这里作为两组阴阳结构的名称，适合观察上下力量如何呼应。',
      reflectionPrompt: '可以先区分眼前情境的内在基础与外在表现，再思考两者之间有哪些可以调整的连接。',
    );
  }
}

final class LiuyaoInterpretationComposer {
  const LiuyaoInterpretationComposer();

  LiuyaoReadingExplanation compose(LiuyaoReading reading) {
    if (!reading.isComplete) {
      throw ArgumentError(
        'Interpretation requires a completed six-line reading.',
      );
    }
    final primaryHexagram = LiuyaoHexagrams.resolve(reading.lines);
    final primary = LiuyaoContentCatalog.forHexagram(primaryHexagram);
    final moving = reading.lines.where((line) => line.isMoving).toList();
    if (moving.isEmpty) {
      return LiuyaoReadingExplanation(
        primary: primary,
        changeRelationship: '无动爻，本卦不变。',
        reflectionPrompt: primary.reflectionPrompt,
        changed: null,
      );
    }

    final changedHexagram = LiuyaoHexagrams.resolve(
      reading.lines,
      changed: true,
    );
    final changed = LiuyaoContentCatalog.forHexagram(changedHexagram);
    final changes = moving
        .map((line) {
          final from = line.nature == LiuyaoLineNature.yang ? '阳' : '阴';
          final to = line.changedNature == LiuyaoLineNature.yang ? '阳' : '阴';
          return '第${line.index + 1}爻由$from变$to';
        })
        .join('、');
    return LiuyaoReadingExplanation(
      primary: primary,
      changeRelationship:
          '$changes；变卦为第 ${changedHexagram.kingWenNumber} 卦“${changedHexagram.name}”。',
      reflectionPrompt:
          '${primary.reflectionPrompt} 也可以比较变卦“${changedHexagram.name}”呈现的结构，'
          '把差异当作一种开放式观察线索。',
      changed: changed,
    );
  }
}
