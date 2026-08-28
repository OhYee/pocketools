import 'dart:collection';

enum DiceAggregation { sum, keepHighest, keepLowest }

enum DiceMode { normal, advantage, disadvantage, custom }

enum DcOutcome { reached, notReached }

final class DicePoolConfig {
  const DicePoolConfig({
    required this.diceCount,
    required this.diceSides,
    required this.aggregation,
    this.keepCount,
    this.modifier = 0,
    this.dc,
  });

  factory DicePoolConfig.normal({int modifier = 0, int? dc}) => DicePoolConfig(
    diceCount: 1,
    diceSides: 20,
    aggregation: DiceAggregation.sum,
    modifier: modifier,
    dc: dc,
  );

  factory DicePoolConfig.advantage({int modifier = 0, int? dc}) =>
      DicePoolConfig(
        diceCount: 2,
        diceSides: 20,
        aggregation: DiceAggregation.keepHighest,
        keepCount: 1,
        modifier: modifier,
        dc: dc,
      );

  factory DicePoolConfig.disadvantage({int modifier = 0, int? dc}) =>
      DicePoolConfig(
        diceCount: 2,
        diceSides: 20,
        aggregation: DiceAggregation.keepLowest,
        keepCount: 1,
        modifier: modifier,
        dc: dc,
      );

  final int diceCount;
  final int diceSides;
  final DiceAggregation aggregation;
  final int? keepCount;
  final int modifier;
  final int? dc;

  static const minimumModifier = -9999;
  static const maximumModifier = 9999;

  DiceMode get mode {
    if (diceCount == 1 &&
        diceSides == 20 &&
        aggregation == DiceAggregation.sum) {
      return DiceMode.normal;
    }
    if (diceCount == 2 &&
        diceSides == 20 &&
        aggregation == DiceAggregation.keepHighest &&
        keepCount == 1) {
      return DiceMode.advantage;
    }
    if (diceCount == 2 &&
        diceSides == 20 &&
        aggregation == DiceAggregation.keepLowest &&
        keepCount == 1) {
      return DiceMode.disadvantage;
    }
    return DiceMode.custom;
  }

  List<String> validate() {
    final errors = <String>[];
    if (diceCount < 1 || diceCount > 20) {
      errors.add('骰子数量必须是 1～20 的整数。');
    }
    if (diceSides < 2 || diceSides > 1000) {
      errors.add('骰子面数必须是 2～1000 的整数。');
    }
    if (aggregation == DiceAggregation.sum) {
      if (keepCount != null) {
        errors.add('全部求和时不应设置保留数量。');
      }
    } else if (keepCount == null || keepCount! < 1 || keepCount! > diceCount) {
      errors.add('保留数量必须是 1～骰子数量的整数。');
    }
    if (modifier < minimumModifier || modifier > maximumModifier) {
      errors.add('修正值必须在 -9999～9999 范围内。');
    }
    return List<String>.unmodifiable(errors);
  }
}

final class DiceRoll {
  const DiceRoll({
    required this.index,
    required this.value,
    required this.isKept,
  });

  final int index;
  final int value;
  final bool isKept;
}

final class DicePoolResult {
  DicePoolResult({
    required this.config,
    required List<DiceRoll> rolls,
    required List<DiceRoll> keptInAggregationOrder,
    required this.total,
  }) : rolls = UnmodifiableListView(List<DiceRoll>.of(rolls)),
       keptInAggregationOrder = UnmodifiableListView(
         List<DiceRoll>.of(keptInAggregationOrder),
       );

  final DicePoolConfig config;
  final List<DiceRoll> rolls;
  final List<DiceRoll> keptInAggregationOrder;
  final int total;

  DcOutcome? get dcOutcome => config.dc == null
      ? null
      : total >= config.dc!
      ? DcOutcome.reached
      : DcOutcome.notReached;
}

final class DiceValidationException implements Exception {
  DiceValidationException(Iterable<String> errors)
    : errors = List<String>.unmodifiable(errors);

  final List<String> errors;

  @override
  String toString() => 'Invalid dice configuration: ${errors.join(' ')}';
}
