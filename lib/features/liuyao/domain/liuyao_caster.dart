import '../../../core/random/random_source.dart';
import 'liuyao_models.dart';

final class LiuyaoCaster {
  const LiuyaoCaster(this._randomSource);

  static const ruleVersion = 'liuyao-three-coin-v1';
  static const automaticAlgorithmVersion = 'unbiased-three-binary-draws-v1';
  static const manualAlgorithmVersion = 'validated-manual-line-values-v1';

  final RandomSource _randomSource;

  LiuyaoReading appendAutomaticLine(LiuyaoReading reading) {
    _validateForAppend(reading, LiuyaoMode.automatic);
    final coins = List<LiuyaoCoinSide>.generate(
      3,
      (_) => _randomSource.nextInt(2) == 0
          ? LiuyaoCoinSide.heads
          : LiuyaoCoinSide.tails,
      growable: false,
    );
    final value = coins.fold<int>(0, (total, side) => total + side.points);
    return reading.append(
      LiuyaoLine(
        index: reading.nextLineIndex,
        value: value,
        source: LiuyaoLineSource.automaticCoins,
        coins: coins,
      ),
    );
  }

  LiuyaoReading appendManualLine(LiuyaoReading reading, int value) {
    _validateForAppend(reading, LiuyaoMode.manual);
    LiuyaoLineKind.fromValue(value);
    return reading.append(
      LiuyaoLine(
        index: reading.nextLineIndex,
        value: value,
        source: LiuyaoLineSource.manualValue,
      ),
    );
  }

  void _validateForAppend(LiuyaoReading reading, LiuyaoMode expectedMode) {
    final errors = reading.config.validate();
    if (errors.isNotEmpty) throw ArgumentError(errors.join(' '));
    if (reading.config.mode != expectedMode) {
      throw ArgumentError(
        'Reading mode does not match the requested operation.',
      );
    }
    if (reading.isComplete) {
      throw StateError('A completed Liuyao reading is immutable.');
    }
  }
}
