import 'dart:collection';

enum TarotArcana { major, minor }

enum TarotSuit { wands, cups, swords, pentacles }

enum TarotRank {
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  page,
  knight,
  queen,
  king,
}

enum TarotSpreadPreset { dailyCard, singleQuestion, pastPresentFuture }

enum TarotPosition { dailyGuidance, coreMessage, past, present, future }

enum TarotOrientation { upright, reversed }

enum TarotRevealMode { sequential, allAtOnce }

final class TarotCard {
  const TarotCard.major({
    required this.id,
    required this.name,
    required this.deckIndex,
    required this.majorNumber,
  }) : arcana = TarotArcana.major,
       suit = null,
       rank = null;

  const TarotCard.minor({
    required this.id,
    required this.name,
    required this.deckIndex,
    required this.suit,
    required this.rank,
  }) : arcana = TarotArcana.minor,
       majorNumber = null;

  final String id;
  final String name;
  final int deckIndex;
  final TarotArcana arcana;
  final int? majorNumber;
  final TarotSuit? suit;
  final TarotRank? rank;

  @override
  bool operator ==(Object other) => other is TarotCard && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

final class TarotReadingConfig {
  const TarotReadingConfig({
    this.spread = TarotSpreadPreset.dailyCard,
    this.includeMinorArcana = true,
    this.useReversals = true,
    this.revealMode = TarotRevealMode.sequential,
    this.intention,
  });

  static const maximumIntentionLength = 500;
  static final RegExp _unsupportedControlCharacters = RegExp(
    r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]',
  );

  final TarotSpreadPreset spread;
  final bool includeMinorArcana;
  final bool useReversals;
  final TarotRevealMode revealMode;
  final String? intention;

  List<TarotPosition> get positions => switch (spread) {
    TarotSpreadPreset.dailyCard => const <TarotPosition>[
      TarotPosition.dailyGuidance,
    ],
    TarotSpreadPreset.singleQuestion => const <TarotPosition>[
      TarotPosition.coreMessage,
    ],
    TarotSpreadPreset.pastPresentFuture => const <TarotPosition>[
      TarotPosition.past,
      TarotPosition.present,
      TarotPosition.future,
    ],
  };

  int get drawCount => positions.length;

  String? get normalizedIntention {
    final normalized = intention?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  List<String> validate() {
    final errors = <String>[];
    final normalized = normalizedIntention;
    if (normalized != null) {
      if (normalized.length > maximumIntentionLength) {
        errors.add('问题或备注不能超过 $maximumIntentionLength 个字符。');
      }
      if (_unsupportedControlCharacters.hasMatch(normalized)) {
        errors.add('问题或备注包含不支持的控制字符。');
      }
    }
    return List<String>.unmodifiable(errors);
  }

  TarotReadingConfig normalized({bool includeIntention = true}) =>
      TarotReadingConfig(
        spread: spread,
        includeMinorArcana: includeMinorArcana,
        useReversals: useReversals,
        revealMode: revealMode,
        intention: includeIntention ? normalizedIntention : null,
      );
}

final class TarotDrawnCard {
  const TarotDrawnCard({
    required this.card,
    required this.position,
    required this.orientation,
  });

  final TarotCard card;
  final TarotPosition position;
  final TarotOrientation orientation;
}

final class TarotReadingResult {
  TarotReadingResult({
    required this.config,
    required List<TarotDrawnCard> cards,
    required this.contentVersion,
  }) : cards = UnmodifiableListView<TarotDrawnCard>(
         List<TarotDrawnCard>.of(cards),
       );

  final TarotReadingConfig config;
  final List<TarotDrawnCard> cards;
  final String contentVersion;
}

final class TarotValidationException implements Exception {
  TarotValidationException(Iterable<String> errors)
    : errors = List<String>.unmodifiable(errors);

  final List<String> errors;
}
