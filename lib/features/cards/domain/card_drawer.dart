import '../../../core/random/random_source.dart';
import 'card_models.dart';

final class CardDrawer {
  const CardDrawer(this._random);

  static const ruleVersion = 'cards/1.0.0';
  static const algorithmVersion = 'random-unbiased-fisher-yates/1.0.0';

  final RandomSource _random;

  /// Draws one card from the remaining physical deck.
  ///
  /// The existing [draw] API intentionally keeps its batch-draw contract for
  /// session/history compatibility. Interactive pages use this method so a
  /// deck can stay on screen and each tap consumes exactly one card.
  PlayingCard drawOne({
    bool includeJokers = false,
    int deckCount = 1,
    Iterable<PlayingCard> excluded = const <PlayingCard>[],
  }) {
    final config = CardDrawConfig(
      drawCount: 1,
      deckCount: deckCount,
      includeJokers: includeJokers,
    );
    final errors = config.validate();
    if (errors.isNotEmpty) throw CardValidationException(errors);
    final deck = _buildDeck(config);
    final excludedIds = excluded.map((card) => card.id).toSet();
    final remaining = deck
        .where((card) => !excludedIds.contains(card.id))
        .toList(growable: false);
    if (remaining.isEmpty) {
      throw CardValidationException(<String>['当前牌组已经没有剩余牌。']);
    }
    return remaining[_random.nextInt(remaining.length)];
  }

  CardDrawResult draw(CardDrawConfig config) {
    final errors = config.validate();
    if (errors.isNotEmpty) {
      throw CardValidationException(errors);
    }
    final deck = _buildDeck(config);
    final shuffled = fisherYatesShuffle(deck, _random);
    return CardDrawResult(
      config: config,
      cards: shuffled.take(config.drawCount).toList(growable: false),
    );
  }

  List<PlayingCard> _buildDeck(CardDrawConfig config) => <PlayingCard>[
    for (var deckIndex = 1; deckIndex <= config.deckCount; deckIndex++) ...[
      for (final suit in CardSuit.values)
        for (final rank in CardRank.values)
          PlayingCard.standard(suit, rank, deckIndex: deckIndex),
      if (config.includeJokers) ...<PlayingCard>[
        PlayingCard.joker(JokerKind.small, deckIndex: deckIndex),
        PlayingCard.joker(JokerKind.big, deckIndex: deckIndex),
      ],
    ],
  ];
}
