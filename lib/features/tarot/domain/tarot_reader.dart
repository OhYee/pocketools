import '../../../core/random/random_source.dart';
import 'tarot_deck.dart';
import 'tarot_models.dart';

final class TarotReader {
  TarotReader(
    this._random, {
    required this.contentVersion,
    Iterable<TarotCard>? deck,
  }) : _deck = List<TarotCard>.unmodifiable(deck ?? TarotDeck.standard);

  static const ruleVersion = 'tarot-reading/1.0.0';
  static const algorithmVersion = 'random-unbiased-fisher-yates-binary/1.0.0';

  final RandomSource _random;
  final String contentVersion;
  final List<TarotCard> _deck;

  /// Draws one card from the remaining deck for the interactive deck flow.
  ///
  /// [draw] remains the batch-reading API used by existing spread/session
  /// callers. This method keeps one tap equal to one card and prevents a
  /// previously drawn card from re-entering the visible deck.
  TarotDrawnCard drawOne(
    TarotReadingConfig config, {
    Iterable<String> excludedCardIds = const <String>[],
    TarotPosition? position,
  }) {
    final normalizedConfig = config.normalized();
    final errors = <String>[
      ...TarotDeck.validate(_deck),
      ...normalizedConfig.validate(),
      if (contentVersion.trim().isEmpty) '内容版本不能为空。',
    ];
    if (errors.isNotEmpty) throw TarotValidationException(errors);
    final excluded = excludedCardIds.toSet();
    final availableDeck = _deck
        .where(
          (card) =>
              (normalizedConfig.includeMinorArcana ||
                  card.arcana == TarotArcana.major) &&
              !excluded.contains(card.id),
        )
        .toList(growable: false);
    if (availableDeck.isEmpty) {
      throw TarotValidationException(<String>['当前塔罗牌组已经没有剩余牌。']);
    }
    final card = availableDeck[_random.nextInt(availableDeck.length)];
    final orientation = normalizedConfig.useReversals
        ? (_random.nextInt(2) == 0
              ? TarotOrientation.upright
              : TarotOrientation.reversed)
        : TarotOrientation.upright;
    return TarotDrawnCard(
      card: card,
      position: position ?? normalizedConfig.positions.first,
      orientation: orientation,
    );
  }

  TarotReadingResult draw(TarotReadingConfig config) {
    final normalizedConfig = config.normalized();
    final errors = <String>[
      ...TarotDeck.validate(_deck),
      ...normalizedConfig.validate(),
      if (contentVersion.trim().isEmpty) '内容版本不能为空。',
    ];
    if (errors.isNotEmpty) throw TarotValidationException(errors);

    final availableDeck = normalizedConfig.includeMinorArcana
        ? _deck
        : _deck
              .where((card) => card.arcana == TarotArcana.major)
              .toList(growable: false);
    final shuffled = fisherYatesShuffle(availableDeck, _random);
    final cards = <TarotDrawnCard>[];
    for (var index = 0; index < normalizedConfig.drawCount; index++) {
      final orientation = normalizedConfig.useReversals
          ? (_random.nextInt(2) == 0
                ? TarotOrientation.upright
                : TarotOrientation.reversed)
          : TarotOrientation.upright;
      cards.add(
        TarotDrawnCard(
          card: shuffled[index],
          position: normalizedConfig.positions[index],
          orientation: orientation,
        ),
      );
    }
    return TarotReadingResult(
      config: normalizedConfig,
      cards: cards,
      contentVersion: contentVersion,
    );
  }
}
