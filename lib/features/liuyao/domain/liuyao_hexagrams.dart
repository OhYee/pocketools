import 'dart:collection';

import 'liuyao_models.dart';

final class LiuyaoTrigram {
  LiuyaoTrigram._({
    required this.id,
    required this.name,
    required this.symbol,
    required List<int> lines,
    required this.theme,
  }) : lines = UnmodifiableListView<int>(lines);

  final String id;
  final String name;
  final String symbol;
  final List<int> lines;
  final String theme;
}

abstract final class LiuyaoTrigrams {
  static final qian = LiuyaoTrigram._(
    id: 'trigram.qian',
    name: '乾',
    symbol: '天',
    lines: <int>[1, 1, 1],
    theme: '持续推动与主动创造',
  );
  static final dui = LiuyaoTrigram._(
    id: 'trigram.dui',
    name: '兑',
    symbol: '泽',
    lines: <int>[1, 1, 0],
    theme: '交流、开放与相互回应',
  );
  static final li = LiuyaoTrigram._(
    id: 'trigram.li',
    name: '离',
    symbol: '火',
    lines: <int>[1, 0, 1],
    theme: '辨明、依附与照见细节',
  );
  static final zhen = LiuyaoTrigram._(
    id: 'trigram.zhen',
    name: '震',
    symbol: '雷',
    lines: <int>[1, 0, 0],
    theme: '启动、触发与面对变化',
  );
  static final xun = LiuyaoTrigram._(
    id: 'trigram.xun',
    name: '巽',
    symbol: '风',
    lines: <int>[0, 1, 1],
    theme: '渐进、渗透与调整方式',
  );
  static final kan = LiuyaoTrigram._(
    id: 'trigram.kan',
    name: '坎',
    symbol: '水',
    lines: <int>[0, 1, 0],
    theme: '穿越阻力并辨认风险',
  );
  static final gen = LiuyaoTrigram._(
    id: 'trigram.gen',
    name: '艮',
    symbol: '山',
    lines: <int>[0, 0, 1],
    theme: '停驻、界限与重新观察',
  );
  static final kun = LiuyaoTrigram._(
    id: 'trigram.kun',
    name: '坤',
    symbol: '地',
    lines: <int>[0, 0, 0],
    theme: '承接、包容与积累条件',
  );

  static final List<LiuyaoTrigram> all = List<LiuyaoTrigram>.unmodifiable(
    <LiuyaoTrigram>[qian, dui, li, zhen, xun, kan, gen, kun],
  );

  static LiuyaoTrigram fromLines(Iterable<int> lines) {
    final values = List<int>.of(lines);
    if (values.length != 3 || values.any((value) => value != 0 && value != 1)) {
      throw ArgumentError('A trigram must contain exactly three binary lines.');
    }
    for (final trigram in all) {
      if (_sameLines(trigram.lines, values)) return trigram;
    }
    throw StateError('The binary trigram table is incomplete.');
  }

  static LiuyaoTrigram byId(String id) {
    for (final trigram in all) {
      if (trigram.id == id) return trigram;
    }
    throw ArgumentError.value(id, 'id', 'Unknown trigram id.');
  }

  static bool _sameLines(List<int> left, List<int> right) {
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

final class LiuyaoHexagram {
  const LiuyaoHexagram({
    required this.id,
    required this.kingWenNumber,
    required this.name,
    required this.upper,
    required this.lower,
  });

  final String id;
  final int kingWenNumber;
  final String name;
  final LiuyaoTrigram upper;
  final LiuyaoTrigram lower;
}

/// Explicit King Wen mapping. Entries are data, not inferred from display text.
abstract final class LiuyaoHexagrams {
  static final List<LiuyaoHexagram> all = List<LiuyaoHexagram>.unmodifiable(
    <LiuyaoHexagram>[
      _hex(1, '乾', LiuyaoTrigrams.qian, LiuyaoTrigrams.qian),
      _hex(2, '坤', LiuyaoTrigrams.kun, LiuyaoTrigrams.kun),
      _hex(3, '屯', LiuyaoTrigrams.kan, LiuyaoTrigrams.zhen),
      _hex(4, '蒙', LiuyaoTrigrams.gen, LiuyaoTrigrams.kan),
      _hex(5, '需', LiuyaoTrigrams.kan, LiuyaoTrigrams.qian),
      _hex(6, '讼', LiuyaoTrigrams.qian, LiuyaoTrigrams.kan),
      _hex(7, '师', LiuyaoTrigrams.kun, LiuyaoTrigrams.kan),
      _hex(8, '比', LiuyaoTrigrams.kan, LiuyaoTrigrams.kun),
      _hex(9, '小畜', LiuyaoTrigrams.xun, LiuyaoTrigrams.qian),
      _hex(10, '履', LiuyaoTrigrams.qian, LiuyaoTrigrams.dui),
      _hex(11, '泰', LiuyaoTrigrams.kun, LiuyaoTrigrams.qian),
      _hex(12, '否', LiuyaoTrigrams.qian, LiuyaoTrigrams.kun),
      _hex(13, '同人', LiuyaoTrigrams.qian, LiuyaoTrigrams.li),
      _hex(14, '大有', LiuyaoTrigrams.li, LiuyaoTrigrams.qian),
      _hex(15, '谦', LiuyaoTrigrams.kun, LiuyaoTrigrams.gen),
      _hex(16, '豫', LiuyaoTrigrams.zhen, LiuyaoTrigrams.kun),
      _hex(17, '随', LiuyaoTrigrams.dui, LiuyaoTrigrams.zhen),
      _hex(18, '蛊', LiuyaoTrigrams.gen, LiuyaoTrigrams.xun),
      _hex(19, '临', LiuyaoTrigrams.kun, LiuyaoTrigrams.dui),
      _hex(20, '观', LiuyaoTrigrams.xun, LiuyaoTrigrams.kun),
      _hex(21, '噬嗑', LiuyaoTrigrams.li, LiuyaoTrigrams.zhen),
      _hex(22, '贲', LiuyaoTrigrams.gen, LiuyaoTrigrams.li),
      _hex(23, '剥', LiuyaoTrigrams.gen, LiuyaoTrigrams.kun),
      _hex(24, '复', LiuyaoTrigrams.kun, LiuyaoTrigrams.zhen),
      _hex(25, '无妄', LiuyaoTrigrams.qian, LiuyaoTrigrams.zhen),
      _hex(26, '大畜', LiuyaoTrigrams.gen, LiuyaoTrigrams.qian),
      _hex(27, '颐', LiuyaoTrigrams.gen, LiuyaoTrigrams.zhen),
      _hex(28, '大过', LiuyaoTrigrams.dui, LiuyaoTrigrams.xun),
      _hex(29, '坎', LiuyaoTrigrams.kan, LiuyaoTrigrams.kan),
      _hex(30, '离', LiuyaoTrigrams.li, LiuyaoTrigrams.li),
      _hex(31, '咸', LiuyaoTrigrams.dui, LiuyaoTrigrams.gen),
      _hex(32, '恒', LiuyaoTrigrams.zhen, LiuyaoTrigrams.xun),
      _hex(33, '遁', LiuyaoTrigrams.qian, LiuyaoTrigrams.gen),
      _hex(34, '大壮', LiuyaoTrigrams.zhen, LiuyaoTrigrams.qian),
      _hex(35, '晋', LiuyaoTrigrams.li, LiuyaoTrigrams.kun),
      _hex(36, '明夷', LiuyaoTrigrams.kun, LiuyaoTrigrams.li),
      _hex(37, '家人', LiuyaoTrigrams.xun, LiuyaoTrigrams.li),
      _hex(38, '睽', LiuyaoTrigrams.li, LiuyaoTrigrams.dui),
      _hex(39, '蹇', LiuyaoTrigrams.kan, LiuyaoTrigrams.gen),
      _hex(40, '解', LiuyaoTrigrams.zhen, LiuyaoTrigrams.kan),
      _hex(41, '损', LiuyaoTrigrams.gen, LiuyaoTrigrams.dui),
      _hex(42, '益', LiuyaoTrigrams.xun, LiuyaoTrigrams.zhen),
      _hex(43, '夬', LiuyaoTrigrams.dui, LiuyaoTrigrams.qian),
      _hex(44, '姤', LiuyaoTrigrams.qian, LiuyaoTrigrams.xun),
      _hex(45, '萃', LiuyaoTrigrams.dui, LiuyaoTrigrams.kun),
      _hex(46, '升', LiuyaoTrigrams.kun, LiuyaoTrigrams.xun),
      _hex(47, '困', LiuyaoTrigrams.dui, LiuyaoTrigrams.kan),
      _hex(48, '井', LiuyaoTrigrams.kan, LiuyaoTrigrams.xun),
      _hex(49, '革', LiuyaoTrigrams.dui, LiuyaoTrigrams.li),
      _hex(50, '鼎', LiuyaoTrigrams.li, LiuyaoTrigrams.xun),
      _hex(51, '震', LiuyaoTrigrams.zhen, LiuyaoTrigrams.zhen),
      _hex(52, '艮', LiuyaoTrigrams.gen, LiuyaoTrigrams.gen),
      _hex(53, '渐', LiuyaoTrigrams.xun, LiuyaoTrigrams.gen),
      _hex(54, '归妹', LiuyaoTrigrams.zhen, LiuyaoTrigrams.dui),
      _hex(55, '丰', LiuyaoTrigrams.zhen, LiuyaoTrigrams.li),
      _hex(56, '旅', LiuyaoTrigrams.li, LiuyaoTrigrams.gen),
      _hex(57, '巽', LiuyaoTrigrams.xun, LiuyaoTrigrams.xun),
      _hex(58, '兑', LiuyaoTrigrams.dui, LiuyaoTrigrams.dui),
      _hex(59, '涣', LiuyaoTrigrams.xun, LiuyaoTrigrams.kan),
      _hex(60, '节', LiuyaoTrigrams.kan, LiuyaoTrigrams.dui),
      _hex(61, '中孚', LiuyaoTrigrams.xun, LiuyaoTrigrams.dui),
      _hex(62, '小过', LiuyaoTrigrams.zhen, LiuyaoTrigrams.gen),
      _hex(63, '既济', LiuyaoTrigrams.kan, LiuyaoTrigrams.li),
      _hex(64, '未济', LiuyaoTrigrams.li, LiuyaoTrigrams.kan),
    ],
  );

  static LiuyaoHexagram resolve(
    Iterable<LiuyaoLine> lines, {
    bool changed = false,
  }) {
    final values = List<LiuyaoLine>.of(lines);
    if (values.length != LiuyaoReading.lineCapacity) {
      throw ArgumentError('A hexagram requires exactly six lines.');
    }
    for (var index = 0; index < values.length; index++) {
      if (values[index].index != index) {
        throw ArgumentError('Hexagram lines must use contiguous indexes.');
      }
    }
    int encode(LiuyaoLine line) {
      final nature = changed ? line.changedNature : line.nature;
      return nature == LiuyaoLineNature.yang ? 1 : 0;
    }

    final lower = LiuyaoTrigrams.fromLines(values.take(3).map(encode));
    final upper = LiuyaoTrigrams.fromLines(values.skip(3).map(encode));
    return fromTrigrams(upper: upper, lower: lower);
  }

  static LiuyaoHexagram fromTrigrams({
    required LiuyaoTrigram upper,
    required LiuyaoTrigram lower,
  }) {
    for (final hexagram in all) {
      if (hexagram.upper.id == upper.id && hexagram.lower.id == lower.id) {
        return hexagram;
      }
    }
    throw StateError('The explicit King Wen mapping is incomplete.');
  }

  static LiuyaoHexagram byNumber(int number) {
    if (number < 1 || number > all.length) {
      throw RangeError.range(number, 1, all.length, 'number');
    }
    return all[number - 1];
  }

  static LiuyaoHexagram byId(String id) {
    for (final hexagram in all) {
      if (hexagram.id == id) return hexagram;
    }
    throw ArgumentError.value(id, 'id', 'Unknown hexagram id.');
  }

  static LiuyaoHexagram _hex(
    int number,
    String name,
    LiuyaoTrigram upper,
    LiuyaoTrigram lower,
  ) => LiuyaoHexagram(
    id: 'hexagram.${number.toString().padLeft(2, '0')}',
    kingWenNumber: number,
    name: name,
    upper: upper,
    lower: lower,
  );
}
