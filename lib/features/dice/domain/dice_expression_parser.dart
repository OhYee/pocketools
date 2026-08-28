import 'dice_models.dart';

/// Pure Dart parser for the deliberately small, non-evaluated D20 grammar.
///
/// Accepted forms are `NdS`, `NdS+M`, `NdS-M`, `NdSkhK+M`, and
/// `NdSklK+M`. The `d`, `kh`, and `kl` operators are case-insensitive. No
/// whitespace, variables, functions, nesting, or exploding-dice syntax is
/// accepted.
final class DiceExpressionParser {
  const DiceExpressionParser();

  static const int maximumExpressionLength = 64;
  static const int minimumModifier = -9999;
  static const int maximumModifier = 9999;

  static final RegExp _grammar = RegExp(
    r'^([0-9]+)[dD]([0-9]+)(?:(kh|kl)([0-9]+))?([+-][0-9]+)?$',
    caseSensitive: false,
  );
  static final RegExp _whitespace = RegExp(r'\s');

  DiceExpressionParseResult parse(String expression) {
    if (expression.isEmpty) {
      return const DiceExpressionParseResult.failure('请输入骰子表达式。');
    }
    if (expression.length > maximumExpressionLength) {
      return const DiceExpressionParseResult.failure('表达式过长。');
    }
    if (_whitespace.hasMatch(expression)) {
      return const DiceExpressionParseResult.failure('表达式不允许空白字符。');
    }

    final match = _grammar.firstMatch(expression);
    if (match == null) {
      return const DiceExpressionParseResult.failure(
        '只支持 NdS、NdS±M、NdSkhK±M 或 NdSklK±M。',
      );
    }

    final diceCount = _parseBounded(match.group(1)!, 1, 20);
    if (diceCount == null) return _failureFor('骰子数量必须是 1～20 的整数。');
    final diceSides = _parseBounded(match.group(2)!, 2, 1000);
    if (diceSides == null) return _failureFor('骰子面数必须是 2～1000 的整数。');

    final operation = match.group(3)?.toLowerCase();
    final rawKeepCount = match.group(4);
    final keepCount = rawKeepCount == null
        ? null
        : _parseBounded(rawKeepCount, 1, diceCount);
    if (rawKeepCount != null && keepCount == null) {
      return _failureFor('保留数量必须是 1～骰子数量的整数。');
    }
    if (operation == null && rawKeepCount != null) {
      return _failureFor('表达式的保留数量缺少 kh 或 kl。');
    }

    final modifierToken = match.group(5);
    final modifier = modifierToken == null
        ? 0
        : _parseModifier(
            modifierToken.substring(1),
            negative: modifierToken.startsWith('-'),
          );
    if (modifier == null) {
      return _failureFor('修正值必须在 -9999～9999 范围内。');
    }

    final aggregation = switch (operation) {
      null => DiceAggregation.sum,
      'kh' => DiceAggregation.keepHighest,
      'kl' => DiceAggregation.keepLowest,
      _ => throw StateError('The expression grammar returned an unknown op.'),
    };
    final config = DicePoolConfig(
      diceCount: diceCount,
      diceSides: diceSides,
      aggregation: aggregation,
      keepCount: keepCount,
      modifier: modifier,
    );
    final errors = config.validate();
    if (errors.isNotEmpty) return _failureFor(errors.first);

    final normalizedModifier = modifierToken == null
        ? ''
        : '${modifierToken.substring(0, 1)}${modifier.abs()}';
    var normalized = '${diceCount}d$diceSides';
    if (operation != null) normalized += '$operation$keepCount';
    normalized += normalizedModifier;
    return DiceExpressionParseResult.success(
      config: config,
      normalizedExpression: normalized,
    );
  }

  DiceExpressionParseResult _failureFor(String message) =>
      DiceExpressionParseResult.failure(message);

  int? _parseBounded(String token, int minimum, int maximum) {
    final value = int.tryParse(token);
    if (value == null || value < minimum || value > maximum) return null;
    return value;
  }

  int? _parseModifier(String token, {required bool negative}) {
    final value = int.tryParse(token);
    if (value == null || value > maximumModifier) return null;
    final signed = negative ? -value : value;
    if (signed < minimumModifier || signed > maximumModifier) return null;
    return signed;
  }
}

final class DiceExpressionParseResult {
  const DiceExpressionParseResult.success({
    required this.config,
    required this.normalizedExpression,
  }) : error = null;

  const DiceExpressionParseResult.failure(this.error)
    : config = null,
      normalizedExpression = null;

  final DicePoolConfig? config;
  final String? normalizedExpression;
  final String? error;

  bool get isValid => config != null && error == null;
}
