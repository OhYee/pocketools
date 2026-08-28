import 'dart:collection';

enum CardSuit { clubs, diamonds, hearts, spades }

enum CardRank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
}

enum JokerKind { small, big }

final class PlayingCard {
  const PlayingCard.standard(this.suit, this.rank, {this.deckIndex = 1})
    : joker = null;

  const PlayingCard.joker(this.joker, {this.deckIndex = 1})
    : suit = null,
      rank = null;

  final CardSuit? suit;
  final CardRank? rank;
  final JokerKind? joker;
  final int deckIndex;

  bool get isJoker => joker != null;

  String get id {
    final baseId = isJoker
        ? 'joker-${joker!.name}'
        : '${suit!.name}-${rank!.name}';
    return deckIndex == 1 ? baseId : 'deck-$deckIndex-$baseId';
  }

  @override
  bool operator ==(Object other) => other is PlayingCard && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

final class CardDrawConfig {
  const CardDrawConfig({
    required this.drawCount,
    this.deckCount = 1,
    this.includeJokers = false,
  });

  static const minimumDeckCount = 1;
  static const maximumDeckCount = 10;

  final int drawCount;
  final int deckCount;
  final bool includeJokers;

  int get cardsPerDeck => includeJokers ? 54 : 52;

  int get deckSize => cardsPerDeck * deckCount;

  List<String> validate() {
    if (deckCount < minimumDeckCount || deckCount > maximumDeckCount) {
      return List<String>.unmodifiable(<String>[
        '牌副数必须是 $minimumDeckCount～$maximumDeckCount 的整数。',
      ]);
    }
    if (drawCount < 1 || drawCount > deckSize) {
      return List<String>.unmodifiable(<String>['抽牌数量必须是 1～$deckSize 的整数。']);
    }
    return const <String>[];
  }
}

final class CardDrawResult {
  CardDrawResult({required this.config, required List<PlayingCard> cards})
    : cards = UnmodifiableListView(List<PlayingCard>.of(cards));

  final CardDrawConfig config;
  final List<PlayingCard> cards;

  int get remainingCount => config.deckSize - cards.length;
}

final class CardValidationException implements Exception {
  CardValidationException(Iterable<String> errors)
    : errors = List<String>.unmodifiable(errors);

  final List<String> errors;
}
