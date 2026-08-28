import '../../../core/session/session.dart';
import '../domain/coin_models.dart';
import 'coin_labels.dart';

final class CoinSessionCodec implements ToolSessionCodec {
  const CoinSessionCodec();

  @override
  String get toolId => 'coin';

  @override
  Map<String, Object?> encodeInput(Object input) {
    if (input is! CoinTossConfig) {
      throw const FormatException('Coin input must be a CoinTossConfig.');
    }
    final config = _validatedConfig(input, source: 'Coin input').normalized();
    return <String, Object?>{
      'mode': config.mode.name,
      'batchCount': config.batchCount,
      'headsLabel': config.headsLabel,
      'tailsLabel': config.tailsLabel,
      'raceTarget': config.raceTarget,
    };
  }

  @override
  CoinTossConfig decodeInput(Map<String, Object?> input) {
    final modeName = _requiredString(input, 'mode', source: 'Coin input');
    late final CoinTossMode mode;
    try {
      mode = CoinTossMode.values.byName(modeName);
    } on ArgumentError {
      throw FormatException('Coin input mode is invalid: $modeName.');
    }
    final config = CoinTossConfig(
      mode: mode,
      batchCount: _requiredInt(input, 'batchCount', source: 'Coin input'),
      headsLabel: _requiredString(input, 'headsLabel', source: 'Coin input'),
      tailsLabel: _requiredString(input, 'tailsLabel', source: 'Coin input'),
      raceTarget: _nullableInt(input, 'raceTarget', source: 'Coin input'),
    );
    return _validatedConfig(config, source: 'Coin input').normalized();
  }

  @override
  Map<String, Object?> encodeOutcome(Object outcome) {
    if (outcome is! CoinTossResult) {
      throw const FormatException('Coin outcome must be a CoinTossResult.');
    }
    final encoded = <String, Object?>{
      'sequence': outcome.sequence.map(coinRawSideId).toList(growable: false),
      'headsCount': outcome.headsCount,
      'tailsCount': outcome.tailsCount,
      'stopReason': outcome.stopReason.name,
      'winner': outcome.winner?.name,
    };
    _decodeAndValidateOutcome(encoded, outcome.config);
    return encoded;
  }

  @override
  CoinTossResult decodeOutcome(Map<String, Object?> outcome, Object input) {
    if (input is! CoinTossConfig) {
      throw const FormatException(
        'Coin outcome requires a decoded CoinTossConfig input.',
      );
    }
    return _decodeAndValidateOutcome(outcome, input);
  }

  CoinTossResult _decodeAndValidateOutcome(
    Map<String, Object?> outcome,
    CoinTossConfig input,
  ) {
    final config = _validatedConfig(
      input,
      source: 'Coin outcome input',
    ).normalized();
    final rawSequence = outcome['sequence'];
    if (rawSequence is! List || rawSequence.isEmpty) {
      throw const FormatException(
        'Coin outcome sequence must be a non-empty list.',
      );
    }
    final sequence = <CoinSide>[];
    for (var index = 0; index < rawSequence.length; index++) {
      final rawSide = rawSequence[index];
      if (rawSide is! String) {
        throw FormatException(
          'Coin outcome sequence[$index] must be heads or tails.',
        );
      }
      try {
        sequence.add(CoinSide.values.byName(rawSide));
      } on ArgumentError {
        throw FormatException(
          'Coin outcome sequence[$index] is invalid: $rawSide.',
        );
      }
    }

    final headsCount = sequence.where((side) => side == CoinSide.heads).length;
    final tailsCount = sequence.length - headsCount;
    _requireEqualCount(outcome, 'headsCount', headsCount);
    _requireEqualCount(outcome, 'tailsCount', tailsCount);

    final stopReasonName = _requiredString(
      outcome,
      'stopReason',
      source: 'Coin outcome',
    );
    late final CoinStopReason stopReason;
    try {
      stopReason = CoinStopReason.values.byName(stopReasonName);
    } on ArgumentError {
      throw FormatException(
        'Coin outcome stopReason is invalid: $stopReasonName.',
      );
    }
    final winner = _nullableSide(outcome, 'winner');

    if (!config.isRace) {
      final expectedCount = config.mode == CoinTossMode.single
          ? 1
          : config.batchCount;
      if (sequence.length != expectedCount) {
        throw FormatException(
          'Coin outcome must contain exactly $expectedCount tosses; '
          'got ${sequence.length}.',
        );
      }
      if (stopReason != CoinStopReason.configuredCountReached ||
          winner != null) {
        throw const FormatException(
          'Non-race coin outcome must stop at configured count without winner.',
        );
      }
    } else {
      final target = config.raceTarget!;
      if (sequence.length > config.maximumTosses) {
        throw FormatException(
          'Race coin outcome cannot exceed ${config.maximumTosses} tosses.',
        );
      }
      var runningHeads = 0;
      var runningTails = 0;
      for (var index = 0; index < sequence.length; index++) {
        if (sequence[index] == CoinSide.heads) {
          runningHeads++;
        } else {
          runningTails++;
        }
        if (index < sequence.length - 1 &&
            (runningHeads >= target || runningTails >= target)) {
          throw FormatException(
            'Race coin outcome continued after reaching target at toss '
            '${index + 1}.',
          );
        }
      }
      final expectedWinner = runningHeads == target
          ? CoinSide.heads
          : runningTails == target
          ? CoinSide.tails
          : null;
      if (expectedWinner == null ||
          stopReason != CoinStopReason.raceTargetReached ||
          winner != expectedWinner) {
        throw const FormatException(
          'Race coin outcome must stop exactly when its winner reaches target.',
        );
      }
    }

    return CoinTossResult(
      config: config,
      sequence: sequence,
      stopReason: stopReason,
      winner: winner,
    );
  }

  CoinTossConfig _validatedConfig(
    CoinTossConfig config, {
    required String source,
  }) {
    final errors = config.validate();
    if (errors.isNotEmpty) {
      throw FormatException('$source is invalid: ${errors.join(' ')}');
    }
    return config;
  }

  void _requireEqualCount(
    Map<String, Object?> outcome,
    String key,
    int expected,
  ) {
    final actual = _requiredInt(outcome, key, source: 'Coin outcome');
    if (actual != expected) {
      throw FormatException(
        'Coin outcome $key must be $expected; got $actual.',
      );
    }
  }

  CoinSide? _nullableSide(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('Coin outcome $key must be heads, tails, or null.');
    }
    try {
      return CoinSide.values.byName(value);
    } on ArgumentError {
      throw FormatException('Coin outcome $key is invalid: $value.');
    }
  }

  int _requiredInt(
    Map<String, Object?> payload,
    String key, {
    required String source,
  }) {
    final value = payload[key];
    if (value is! int) {
      throw FormatException('$source $key must be an integer.');
    }
    return value;
  }

  int? _nullableInt(
    Map<String, Object?> payload,
    String key, {
    required String source,
  }) {
    final value = payload[key];
    if (value == null) return null;
    if (value is! int) {
      throw FormatException('$source $key must be an integer or null.');
    }
    return value;
  }

  String _requiredString(
    Map<String, Object?> payload,
    String key, {
    required String source,
  }) {
    final value = payload[key];
    if (value is! String) {
      throw FormatException('$source $key must be a string.');
    }
    return value;
  }

  @override
  String summarize(SessionRecord session) {
    final config = decodeInput(session.input);
    final result = decodeOutcome(session.outcome, config);
    final sequence = result.sequence.map(coinRawSideId).join(',');
    return '硬币 · 共抛 ${result.tossCount} 次 · '
        '${config.headsLabel} ${result.headsCount} / '
        '${config.tailsLabel} ${result.tailsCount} · '
        '序列 $sequence · ${coinStopReasonLabel(result)} · '
        '规则 ${session.ruleVersion} · 算法 ${session.algorithmVersion}';
  }
}
