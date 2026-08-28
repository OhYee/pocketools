import '../../../core/session/session.dart';
import '../domain/card_models.dart';

/// Presentation/session adapter kept separate from the pure card domain.
final class CardSessionCodec implements ToolSessionCodec {
  const CardSessionCodec();

  @override
  String get toolId => 'cards';

  @override
  Map<String, Object?> encodeInput(Object input) {
    final config = input as CardDrawConfig;
    _validateConfig(config, source: 'Card input');
    return <String, Object?>{
      'drawCount': config.drawCount,
      'deckCount': config.deckCount,
      'includeJokers': config.includeJokers,
      'deckSize': config.deckSize,
    };
  }

  @override
  CardDrawConfig decodeInput(Map<String, Object?> input) {
    final drawCount = _requiredInt(input, 'drawCount', source: 'Card input');
    final deckCount = input.containsKey('deckCount')
        ? _requiredInt(input, 'deckCount', source: 'Card input')
        : 1;
    final includeJokers = _requiredBool(
      input,
      'includeJokers',
      source: 'Card input',
    );
    final config = CardDrawConfig(
      drawCount: drawCount,
      deckCount: deckCount,
      includeJokers: includeJokers,
    );
    _validateConfig(config, source: 'Card input');
    final deckSize = input.containsKey('deckSize')
        ? _requiredInt(input, 'deckSize', source: 'Card input')
        : config.deckSize;
    if (deckSize != config.deckSize) {
      throw FormatException(
        'Card input deckSize must be ${config.deckSize} when '
        'deckCount is $deckCount and includeJokers is $includeJokers; '
        'got $deckSize.',
      );
    }
    return config;
  }

  @override
  Map<String, Object?> encodeOutcome(Object outcome) {
    final result = outcome as CardDrawResult;
    final encoded = <String, Object?>{
      'cards': result.cards.map((card) => card.id).toList(growable: false),
      'remainingCount': result.remainingCount,
    };
    _decodeAndValidateOutcome(encoded, result.config);
    return encoded;
  }

  @override
  CardDrawResult decodeOutcome(Map<String, Object?> outcome, Object input) {
    if (input is! CardDrawConfig) {
      throw FormatException(
        'Card outcome requires a decoded CardDrawConfig input.',
      );
    }
    return _decodeAndValidateOutcome(outcome, input);
  }

  CardDrawResult _decodeAndValidateOutcome(
    Map<String, Object?> outcome,
    CardDrawConfig config,
  ) {
    _validateConfig(config, source: 'Card outcome input');
    final rawCards = outcome['cards'];
    if (rawCards is! List) {
      throw const FormatException('Card outcome cards must be a list.');
    }
    if (rawCards.isEmpty || rawCards.length > config.drawCount) {
      throw FormatException(
        'Card outcome must contain 1 to ${config.drawCount} cards; '
        'got ${rawCards.length}.',
      );
    }

    final cards = <PlayingCard>[];
    final seenIds = <String>{};
    for (var index = 0; index < rawCards.length; index++) {
      final rawId = rawCards[index];
      if (rawId is! String) {
        throw FormatException(
          'Card outcome cards[$index] must be a card id string.',
        );
      }
      final card = _cardFromId(rawId);
      if (card.deckIndex > config.deckCount) {
        throw FormatException(
          'Card outcome contains a card from deck ${card.deckIndex}; '
          'configured deck count is ${config.deckCount}.',
        );
      }
      if (card.isJoker && !config.includeJokers) {
        throw FormatException(
          'Card outcome contains joker $rawId while includeJokers is false.',
        );
      }
      if (!seenIds.add(card.id)) {
        throw FormatException(
          'Card outcome contains duplicate card id: $rawId.',
        );
      }
      cards.add(card);
    }

    final remainingCount = _requiredInt(
      outcome,
      'remainingCount',
      source: 'Card outcome',
    );
    final expectedRemainingCount = config.deckSize - cards.length;
    if (remainingCount != expectedRemainingCount) {
      throw FormatException(
        'Card outcome remainingCount must be $expectedRemainingCount; '
        'got $remainingCount.',
      );
    }
    return CardDrawResult(config: config, cards: cards);
  }

  PlayingCard _cardFromId(String id) {
    var deckIndex = 1;
    var cardId = id;
    final deckMatch = RegExp(r'^deck-(\d+)-(.+)$').firstMatch(id);
    if (deckMatch != null) {
      deckIndex = int.tryParse(deckMatch.group(1)!) ?? 0;
      cardId = deckMatch.group(2)!;
    }
    if (deckIndex < 1) throw FormatException('Invalid card id: $id');
    if (cardId == 'joker-small') {
      return PlayingCard.joker(JokerKind.small, deckIndex: deckIndex);
    }
    if (cardId == 'joker-big') {
      return PlayingCard.joker(JokerKind.big, deckIndex: deckIndex);
    }
    final parts = cardId.split('-');
    if (parts.length != 2) throw FormatException('Invalid card id: $id');
    try {
      return PlayingCard.standard(
        CardSuit.values.byName(parts.first),
        CardRank.values.byName(parts.last),
        deckIndex: deckIndex,
      );
    } on ArgumentError {
      throw FormatException('Invalid card id: $id');
    }
  }

  void _validateConfig(CardDrawConfig config, {required String source}) {
    final errors = config.validate();
    if (errors.isNotEmpty) {
      throw FormatException('$source is invalid: ${errors.join(' ')}');
    }
  }

  int _requiredInt(
    Map<String, Object?> payload,
    String key, {
    required String source,
  }) {
    final value = payload[key];
    if (value is! int) {
      throw FormatException('$source $key must be an integer.');
    }
    return value;
  }

  bool _requiredBool(
    Map<String, Object?> payload,
    String key, {
    required String source,
  }) {
    final value = payload[key];
    if (value is! bool) {
      throw FormatException('$source $key must be a boolean.');
    }
    return value;
  }

  @override
  String summarize(SessionRecord session) {
    final cards = (session.outcome['cards']! as List<Object?>).cast<String>();
    return '扑克牌 · 抽取 ${cards.length} 张';
  }
}
