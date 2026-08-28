import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/features/dice/domain/dice_expression_parser.dart';
import 'package:pocketools/features/dice/domain/dice_models.dart';

void main() {
  const parser = DiceExpressionParser();

  group('independent D20 expression attacks', () {
    test('accepted grammar maps to the same structured mode boundaries', () {
      final cases = <String, ({DiceMode mode, String normalized})>{
        '1D20': (mode: DiceMode.normal, normalized: '1d20'),
        '2d20kH1+0005': (mode: DiceMode.advantage, normalized: '2d20kh1+5'),
        '2D20Kl1-0005': (mode: DiceMode.disadvantage, normalized: '2d20kl1-5'),
        '20D1000KL20-9999': (
          mode: DiceMode.custom,
          normalized: '20d1000kl20-9999',
        ),
      };

      for (final entry in cases.entries) {
        final result = parser.parse(entry.key);
        expect(result.isValid, isTrue, reason: entry.key);
        expect(result.config?.mode, entry.value.mode, reason: entry.key);
        expect(
          result.normalizedExpression,
          entry.value.normalized,
          reason: entry.key,
        );
      }
    });

    test('huge integers Unicode and controls fail without coercion', () {
      final huge = List<String>.filled(60, '9').join();
      for (final expression in <String>[
        '${huge}d20',
        '1d$huge',
        '1d20+$huge',
        '1d20-$huge',
        '１d20',
        '١d20',
        '1d20\u0000',
        '1d20\u001f',
        '1d20\u007f',
        '1d20\u00a0',
        '1d20\u2009',
        '1d20\u200b',
        '1d20\u202e',
        '1d20\u3000',
      ]) {
        final result = parser.parse(expression);
        expect(result.isValid, isFalse, reason: _escaped(expression));
        expect(result.config, isNull, reason: _escaped(expression));
      }
    });

    test('kh and kl ambiguity and modifier overflow stay rejected', () {
      for (final expression in <String>[
        '2d20kh',
        '2d20kl',
        '2d20kh1kl1',
        '2d20kl1kh1',
        '2d20k1',
        '2d20hl1',
        '2d20kh+1',
        '2d20kl-1',
        '2d20kh0',
        '2d20kl3',
        '1d20+10000',
        '1d20-10000',
        '1d20+-1',
        '1d20--1',
      ]) {
        expect(parser.parse(expression).isValid, isFalse, reason: expression);
      }
    });
  });
}

String _escaped(String value) => value.runes
    .map(
      (rune) => rune < 0x20 || rune > 0x7e
          ? '\\u{${rune.toRadixString(16)}}'
          : String.fromCharCode(rune),
    )
    .join();
