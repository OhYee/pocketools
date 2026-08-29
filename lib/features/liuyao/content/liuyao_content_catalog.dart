import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/liuyao_hexagrams.dart';
import '../domain/liuyao_models.dart';

final class LiuyaoLineContent {
  const LiuyaoLineContent({
    required this.position,
    required this.type,
    required this.classicText,
  });

  final int position;
  final String type;
  final String classicText;

  String get title => switch (position) {
    1 => '初$type',
    6 => '上$type',
    _ => '$type${<String>['', '一', '二', '三', '四', '五', '六'][position]}',
  };
}

final class LiuyaoHexagramContent {
  const LiuyaoHexagramContent({
    required this.hexagramId,
    required this.title,
    required this.classicText,
    required this.structureSummary,
    required this.reflectionPrompt,
  });

  final String hexagramId;
  final String title;
  final String classicText;
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

/// Public-domain Zhouyi judgments and line texts plus app-authored structural
/// prompts. The bundled line-text dataset is loaded on demand so opening a
/// tool does not delay application startup.
abstract final class LiuyaoContentCatalog {
  static const contentVersion = '1.2.0';
  static const lineTextAsset = 'assets/runtime/liuyao_lines.json';
  static final Map<int, Future<List<LiuyaoLineContent>>> _lineContentCache =
      <int, Future<List<LiuyaoLineContent>>>{};
  static final Map<int, List<LiuyaoLineContent>> _loadedLineContents =
      <int, List<LiuyaoLineContent>>{};

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
          content.classicText.trim().isEmpty ||
          content.structureSummary.trim().isEmpty ||
          content.reflectionPrompt.trim().isEmpty) {
        errors.add('Liuyao content ${content.hexagramId} has an empty field.');
      }
    }
    return List<String>.unmodifiable(errors);
  }

  static Future<List<LiuyaoLineContent>> lineContentsFor(
    LiuyaoHexagram hexagram, {
    AssetBundle? bundle,
  }) {
    if (bundle != null) return _loadLineContents(hexagram, bundle);
    return _lineContentCache.putIfAbsent(
      hexagram.kingWenNumber,
      () => _loadLineContents(hexagram, rootBundle),
    );
  }

  static List<LiuyaoLineContent>? cachedLineContentsFor(
    LiuyaoHexagram hexagram,
  ) => _loadedLineContents[hexagram.kingWenNumber];

  static Future<List<LiuyaoLineContent>> _loadLineContents(
    LiuyaoHexagram hexagram,
    AssetBundle bundle,
  ) async {
    final encoded = await bundle.loadString(lineTextAsset);
    final decoded = jsonDecode(encoded) as Map<String, Object?>;
    final hexagrams = decoded['hexagrams'] as List<Object?>;
    final rawHexagram = hexagrams.cast<Map<String, Object?>>().firstWhere(
      (entry) => entry['number'] == hexagram.kingWenNumber,
    );
    final lines = (rawHexagram['lines'] as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(
          (line) => LiuyaoLineContent(
            position: line['position'] as int,
            type: line['type'] as String,
            classicText: line['text'] as String,
          ),
        )
        .toList(growable: false);
    if (lines.length != LiuyaoReading.lineCapacity) {
      throw const FormatException('A hexagram must contain six line texts.');
    }
    final immutable = List<LiuyaoLineContent>.unmodifiable(lines);
    _loadedLineContents[hexagram.kingWenNumber] = immutable;
    return immutable;
  }

  static String commonLineInterpretation({
    required LiuyaoLineContent content,
    required bool moving,
  }) {
    final stage = switch (content.position) {
      1 => '事情刚开始，常见解读侧重打基础、观察时机',
      2 => '事情进入发展初段，常见解读侧重回应关系与稳步推进',
      3 => '处在下卦末端，常见解读侧重转折前的风险与取舍',
      4 => '进入上卦开端，常见解读侧重适应新环境与谨慎行动',
      5 => '接近核心位置，常见解读侧重承担责任与发挥影响力',
      6 => '事情发展到阶段末端，常见解读侧重收束、反省与避免过度',
      _ => throw RangeError.range(content.position, 1, 6, 'position'),
    };
    final nature = content.type == '九'
        ? '阳爻通常提示主动、推进或外显的力量'
        : '阴爻通常提示承接、调整或内敛的力量';
    final change = moving
        ? '本爻为动爻，阅读时应重点结合爻辞，并与变卦对应位置比较。'
        : '本爻为静爻，可作为本卦整体结构的背景来理解。';
    return '$stage；$nature。$change';
  }

  static LiuyaoHexagramContent _buildContent(LiuyaoHexagram hexagram) {
    final upper = hexagram.upper;
    final lower = hexagram.lower;
    return LiuyaoHexagramContent(
      hexagramId: hexagram.id,
      title: '第 ${hexagram.kingWenNumber} 卦 · ${hexagram.name}',
      classicText: _classicTexts[hexagram.kingWenNumber - 1],
      structureSummary:
          '上卦${upper.name}（${upper.symbol}）强调${upper.theme}；'
          '下卦${lower.name}（${lower.symbol}）提供${lower.theme}的起点。'
          '“${hexagram.name}”在这里作为两组阴阳结构的名称，适合观察上下力量如何呼应。',
      reflectionPrompt: '可以先区分眼前情境的内在基础与外在表现，再思考两者之间有哪些可以调整的连接。',
    );
  }

  /// 卦辞据《周易》电子底本校录；保留原文常见的繁体字形。
  static const List<String> _classicTexts = <String>[
    '乾：元亨。利貞。',
    '坤：元亨。利牝馬之貞。',
    '屯：元亨，利貞。勿用有攸往，利建侯。',
    '蒙：亨。匪我求童蒙，童蒙求我。初筮告，再三瀆，瀆則不告。利貞。',
    '需：有孚，光亨。貞吉，利涉大川。',
    '訟：有孚，窒，惕，中吉，終凶。利見大人，不利涉大川。',
    '師：貞丈人吉，无咎。',
    '比：吉。原筮元永貞，无咎。不寧方來，後夫凶。',
    '小畜：亨。密雲不雨，自我西郊。',
    '履虎尾，不咥人，亨。',
    '泰：小往大來，吉亨。',
    '否之匪人，不利君子貞，大往小來。',
    '同人于野，亨。利涉大川，利君子貞。',
    '大有：元亨。',
    '謙：亨，君子有終。',
    '豫：利建侯行師。',
    '隨：元亨。利貞。无咎。',
    '蠱：元亨。利涉大川。先甲三日，後甲三日。',
    '臨：元亨。利貞。至于八月有凶。',
    '觀：盥而不荐，有孚顒若。',
    '噬嗑：亨。利用獄。',
    '賁：亨。小利有攸往。',
    '剝：不利。有攸往。',
    '復：亨。出入无疾，朋來无咎。反復其道，七日來復，利有攸往。',
    '无妄：元亨。利貞。其匪正有眚，不利有攸往。',
    '大畜：利貞，不家食吉，利涉大川。',
    '頤：貞吉。觀頤，自求口實。',
    '大過：棟橈，利有攸往，亨。',
    '習坎：有孚，維心亨。行有尚。',
    '離：利貞。亨。畜牝牛，吉。',
    '咸：亨。利貞。取女吉。',
    '恆：亨，无咎。利貞，利有攸往。',
    '遯：亨。小利貞。',
    '大壯：利貞。',
    '晉：康侯用錫馬蕃庶，晝日三接。',
    '明夷：利艱貞。',
    '家人：利女貞。',
    '睽：小事吉。',
    '蹇：利西南，不利東北；利見大人，貞吉。',
    '解：利西南，无所往，其來復吉。有攸往，夙吉。',
    '損：有孚，元吉。无咎，可貞，利有攸往。曷之用？二簋可用享。',
    '益：利有攸往。利涉大川。',
    '夬：揚于王庭，孚號，有厲，告自邑，不利即戎，利有攸往。',
    '姤：女壯，勿用取女。',
    '萃：亨。王假有廟，利見大人，亨。利貞。用大牲吉，利有攸往。',
    '升：元亨，用見大人，勿恤，南征吉。',
    '困：亨，貞大人吉，无咎，有言不信。',
    '井：改邑不改井，无喪无得，往來井井。汔至亦未繘井。羸其瓶，凶。',
    '革：巳日乃孚，元亨。利貞。悔亡。',
    '鼎：元吉，亨。',
    '震：亨。震來虩虩，笑言啞啞。震驚百里，不喪匕鬯。',
    '艮：艮其背，不獲其身，行其庭，不見其人，无咎。',
    '漸：女歸吉，利貞。',
    '歸妹：征凶，无攸利。',
    '豐：亨。王假之，勿憂，宜日中。',
    '旅：小亨，旅貞吉。',
    '巽：小亨。利有攸往。利見大人。',
    '兌：亨。利貞。',
    '渙：亨。王假有廟，利涉大川，利貞。',
    '節：亨。苦節不可貞。',
    '中孚：豚魚吉，利涉大川，利貞。',
    '小過：亨。利貞。可小事，不可大事。飛鳥遺之音，不宜上宜下，大吉。',
    '既濟：亨小。利貞。初吉終亂。',
    '未濟：亨。小狐汔濟，濡其尾，无攸利。',
  ];
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
