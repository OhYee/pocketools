import '../../../core/random/random_source.dart';
import 'dice_models.dart';

final class DiceRoller {
  const DiceRoller(this._random);

  static const ruleVersion = 'dice/1.0.0';
  static const algorithmVersion = 'random-unbiased-u32/1';

  final RandomSource _random;

  DicePoolResult roll(DicePoolConfig config) {
    final errors = config.validate();
    if (errors.isNotEmpty) {
      throw DiceValidationException(errors);
    }

    final values = List<int>.generate(
      config.diceCount,
      (_) => _random.nextInt(config.diceSides) + 1,
      growable: false,
    );
    final orderedIndexes = List<int>.generate(values.length, (index) => index);
    switch (config.aggregation) {
      case DiceAggregation.sum:
        break;
      case DiceAggregation.keepHighest:
        orderedIndexes.sort((left, right) {
          final byValue = values[right].compareTo(values[left]);
          return byValue != 0 ? byValue : left.compareTo(right);
        });
        break;
      case DiceAggregation.keepLowest:
        orderedIndexes.sort((left, right) {
          final byValue = values[left].compareTo(values[right]);
          return byValue != 0 ? byValue : left.compareTo(right);
        });
        break;
    }

    final keptCount = config.aggregation == DiceAggregation.sum
        ? config.diceCount
        : config.keepCount!;
    final keptIndexes = orderedIndexes.take(keptCount).toSet();
    final rolls = List<DiceRoll>.generate(
      values.length,
      (index) => DiceRoll(
        index: index + 1,
        value: values[index],
        isKept: keptIndexes.contains(index),
      ),
      growable: false,
    );
    final keptInAggregationOrder = orderedIndexes
        .take(keptCount)
        .map((index) => rolls[index])
        .toList(growable: false);
    final keptTotal = keptInAggregationOrder.fold<int>(
      0,
      (sum, roll) => sum + roll.value,
    );
    return DicePoolResult(
      config: config,
      rolls: rolls,
      keptInAggregationOrder: keptInAggregationOrder,
      total: keptTotal + config.modifier,
    );
  }
}
