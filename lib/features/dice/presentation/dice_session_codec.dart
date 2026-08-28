import '../../../core/session/session.dart';
import '../domain/dice_models.dart';

final class DiceSessionCodec implements ToolSessionCodec {
  const DiceSessionCodec();

  static const _inputKeys = <String>{
    'diceCount',
    'diceSides',
    'aggregation',
    'keepCount',
    'modifier',
    'dc',
    'mode',
  };
  static const _outcomeKeys = <String>{
    'rolls',
    'keptOrder',
    'total',
    'dcOutcome',
  };
  static const _rollKeys = <String>{'index', 'value', 'kept'};

  @override
  String get toolId => 'd20';

  @override
  Map<String, Object?> encodeInput(Object input) {
    if (input is! DicePoolConfig) {
      throw ArgumentError.value(input, 'input', 'Expected DicePoolConfig.');
    }
    final errors = input.validate();
    if (errors.isNotEmpty) throw DiceValidationException(errors);
    return <String, Object?>{
      'diceCount': input.diceCount,
      'diceSides': input.diceSides,
      'aggregation': input.aggregation.name,
      'keepCount': input.keepCount,
      'modifier': input.modifier,
      'dc': input.dc,
      'mode': input.mode.name,
    };
  }

  @override
  DicePoolConfig decodeInput(Map<String, Object?> input) {
    _requireExactKeys(input, _inputKeys, 'D20 input');
    try {
      final config = DicePoolConfig(
        diceCount: _required<int>(input, 'diceCount'),
        diceSides: _required<int>(input, 'diceSides'),
        aggregation: DiceAggregation.values.byName(
          _required<String>(input, 'aggregation'),
        ),
        keepCount: _nullable<int>(input, 'keepCount'),
        modifier: _required<int>(input, 'modifier'),
        dc: _nullable<int>(input, 'dc'),
      );
      final errors = config.validate();
      if (errors.isNotEmpty) {
        throw FormatException('Invalid D20 input: ${errors.join(' ')}');
      }
      final encodedMode = _required<String>(input, 'mode');
      if (encodedMode != config.mode.name) {
        throw FormatException(
          'D20 mode $encodedMode is inconsistent with the configuration.',
        );
      }
      return config;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invalid D20 input: $error');
    }
  }

  @override
  Map<String, Object?> encodeOutcome(Object outcome) {
    if (outcome is! DicePoolResult) {
      throw ArgumentError.value(outcome, 'outcome', 'Expected DicePoolResult.');
    }
    _validateResult(outcome);
    return <String, Object?>{
      'rolls': outcome.rolls
          .map(
            (roll) => <String, Object?>{
              'index': roll.index,
              'value': roll.value,
              'kept': roll.isKept,
            },
          )
          .toList(growable: false),
      'keptOrder': outcome.keptInAggregationOrder
          .map((roll) => roll.index)
          .toList(growable: false),
      'total': outcome.total,
      'dcOutcome': outcome.dcOutcome?.name,
    };
  }

  @override
  DicePoolResult decodeOutcome(Map<String, Object?> outcome, Object input) {
    if (input is! DicePoolConfig) {
      throw const FormatException('D20 outcome requires DicePoolConfig input.');
    }
    _requireExactKeys(outcome, _outcomeKeys, 'D20 outcome');
    try {
      final rawRolls = _required<List<Object?>>(outcome, 'rolls');
      if (rawRolls.length != input.diceCount) {
        throw FormatException(
          'D20 rolls length must equal diceCount ${input.diceCount}.',
        );
      }
      final rolls = <DiceRoll>[];
      for (var position = 0; position < rawRolls.length; position++) {
        final rawRoll = rawRolls[position];
        if (rawRoll is! Map<String, Object?>) {
          throw const FormatException('Each D20 roll must be an object.');
        }
        _requireExactKeys(rawRoll, _rollKeys, 'D20 roll');
        final index = _required<int>(rawRoll, 'index');
        final value = _required<int>(rawRoll, 'value');
        if (index != position + 1) {
          throw const FormatException(
            'D20 roll indices must preserve generation order from 1.',
          );
        }
        if (value < 1 || value > input.diceSides) {
          throw FormatException(
            'D20 roll value $value is outside 1..${input.diceSides}.',
          );
        }
        rolls.add(
          DiceRoll(
            index: index,
            value: value,
            isKept: _required<bool>(rawRoll, 'kept'),
          ),
        );
      }
      final rawKeptOrder = _required<List<Object?>>(outcome, 'keptOrder');
      if (rawKeptOrder.any((value) => value is! int)) {
        throw const FormatException('D20 keptOrder must contain integers.');
      }
      final keptOrder = rawKeptOrder.cast<int>();
      final result = DicePoolResult(
        config: input,
        rolls: rolls,
        keptInAggregationOrder: keptOrder
            .map((index) {
              if (index < 1 || index > rolls.length) {
                throw const FormatException(
                  'D20 keptOrder contains an unknown roll index.',
                );
              }
              return rolls[index - 1];
            })
            .toList(growable: false),
        total: _required<int>(outcome, 'total'),
      );
      _validateResult(result);
      final encodedDcOutcome = _nullable<String>(outcome, 'dcOutcome');
      if (encodedDcOutcome != result.dcOutcome?.name) {
        throw const FormatException(
          'D20 dcOutcome is inconsistent with total and DC.',
        );
      }
      return result;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invalid D20 outcome: $error');
    }
  }

  void _validateResult(DicePoolResult result) {
    final configErrors = result.config.validate();
    if (configErrors.isNotEmpty) {
      throw FormatException(
        'Invalid D20 result config: ${configErrors.join(' ')}',
      );
    }
    if (result.rolls.length != result.config.diceCount) {
      throw const FormatException('D20 result roll count is inconsistent.');
    }
    for (var index = 0; index < result.rolls.length; index++) {
      final roll = result.rolls[index];
      if (roll.index != index + 1 ||
          roll.value < 1 ||
          roll.value > result.config.diceSides) {
        throw const FormatException('D20 result rolls are invalid.');
      }
    }
    final expectedOrder = _expectedKeptOrder(result.config, result.rolls);
    final actualOrder = result.keptInAggregationOrder
        .map((roll) => roll.index)
        .toList(growable: false);
    if (!_sameInts(actualOrder, expectedOrder)) {
      throw const FormatException('D20 keptOrder is inconsistent with rules.');
    }
    final expectedSet = expectedOrder.toSet();
    for (final roll in result.rolls) {
      if (roll.isKept != expectedSet.contains(roll.index)) {
        throw const FormatException(
          'D20 kept flags are inconsistent with rules.',
        );
      }
    }
    final expectedTotal = result.keptInAggregationOrder.fold<int>(
      result.config.modifier,
      (total, roll) => total + roll.value,
    );
    if (result.total != expectedTotal) {
      throw const FormatException('D20 total is inconsistent with kept rolls.');
    }
  }

  List<int> _expectedKeptOrder(DicePoolConfig config, List<DiceRoll> rolls) {
    final indexes = List<int>.generate(rolls.length, (index) => index);
    switch (config.aggregation) {
      case DiceAggregation.sum:
        break;
      case DiceAggregation.keepHighest:
        indexes.sort((left, right) {
          final byValue = rolls[right].value.compareTo(rolls[left].value);
          return byValue != 0 ? byValue : left.compareTo(right);
        });
      case DiceAggregation.keepLowest:
        indexes.sort((left, right) {
          final byValue = rolls[left].value.compareTo(rolls[right].value);
          return byValue != 0 ? byValue : left.compareTo(right);
        });
    }
    final count = config.aggregation == DiceAggregation.sum
        ? config.diceCount
        : config.keepCount!;
    return indexes
        .take(count)
        .map((index) => index + 1)
        .toList(growable: false);
  }

  bool _sameInts(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  void _requireExactKeys(
    Map<String, Object?> value,
    Set<String> expected,
    String label,
  ) {
    if (value.length != expected.length ||
        !value.keys.toSet().containsAll(expected)) {
      throw FormatException('$label fields are missing or unexpected.');
    }
  }

  T _required<T>(Map<String, Object?> value, String key) {
    final item = value[key];
    if (item is! T) {
      throw FormatException('D20 field $key has an invalid type.');
    }
    return item;
  }

  T? _nullable<T>(Map<String, Object?> value, String key) {
    final item = value[key];
    if (item == null) return null;
    if (item is! T) {
      throw FormatException('D20 field $key has an invalid type.');
    }
    return item as T;
  }

  @override
  String summarize(SessionRecord session) {
    final total = session.outcome['total'];
    final mode = session.input['mode'];
    return '${_modeLabel(mode)}检定 · 总值 $total';
  }

  String _modeLabel(Object? mode) => switch (mode) {
    'normal' => '普通',
    'advantage' => '优势',
    'disadvantage' => '劣势',
    _ => '自定义',
  };
}
