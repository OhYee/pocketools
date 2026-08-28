import '../domain/tarot_models.dart';

String tarotSpreadLabel(TarotSpreadPreset spread) => switch (spread) {
  TarotSpreadPreset.dailyCard => '今日一牌',
  TarotSpreadPreset.singleQuestion => '单牌问答',
  TarotSpreadPreset.pastPresentFuture => '过去／现在／未来',
};

String tarotPositionLabel(TarotPosition position) => switch (position) {
  TarotPosition.dailyGuidance => '今日提示',
  TarotPosition.coreMessage => '核心信息',
  TarotPosition.past => '过去',
  TarotPosition.present => '现在',
  TarotPosition.future => '未来',
};

String tarotOrientationLabel(TarotOrientation orientation) =>
    orientation == TarotOrientation.upright ? '正位' : '逆位';

String tarotRevealModeLabel(TarotRevealMode mode) => switch (mode) {
  TarotRevealMode.sequential => '逐张揭示',
  TarotRevealMode.allAtOnce => '一次揭示',
};

String tarotArcanaPoolLabel(bool includeMinorArcana) =>
    includeMinorArcana ? '完整牌组（78 张）' : '仅大阿卡那（22 张）';

String tarotReadingSummary(TarotReadingConfig config) =>
    '${tarotSpreadLabel(config.spread)} · '
    '${config.drawCount} 张 · '
    '${tarotArcanaPoolLabel(config.includeMinorArcana)} · '
    '${config.useReversals ? '使用逆位' : '仅正位'} · '
    '${tarotRevealModeLabel(config.revealMode)}';
