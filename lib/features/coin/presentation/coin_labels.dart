import '../domain/coin_models.dart';

String coinRawSideId(CoinSide side) => side.name;

String coinOriginalSideLabel(CoinSide side) => switch (side) {
  CoinSide.heads => '正面',
  CoinSide.tails => '反面',
};

String coinDisplayedSideLabel(CoinTossConfig config, CoinSide side) =>
    config.labelFor(side);

String coinStopReasonLabel(CoinTossResult result) {
  if (result.stopReason == CoinStopReason.configuredCountReached) {
    return result.config.mode == CoinTossMode.single
        ? '完成单次抛掷'
        : '已完成配置的 ${result.config.batchCount} 次';
  }
  final winner = result.winner!;
  return '${result.config.labelFor(winner)}率先达到 '
      '${result.config.raceTarget} 次，共抛 ${result.tossCount} 次';
}

String coinSequenceLabel(CoinTossResult result) => result.sequence.indexed
    .map(
      (entry) =>
          '#${entry.$1 + 1} ${result.config.labelFor(entry.$2)}'
          '（${coinRawSideId(entry.$2)}）',
    )
    .join('、');
