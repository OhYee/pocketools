import '../../../core/random/random_source.dart';
import 'coin_models.dart';

final class CoinTosser {
  const CoinTosser(this._random);

  static const ruleVersion = 'coin/1.0.0';
  static const algorithmVersion = 'random-unbiased-binary/1.0.0';

  final RandomSource _random;

  CoinTossResult toss(CoinTossConfig config) {
    final errors = config.validate();
    if (errors.isNotEmpty) {
      throw CoinValidationException(errors);
    }

    final normalizedConfig = config.normalized();
    final sequence = <CoinSide>[];
    var headsCount = 0;
    var tailsCount = 0;
    CoinSide? winner;

    for (var index = 0; index < normalizedConfig.maximumTosses; index++) {
      final side = _random.nextInt(2) == 0 ? CoinSide.heads : CoinSide.tails;
      sequence.add(side);
      if (side == CoinSide.heads) {
        headsCount++;
      } else {
        tailsCount++;
      }

      final target = normalizedConfig.raceTarget;
      if (target != null && (headsCount == target || tailsCount == target)) {
        winner = side;
        break;
      }
    }

    return CoinTossResult(
      config: normalizedConfig,
      sequence: sequence,
      stopReason: winner == null
          ? CoinStopReason.configuredCountReached
          : CoinStopReason.raceTargetReached,
      winner: winner,
    );
  }
}
