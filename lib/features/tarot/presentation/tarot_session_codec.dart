import '../../../core/session/session.dart';
import '../domain/tarot_deck.dart';
import '../domain/tarot_models.dart';
import 'tarot_labels.dart';

final class TarotSessionCodec implements ToolSessionCodec {
  const TarotSessionCodec();

  static final RegExp _contentVersionPattern = RegExp(
    r'^[A-Za-z0-9._/-]{1,64}$',
  );

  @override
  String get toolId => 'tarot';

  @override
  Map<String, Object?> encodeInput(Object input) {
    if (input is! TarotReadingConfig) {
      throw const FormatException('Tarot input must be a TarotReadingConfig.');
    }
    final config = input.normalized();
    final errors = config.validate();
    if (errors.isNotEmpty) throw FormatException(errors.join(' '));
    return <String, Object?>{
      'spread': config.spread.name,
      'includeMinorArcana': config.includeMinorArcana,
      'useReversals': config.useReversals,
      'revealMode': config.revealMode.name,
      'intention': config.normalizedIntention,
      'drawCount': config.drawCount,
      'positions': config.positions
          .map((position) => position.name)
          .toList(growable: false),
    };
  }

  @override
  TarotReadingConfig decodeInput(Map<String, Object?> input) {
    final payload = <String, Object?>{...input};
    // Sessions written before the deck-pool option default to the original
    // complete 78-card behavior.
    if (!payload.containsKey('includeMinorArcana')) {
      payload['includeMinorArcana'] = true;
    }
    if (!payload.containsKey('intention')) payload['intention'] = null;
    _requireExactKeys(payload, const <String>{
      'spread',
      'includeMinorArcana',
      'useReversals',
      'revealMode',
      'intention',
      'drawCount',
      'positions',
    }, 'Tarot input');
    final spread = _enumByName(
      TarotSpreadPreset.values,
      _requiredString(payload, 'spread', source: 'Tarot input'),
      'Tarot input spread',
    );
    final config = TarotReadingConfig(
      spread: spread,
      includeMinorArcana: _requiredBool(
        payload,
        'includeMinorArcana',
        source: 'Tarot input',
      ),
      useReversals: _requiredBool(
        payload,
        'useReversals',
        source: 'Tarot input',
      ),
      revealMode: _enumByName(
        TarotRevealMode.values,
        _requiredString(payload, 'revealMode', source: 'Tarot input'),
        'Tarot input revealMode',
      ),
      intention: _optionalString(payload, 'intention', source: 'Tarot input'),
    ).normalized();
    final errors = config.validate();
    if (errors.isNotEmpty) throw FormatException(errors.join(' '));
    final drawCount = _requiredInt(payload, 'drawCount', source: 'Tarot input');
    if (drawCount != config.drawCount) {
      throw FormatException(
        'Tarot input drawCount must be ${config.drawCount}; got $drawCount.',
      );
    }
    final rawPositions = payload['positions'];
    if (rawPositions is! List || rawPositions.length != config.drawCount) {
      throw FormatException(
        'Tarot input positions must contain ${config.drawCount} values.',
      );
    }
    for (var index = 0; index < rawPositions.length; index++) {
      if (rawPositions[index] != config.positions[index].name) {
        throw FormatException(
          'Tarot input positions[$index] must be '
          '${config.positions[index].name}.',
        );
      }
    }
    return config;
  }

  @override
  Map<String, Object?> encodeOutcome(Object outcome) {
    if (outcome is! TarotReadingResult) {
      throw const FormatException(
        'Tarot outcome must be a TarotReadingResult.',
      );
    }
    final encoded = <String, Object?>{
      'cards': outcome.cards.indexed
          .map(
            (entry) => <String, Object?>{
              'sequence': entry.$1,
              'cardId': entry.$2.card.id,
              'position': entry.$2.position.name,
              'orientation': entry.$2.orientation.name,
            },
          )
          .toList(growable: false),
      'contentVersion': outcome.contentVersion,
    };
    _decodeAndValidateOutcome(encoded, outcome.config);
    return encoded;
  }

  @override
  TarotReadingResult decodeOutcome(Map<String, Object?> outcome, Object input) {
    if (input is! TarotReadingConfig) {
      throw const FormatException(
        'Tarot outcome requires a decoded TarotReadingConfig input.',
      );
    }
    return _decodeAndValidateOutcome(outcome, input);
  }

  TarotReadingResult _decodeAndValidateOutcome(
    Map<String, Object?> outcome,
    TarotReadingConfig config,
  ) {
    _requireExactKeys(outcome, const <String>{
      'cards',
      'contentVersion',
    }, 'Tarot outcome');
    final rawCards = outcome['cards'];
    if (rawCards is! List ||
        rawCards.isEmpty ||
        rawCards.length > config.drawCount) {
      throw FormatException(
        'Tarot outcome cards must contain 1 to ${config.drawCount} values.',
      );
    }
    final cards = <TarotDrawnCard>[];
    final seenIds = <String>{};
    final seenPositions = <TarotPosition>{};
    final partial = rawCards.length < config.drawCount;
    for (var index = 0; index < rawCards.length; index++) {
      final rawCard = rawCards[index];
      if (rawCard is! Map) {
        throw FormatException('Tarot outcome cards[$index] must be a map.');
      }
      final payload = _stringKeyedMap(rawCard, 'Tarot outcome cards[$index]');
      _requireExactKeys(payload, const <String>{
        'sequence',
        'cardId',
        'position',
        'orientation',
      }, 'Tarot outcome cards[$index]');
      final sequence = _requiredInt(
        payload,
        'sequence',
        source: 'Tarot outcome cards[$index]',
      );
      if (sequence != index) {
        throw FormatException(
          'Tarot outcome cards[$index] sequence must be $index.',
        );
      }
      final cardId = _requiredString(
        payload,
        'cardId',
        source: 'Tarot outcome cards[$index]',
      );
      final card = TarotDeck.byId[cardId];
      if (card == null) {
        throw FormatException('Tarot outcome has invalid cardId: $cardId.');
      }
      if (!config.includeMinorArcana && card.arcana != TarotArcana.major) {
        throw FormatException(
          'Tarot outcome cannot contain minor arcana cards when '
          'includeMinorArcana is false: $cardId.',
        );
      }
      if (!seenIds.add(cardId)) {
        throw FormatException('Tarot outcome has duplicate cardId: $cardId.');
      }
      final position = _enumByName(
        TarotPosition.values,
        _requiredString(
          payload,
          'position',
          source: 'Tarot outcome cards[$index]',
        ),
        'Tarot outcome cards[$index] position',
      );
      if (partial) {
        if (!config.positions.contains(position) ||
            !seenPositions.add(position)) {
          throw FormatException(
            'Tarot outcome cards[$index] position must be a unique position '
            'in the configured spread.',
          );
        }
      } else if (position != config.positions[index]) {
        throw FormatException(
          'Tarot outcome cards[$index] position must be '
          '${config.positions[index].name}.',
        );
      }
      final orientation = _enumByName(
        TarotOrientation.values,
        _requiredString(
          payload,
          'orientation',
          source: 'Tarot outcome cards[$index]',
        ),
        'Tarot outcome cards[$index] orientation',
      );
      if (!config.useReversals && orientation != TarotOrientation.upright) {
        throw FormatException(
          'Tarot outcome cannot contain reversed cards when useReversals is false.',
        );
      }
      cards.add(
        TarotDrawnCard(
          card: card,
          position: position,
          orientation: orientation,
        ),
      );
    }
    final contentVersion = _requiredString(
      outcome,
      'contentVersion',
      source: 'Tarot outcome',
    );
    if (!_contentVersionPattern.hasMatch(contentVersion)) {
      throw const FormatException(
        'Tarot outcome contentVersion has an invalid format.',
      );
    }
    return TarotReadingResult(
      config: config,
      cards: cards,
      contentVersion: contentVersion,
    );
  }

  Map<String, Object?> _stringKeyedMap(Map payload, String source) {
    final result = <String, Object?>{};
    for (final entry in payload.entries) {
      if (entry.key is! String) {
        throw FormatException('$source keys must be strings.');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  void _requireExactKeys(
    Map<String, Object?> payload,
    Set<String> expected,
    String source,
  ) {
    final actual = payload.keys.toSet();
    if (actual.length != expected.length || !actual.containsAll(expected)) {
      final missing = expected.difference(actual).join(', ');
      final unexpected = actual.difference(expected).join(', ');
      throw FormatException(
        '$source keys are invalid; missing=[$missing], '
        'unexpected=[$unexpected].',
      );
    }
  }

  T _enumByName<T extends Enum>(List<T> values, String name, String source) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw FormatException('$source is invalid: $name.');
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

  String _requiredString(
    Map<String, Object?> payload,
    String key, {
    required String source,
  }) {
    final value = payload[key];
    if (value is! String) {
      throw FormatException('$source $key must be a string.');
    }
    return value;
  }

  String? _optionalString(
    Map<String, Object?> payload,
    String key, {
    required String source,
  }) {
    final value = payload[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('$source $key must be a string or null.');
    }
    return value;
  }

  @override
  String summarize(SessionRecord session) {
    final config = decodeInput(session.input);
    final result = decodeOutcome(session.outcome, config);
    final ordered = result.cards
        .map(
          (drawn) =>
              '${tarotPositionLabel(drawn.position)}:${drawn.card.name}'
              '(${tarotOrientationLabel(drawn.orientation)})',
        )
        .join('、');
    return '塔罗 · ${tarotReadingSummary(config)} · $ordered · '
        '内容 ${result.contentVersion} · 规则 ${session.ruleVersion} · '
        '算法 ${session.algorithmVersion}';
  }
}
