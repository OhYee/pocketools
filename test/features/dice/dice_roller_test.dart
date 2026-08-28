import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/features/dice/domain/dice_models.dart';
import 'package:pocketools/features/dice/domain/dice_roller.dart';

void main() {
  group('D20 presets and validation', () {
    test('maps normal, advantage, disadvantage, and custom modes', () {
      expect(DicePoolConfig.normal().mode, DiceMode.normal);
      expect(DicePoolConfig.advantage().mode, DiceMode.advantage);
      expect(DicePoolConfig.disadvantage().mode, DiceMode.disadvantage);
      expect(
        const DicePoolConfig(
          diceCount: 2,
          diceSides: 20,
          aggregation: DiceAggregation.sum,
        ).mode,
        DiceMode.custom,
      );
    });

    test('accepts all specified boundaries', () {
      expect(
        const DicePoolConfig(
          diceCount: 1,
          diceSides: 2,
          aggregation: DiceAggregation.keepHighest,
          keepCount: 1,
        ).validate(),
        isEmpty,
      );
      expect(
        const DicePoolConfig(
          diceCount: 20,
          diceSides: 1000,
          aggregation: DiceAggregation.keepLowest,
          keepCount: 20,
        ).validate(),
        isEmpty,
      );
    });

    test('rejects count, sides, and K outside their boundaries', () {
      expect(
        const DicePoolConfig(
          diceCount: 0,
          diceSides: 1,
          aggregation: DiceAggregation.keepHighest,
          keepCount: 0,
        ).validate(),
        hasLength(3),
      );
      expect(
        const DicePoolConfig(
          diceCount: 21,
          diceSides: 1001,
          aggregation: DiceAggregation.keepLowest,
          keepCount: 22,
        ).validate(),
        hasLength(3),
      );
    });

    test('rejects sum with K and keep modes without a legal K', () {
      expect(
        const DicePoolConfig(
          diceCount: 2,
          diceSides: 20,
          aggregation: DiceAggregation.sum,
          keepCount: 1,
        ).validate(),
        isNotEmpty,
      );
      expect(
        const DicePoolConfig(
          diceCount: 2,
          diceSides: 20,
          aggregation: DiceAggregation.keepHighest,
        ).validate(),
        isNotEmpty,
      );
      expect(
        const DicePoolConfig(
          diceCount: 2,
          diceSides: 20,
          aggregation: DiceAggregation.keepLowest,
          keepCount: 3,
        ).validate(),
        isNotEmpty,
      );
    });

    test('modifier and DC do not change the recognized preset', () {
      expect(DicePoolConfig.normal(modifier: -3, dc: 18).mode, DiceMode.normal);
      expect(
        DicePoolConfig.advantage(modifier: 4, dc: 22).mode,
        DiceMode.advantage,
      );
      expect(
        DicePoolConfig.disadvantage(modifier: 0, dc: -1).mode,
        DiceMode.disadvantage,
      );
    });
  });

  test('fixed vector keeps stable indexes and totals 41', () {
    final result = DiceRoller(SequenceRandomSource(<int>[7, 15, 3, 11])).roll(
      const DicePoolConfig(
        diceCount: 4,
        diceSides: 20,
        aggregation: DiceAggregation.keepHighest,
        keepCount: 3,
        modifier: 5,
        dc: 35,
      ),
    );

    expect(result.rolls.map((roll) => roll.value), <int>[8, 16, 4, 12]);
    expect(
      result.rolls.where((roll) => roll.isKept).map((roll) => roll.index),
      <int>[1, 2, 4],
    );
    expect(result.keptInAggregationOrder.map((roll) => roll.value), <int>[
      16,
      12,
      8,
    ]);
    expect(result.total, 41);
    expect(result.dcOutcome, DcOutcome.reached);
    expect(() => result.rolls.clear(), throwsUnsupportedError);
  });

  test('equal values prefer the earlier generation index', () {
    final result = DiceRoller(SequenceRandomSource(<int>[9, 9, 8])).roll(
      const DicePoolConfig(
        diceCount: 3,
        diceSides: 20,
        aggregation: DiceAggregation.keepHighest,
        keepCount: 1,
      ),
    );

    expect(result.rolls.map((roll) => roll.isKept), <bool>[true, false, false]);
  });

  test('ties are stable for both highest and lowest aggregation', () {
    const highestConfig = DicePoolConfig(
      diceCount: 4,
      diceSides: 20,
      aggregation: DiceAggregation.keepHighest,
      keepCount: 2,
    );
    const lowestConfig = DicePoolConfig(
      diceCount: 4,
      diceSides: 20,
      aggregation: DiceAggregation.keepLowest,
      keepCount: 2,
    );
    final highest = DiceRoller(SequenceRandomSource(<int>[4, 4, 1, 4]))
        .roll(highestConfig);
    final lowest = DiceRoller(SequenceRandomSource(<int>[4, 4, 1, 4]))
        .roll(lowestConfig);

    expect(
      highest.rolls.where((roll) => roll.isKept).map((roll) => roll.index),
      <int>[1, 2],
    );
    expect(
      lowest.rolls.where((roll) => roll.isKept).map((roll) => roll.index),
      <int>[1, 3],
    );
    expect(lowest.keptInAggregationOrder.map((roll) => roll.index), <int>[
      3,
      1,
    ]);
  });

  test('K equal to diceCount matches sum for both keep modes', () {
    const values = <int>[1, 4, 2, 3];
    DicePoolResult roll(DiceAggregation aggregation, {int? keepCount}) =>
        DiceRoller(SequenceRandomSource(values)).roll(
          DicePoolConfig(
            diceCount: values.length,
            diceSides: 6,
            aggregation: aggregation,
            keepCount: keepCount,
            modifier: -2,
            dc: 10,
          ),
        );

    final sum = roll(DiceAggregation.sum);
    final highest = roll(DiceAggregation.keepHighest, keepCount: values.length);
    final lowest = roll(DiceAggregation.keepLowest, keepCount: values.length);

    expect(highest.total, sum.total);
    expect(lowest.total, sum.total);
    expect(highest.rolls.every((roll) => roll.isKept), isTrue);
    expect(lowest.rolls.every((roll) => roll.isKept), isTrue);
    expect(highest.dcOutcome, sum.dcOutcome);
    expect(lowest.dcOutcome, sum.dcOutcome);
  });

  test('supports 20 D1000 dice and preserves every roll', () {
    final result = DiceRoller(SequenceRandomSource(List<int>.filled(20, 999)))
        .roll(
          const DicePoolConfig(
            diceCount: 20,
            diceSides: 1000,
            aggregation: DiceAggregation.sum,
            modifier: -1,
          ),
        );

    expect(result.rolls, hasLength(20));
    expect(result.rolls.every((roll) => roll.value == 1000), isTrue);
    expect(result.rolls.every((roll) => roll.isKept), isTrue);
    expect(result.total, 19999);
  });

  test('invalid input is rejected before randomness is consumed', () {
    final random = _RecordingRandomSource(const <int>[0]);
    final roller = DiceRoller(random);

    expect(
      () => roller.roll(
        const DicePoolConfig(
          diceCount: 21,
          diceSides: 20,
          aggregation: DiceAggregation.sum,
        ),
      ),
      throwsA(isA<DiceValidationException>()),
    );
    expect(random.consumed, 0);
  });

  test('random failure exposes no partial result', () {
    final random = _ThrowingRandomSource(throwAfter: 2);

    expect(
      () => DiceRoller(random).roll(
        const DicePoolConfig(
          diceCount: 4,
          diceSides: 20,
          aggregation: DiceAggregation.sum,
        ),
      ),
      throwsStateError,
    );
    expect(random.consumed, 2);
  });

  test('natural 1 and 20 have no implicit success rule', () {
    final result = DiceRoller(SequenceRandomSource(<int>[0, 19])).roll(
      const DicePoolConfig(
        diceCount: 2,
        diceSides: 20,
        aggregation: DiceAggregation.sum,
        dc: 22,
      ),
    );

    expect(result.total, 21);
    expect(result.dcOutcome, DcOutcome.notReached);
  });

  test('natural values follow only the configured total versus DC', () {
    final naturalOne = DiceRoller(SequenceRandomSource(<int>[0])).roll(
      const DicePoolConfig(
        diceCount: 1,
        diceSides: 20,
        aggregation: DiceAggregation.sum,
        dc: 1,
      ),
    );
    final naturalTwenty = DiceRoller(SequenceRandomSource(<int>[19])).roll(
      const DicePoolConfig(
        diceCount: 1,
        diceSides: 20,
        aggregation: DiceAggregation.sum,
        dc: 21,
      ),
    );

    expect(naturalOne.dcOutcome, DcOutcome.reached);
    expect(naturalTwenty.dcOutcome, DcOutcome.notReached);
  });
}

final class _RecordingRandomSource implements RandomSource {
  _RecordingRandomSource(this._values);

  final List<int> _values;
  var consumed = 0;

  @override
  int nextInt(int maxExclusive) => _values[consumed++];
}

final class _ThrowingRandomSource implements RandomSource {
  _ThrowingRandomSource({required this.throwAfter});

  final int throwAfter;
  var consumed = 0;

  @override
  int nextInt(int maxExclusive) {
    if (consumed == throwAfter) throw StateError('Random source failed.');
    consumed++;
    return 0;
  }
}
