import '../domain/card_models.dart';

String cardRankLabel(CardRank rank) => switch (rank) {
  CardRank.two => '2',
  CardRank.three => '3',
  CardRank.four => '4',
  CardRank.five => '5',
  CardRank.six => '6',
  CardRank.seven => '7',
  CardRank.eight => '8',
  CardRank.nine => '9',
  CardRank.ten => '10',
  CardRank.jack => 'J',
  CardRank.queen => 'Q',
  CardRank.king => 'K',
  CardRank.ace => 'A',
};

String cardSuitLabel(CardSuit suit) => switch (suit) {
  CardSuit.clubs => '梅花',
  CardSuit.diamonds => '方块',
  CardSuit.hearts => '红桃',
  CardSuit.spades => '黑桃',
};

String cardSuitSymbol(CardSuit suit) => switch (suit) {
  CardSuit.clubs => '♣',
  CardSuit.diamonds => '♦',
  CardSuit.hearts => '♥',
  CardSuit.spades => '♠',
};

String playingCardLabel(PlayingCard card) {
  final joker = card.joker;
  final label = joker != null
      ? joker == JokerKind.small
            ? '小王'
            : '大王'
      : '${cardSuitLabel(card.suit!)} ${cardRankLabel(card.rank!)}';
  return card.deckIndex == 1 ? label : '第${card.deckIndex}副 · $label';
}

String cardDeckSummary(CardDrawConfig config) =>
    '标准牌组 · '
    '${config.deckCount == 1 ? '' : '${config.deckCount} 副牌 · '}'
    '${config.includeJokers ? '含大小王' : '不含大小王'} · '
    '${config.deckSize} 张 · 抽取 ${config.drawCount} 张 · 无放回';
