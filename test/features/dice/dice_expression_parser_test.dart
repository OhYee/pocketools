import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/features/dice/domain/dice_expression_parser.dart';
import 'package:pocketools/features/dice/domain/dice_models.dart';

void main() {
  const parser = DiceExpressionParser();

  group('D20 expression parser', () {
    test('accepts every frozen grammar form and canonicalizes it', () {
      final cases = <String, DicePoolConfig>{
        '1d20': DicePoolConfig.normal(),
        '1D20+0': DicePoolConfig.normal(),
        '2d20+5': const DicePoolConfig(
          diceCount: 2,
          diceSides: 20,
          aggregation: DiceAggregation.sum,
          modifier: 5,
        ),
        '3d6-2': const DicePoolConfig(
          diceCount: 3,
          diceSides: 6,
          aggregation: DiceAggregation.sum,
          modifier: -2,
        ),
        '2d20kh1+5': DicePoolConfig.advantage(modifier: 5),
        '2D20KH1-0': DicePoolConfig.advantage(),
        '4d100kl2-9999': const DicePoolConfig(
          diceCount: 4,
          diceSides: 100,
          aggregation: DiceAggregation.keepLowest,
          keepCount: 2,
          modifier: -9999,
        ),
      };

      for (final entry in cases.entries) {
        final result = parser.parse(entry.key);
        expect(result.isValid, isTrue, reason: entry.key);
        expect(result.config!.diceCount, entry.value.diceCount);
        expect(result.config!.diceSides, entry.value.diceSides);
        expect(result.config!.aggregation, entry.value.aggregation);
        expect(result.config!.keepCount, entry.value.keepCount);
        expect(result.config!.modifier, entry.value.modifier);
      }
      expect(parser.parse('01d020+000').normalizedExpression, '1d20+0');
      expect(parser.parse('2D20KH01-0002').normalizedExpression, '2d20kh1-2');
    });

    test('accepts exact N, S, K and modifier boundaries', () {
      for (final expression in <String>[
        '1d2',
        '20d1000',
        '20d1000kh20+9999',
        '20d1000kl1-9999',
      ]) {
        expect(parser.parse(expression).isValid, isTrue, reason: expression);
      }
    });

    test(
      'rejects empty, whitespace, malformed, nested, and executable forms',
      () {
        for (final expression in <String>[
          '',
          ' ',
          '1 d20',
          '1d20 + 5',
          '1d20 ',
          ' 1d20',
          '0d20',
          '21d20',
          '1d1',
          '1d1001',
          '2d20kh0',
          '2d20kh3',
          '2d20kl21',
          '1d20kh1kh1',
          '1d20!!',
          '1d20e6',
          '1d20+1d4',
          '1d(20)',
          'd20',
          '1d',
          '1d20/2',
          '1d20.5',
          '1d20+10000',
          '1d20-10000',
          '1d20+9223372036854775808',
          '1d20+5\u0000',
        ]) {
          final result = parser.parse(expression);
          expect(result.isValid, isFalse, reason: expression);
          expect(result.error, isNotNull, reason: expression);
        }
      },
    );

    test('rejects overlong input before parsing', () {
      final result = parser.parse('1d20${List<String>.filled(64, '0').join()}');

      expect(result.isValid, isFalse);
      expect(result.error, contains('过长'));
    });
  });
}
