import 'dart:collection';

enum CoinTossMode { single, batch }

enum CoinSide { heads, tails }

enum CoinStopReason { configuredCountReached, raceTargetReached }

final class CoinTossConfig {
  const CoinTossConfig({
    this.mode = CoinTossMode.single,
    this.batchCount = 3,
    this.headsLabel = '正面',
    this.tailsLabel = '反面',
    this.raceTarget,
  });

  static const minimumCount = 1;
  static const maximumCount = 100;

  final CoinTossMode mode;
  final int batchCount;
  final String headsLabel;
  final String tailsLabel;
  final int? raceTarget;

  String get normalizedHeadsLabel => headsLabel.trim();

  String get normalizedTailsLabel => tailsLabel.trim();

  bool get isRace => mode == CoinTossMode.batch && raceTarget != null;

  int get maximumTosses {
    if (mode == CoinTossMode.single) return 1;
    if (raceTarget case final target?) return target * 2 - 1;
    return batchCount;
  }

  String labelFor(CoinSide side) => switch (side) {
    CoinSide.heads => normalizedHeadsLabel,
    CoinSide.tails => normalizedTailsLabel,
  };

  CoinTossConfig normalized() => CoinTossConfig(
    mode: mode,
    batchCount: batchCount,
    headsLabel: normalizedHeadsLabel,
    tailsLabel: normalizedTailsLabel,
    raceTarget: raceTarget,
  );

  List<String> validate() {
    final errors = <String>[];
    if (batchCount < minimumCount || batchCount > maximumCount) {
      errors.add('批量次数必须是 1～100 的整数。');
    }
    if (normalizedHeadsLabel.isEmpty || normalizedTailsLabel.isEmpty) {
      errors.add('正面与反面标签去除首尾空格后均不能为空。');
    } else if (normalizedHeadsLabel == normalizedTailsLabel) {
      errors.add('两个标签不能相同。');
    }
    if (mode == CoinTossMode.single && raceTarget != null) {
      errors.add('单次模式不能启用率先达到。');
    }
    if (raceTarget case final target?) {
      if (target < minimumCount || target > maximumCount) {
        errors.add('率先达到次数必须是 1～100 的整数。');
      }
    }
    return List<String>.unmodifiable(errors);
  }
}

final class CoinTossResult {
  CoinTossResult({
    required this.config,
    required List<CoinSide> sequence,
    required this.stopReason,
    this.winner,
  }) : sequence = UnmodifiableListView<CoinSide>(List<CoinSide>.of(sequence));

  final CoinTossConfig config;
  final List<CoinSide> sequence;
  final CoinStopReason stopReason;
  final CoinSide? winner;

  int get tossCount => sequence.length;

  int get headsCount => sequence.where((side) => side == CoinSide.heads).length;

  int get tailsCount => tossCount - headsCount;

  double get headsRatio => headsCount / tossCount;

  double get tailsRatio => tailsCount / tossCount;
}

final class CoinValidationException implements Exception {
  CoinValidationException(Iterable<String> errors)
    : errors = List<String>.unmodifiable(errors);

  final List<String> errors;
}
