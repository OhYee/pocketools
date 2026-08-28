import '../../../core/random/random_source.dart';
import '../../tarot/domain/tarot_deck.dart';
import '../../tarot/domain/tarot_models.dart';
import 'multi_divination_models.dart';

/// Draws the three-card groups from one lazily-created Fisher-Yates deck.
/// Calling [appendGroup] repeatedly never reshuffles the deck and never
/// returns a card already present in the supplied draft.
final class MultiDivinationReader {
  MultiDivinationReader(this._random, {Iterable<TarotCard>? deck})
    : _deck = List<TarotCard>.unmodifiable(deck ?? TarotDeck.standard);

  final RandomSource _random;
  final List<TarotCard> _deck;
  List<TarotCard>? _shuffledDeck;

  MultiDivinationReading appendGroup(MultiDivinationReading reading) {
    if (reading.isComplete) {
      throw StateError('A completed multi-divination reading is immutable.');
    }
    final prepared = reading.deckOrder == null
        ? reading.withDeckOrder(_shuffled().map((card) => card.id))
        : reading;
    final cardsById = <String, TarotCard>{
      for (final card in _deck) card.id: card,
    };
    final usedIds = prepared.groups
        .expand((group) => group.cards)
        .map((card) => card.card.id)
        .toSet();
    final available = prepared.deckOrder!
        .map((id) => cardsById[id])
        .whereType<TarotCard>()
        .where((card) => !usedIds.contains(card.id))
        .take(MultiDivinationReading.cardsPerGroup)
        .toList(growable: false);
    if (available.length != MultiDivinationReading.cardsPerGroup) {
      throw StateError('The tarot deck has no three-card group remaining.');
    }

    final cards = <MultiDivinationCard>[
      for (var index = 0; index < available.length; index++)
        MultiDivinationCard(
          slot: MultiDivinationCardSlot.values[index],
          card: available[index],
          orientation: _nextOrientation(),
        ),
    ];
    return prepared.append(
      MultiDivinationGroup(index: reading.nextGroupIndex, cards: cards),
    );
  }

  MultiDivinationReading drawGroup(MultiDivinationReading reading) =>
      appendGroup(reading);

  List<TarotCard> _shuffled() {
    final current = _shuffledDeck;
    if (current != null) return current;
    final errors = TarotDeck.validate(_deck);
    if (errors.isNotEmpty) {
      throw TarotValidationException(errors);
    }
    final shuffled = fisherYatesShuffle(_deck, _random);
    return _shuffledDeck = shuffled;
  }

  TarotOrientation _nextOrientation() => _random.nextInt(2) == 0
      ? TarotOrientation.upright
      : TarotOrientation.reversed;
}

/// Alias for callers that use the traditional caster terminology.
typedef MultiDivinationCaster = MultiDivinationReader;
