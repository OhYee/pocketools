import 'dart:collection';

import 'tarot_models.dart';

abstract final class TarotDeck {
  static final List<TarotCard> standard = _buildStandardDeck();

  static final Map<String, TarotCard> byId =
      Map<String, TarotCard>.unmodifiable(<String, TarotCard>{
        for (final card in standard) card.id: card,
      });

  static List<String> validate(Iterable<TarotCard> cards) {
    final snapshot = List<TarotCard>.of(cards);
    final errors = <String>[];
    if (snapshot.length != 78) errors.add('塔罗牌组必须恰好包含 78 张牌。');
    if (snapshot.where((card) => card.arcana == TarotArcana.major).length !=
        22) {
      errors.add('塔罗牌组必须包含 22 张大阿尔卡那。');
    }
    for (final suit in TarotSuit.values) {
      final suitedCards = snapshot.where((card) => card.suit == suit).toList();
      if (suitedCards.length != 14) {
        errors.add('${tarotSuitName(suit)}必须包含 14 张牌。');
      }
      final ranks = suitedCards.map((card) => card.rank).toSet();
      if (ranks.length != TarotRank.values.length) {
        errors.add('${tarotSuitName(suit)}的十四种点数必须完整且唯一。');
      }
    }
    if (snapshot.map((card) => card.id).toSet().length != snapshot.length) {
      errors.add('塔罗牌 ID 必须唯一。');
    }
    if (snapshot.map((card) => card.deckIndex).toSet().length !=
        snapshot.length) {
      errors.add('塔罗牌面索引必须唯一。');
    }
    for (var index = 0; index < snapshot.length; index++) {
      final card = snapshot[index];
      if (card.deckIndex != index) {
        errors.add('塔罗牌索引必须按稳定牌组顺序连续。');
        break;
      }
      if (card.id.isEmpty || card.name.isEmpty) {
        errors.add('每张塔罗牌都必须有稳定 ID 和名称。');
        break;
      }
    }
    return List<String>.unmodifiable(errors);
  }

  static List<TarotCard> _buildStandardDeck() {
    final cards = <TarotCard>[
      for (var index = 0; index < _majorSeeds.length; index++)
        TarotCard.major(
          id: 'major-${index.toString().padLeft(2, '0')}-${_majorSeeds[index].$1}',
          name: _majorSeeds[index].$2,
          deckIndex: index,
          majorNumber: index,
        ),
    ];
    for (final suit in TarotSuit.values) {
      for (final rank in TarotRank.values) {
        cards.add(
          TarotCard.minor(
            id: 'minor-${suit.name}-${rank.name}',
            name: '${tarotSuitName(suit)}${tarotRankName(rank)}',
            deckIndex: cards.length,
            suit: suit,
            rank: rank,
          ),
        );
      }
    }
    final errors = validate(cards);
    if (errors.isNotEmpty) throw StateError(errors.join(' '));
    return UnmodifiableListView<TarotCard>(cards);
  }

  static const List<(String, String)> _majorSeeds = <(String, String)>[
    ('fool', '愚者'),
    ('magician', '魔术师'),
    ('high-priestess', '女祭司'),
    ('empress', '女皇'),
    ('emperor', '皇帝'),
    ('hierophant', '教皇'),
    ('lovers', '恋人'),
    ('chariot', '战车'),
    ('strength', '力量'),
    ('hermit', '隐者'),
    ('wheel-of-fortune', '命运之轮'),
    ('justice', '正义'),
    ('hanged-man', '倒吊人'),
    ('death', '死神'),
    ('temperance', '节制'),
    ('devil', '恶魔'),
    ('tower', '高塔'),
    ('star', '星星'),
    ('moon', '月亮'),
    ('sun', '太阳'),
    ('judgement', '审判'),
    ('world', '世界'),
  ];
}

String tarotSuitName(TarotSuit suit) => switch (suit) {
  TarotSuit.wands => '权杖',
  TarotSuit.cups => '圣杯',
  TarotSuit.swords => '宝剑',
  TarotSuit.pentacles => '星币',
};

String tarotRankName(TarotRank rank) => switch (rank) {
  TarotRank.ace => '一',
  TarotRank.two => '二',
  TarotRank.three => '三',
  TarotRank.four => '四',
  TarotRank.five => '五',
  TarotRank.six => '六',
  TarotRank.seven => '七',
  TarotRank.eight => '八',
  TarotRank.nine => '九',
  TarotRank.ten => '十',
  TarotRank.page => '侍从',
  TarotRank.knight => '骑士',
  TarotRank.queen => '王后',
  TarotRank.king => '国王',
};
