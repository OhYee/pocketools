import '../../../core/session/session.dart';
import '../content/multi_divination_content_catalog.dart';
import '../domain/multi_divination_models.dart';
import '../../liuyao/domain/liuyao_models.dart';
import '../../tarot/domain/tarot_deck.dart';
import '../../tarot/domain/tarot_models.dart';

/// Strict, JSON-compatible codec for complete and partial multi-divination
/// drafts. Derived line and hexagram fields are encoded for readable history,
/// then recomputed and checked while decoding.
final class MultiDivinationSessionCodec implements ToolSessionCodec {
  const MultiDivinationSessionCodec();

  @override
  String get toolId => 'multi_divination';

  @override
  Map<String, Object?> encodeInput(Object input) {
    if (input is! MultiDivinationConfig) {
      throw const FormatException(
        'Multi-divination input must be a MultiDivinationConfig.',
      );
    }
    final config = input.normalized();
    final errors = config.validate();
    if (errors.isNotEmpty) throw FormatException(errors.join(' '));
    return <String, Object?>{
      'mode': config.mode.name,
      'intention': config.normalizedIntention,
      'groupCapacity': MultiDivinationReading.groupCapacity,
      'cardsPerGroup': MultiDivinationReading.cardsPerGroup,
      'interpretedSlots': MultiDivinationContentCatalog.interpretedSlots
          .map((slot) => slot.code)
          .toList(growable: false),
    };
  }

  @override
  MultiDivinationConfig decodeInput(Map<String, Object?> input) {
    _requireExactKeys(input, const <String>{
      'mode',
      'intention',
      'groupCapacity',
      'cardsPerGroup',
      'interpretedSlots',
    }, 'Multi-divination input');
    final mode = _enumByName(
      MultiDivinationMode.values,
      _requiredString(input, 'mode', 'Multi-divination input'),
      'Multi-divination input mode',
    );
    final groupCapacity = _requiredInt(
      input,
      'groupCapacity',
      'Multi-divination input',
    );
    if (groupCapacity != MultiDivinationReading.groupCapacity) {
      throw FormatException(
        'Multi-divination input groupCapacity must be '
        '${MultiDivinationReading.groupCapacity}; got $groupCapacity.',
      );
    }
    final cardsPerGroup = _requiredInt(
      input,
      'cardsPerGroup',
      'Multi-divination input',
    );
    if (cardsPerGroup != MultiDivinationReading.cardsPerGroup) {
      throw FormatException(
        'Multi-divination input cardsPerGroup must be '
        '${MultiDivinationReading.cardsPerGroup}; got $cardsPerGroup.',
      );
    }
    final rawSlots = input['interpretedSlots'];
    if (rawSlots is! List || rawSlots.length != 1 || rawSlots.first != 'A') {
      throw const FormatException(
        'Standard multi-divination input must interpret slot A only.',
      );
    }
    final config = MultiDivinationConfig(
      mode: mode,
      intention: _optionalString(input, 'intention', 'Multi-divination input'),
    ).normalized();
    final errors = config.validate();
    if (errors.isNotEmpty) throw FormatException(errors.join(' '));
    return config;
  }

  @override
  Map<String, Object?> encodeOutcome(Object outcome) {
    if (outcome is! MultiDivinationReading) {
      throw const FormatException(
        'Multi-divination outcome must be a MultiDivinationReading.',
      );
    }
    final encoded = <String, Object?>{
      'groupCount': outcome.groups.length,
      'groups': outcome.groups.map(_encodeGroup).toList(growable: false),
      'deckOrder': outcome.deckOrder?.toList(growable: false),
      'complete': outcome.isComplete,
      'primaryHexagramId': outcome.primaryHexagram?.id,
      'changedHexagramId': outcome.changedHexagram?.id,
      'contentVersion': MultiDivinationContentCatalog.contentVersion,
    };
    _decodeAndValidateOutcome(encoded, outcome.config);
    return encoded;
  }

  @override
  MultiDivinationReading decodeOutcome(
    Map<String, Object?> outcome,
    Object input,
  ) {
    if (input is! MultiDivinationConfig) {
      throw const FormatException(
        'Multi-divination outcome requires a decoded MultiDivinationConfig.',
      );
    }
    return _decodeAndValidateOutcome(outcome, input);
  }

  @override
  String summarize(SessionRecord session) {
    final config = decodeInput(session.input);
    final reading = decodeOutcome(session.outcome, config);
    if (!reading.isComplete) {
      return '标准模式 · 已完成 ${reading.groups.length}/'
          '${MultiDivinationReading.groupCapacity} 组';
    }
    final primary = reading.primaryHexagram!;
    final moving = reading.movingLineIndexes;
    if (moving.isEmpty) {
      return '本卦第 ${primary.kingWenNumber} 卦 ${primary.name} · 无动爻 · 变卦无';
    }
    final changed = reading.changedHexagram!;
    return '本卦第 ${primary.kingWenNumber} 卦 ${primary.name} · '
        '动爻 ${moving.map((index) => index + 1).join('、')} · '
        '变卦第 ${changed.kingWenNumber} 卦 ${changed.name}';
  }

  Map<String, Object?> _encodeGroup(MultiDivinationGroup group) =>
      <String, Object?>{
        'sequence': group.index,
        'cards': group.cards.map(_encodeCard).toList(growable: false),
        'uprightCount': group.uprightCount,
        'lineValue': group.lineValue,
        'lineKind': group.lineKind.name,
      };

  Map<String, Object?> _encodeCard(MultiDivinationCard card) =>
      <String, Object?>{
        'slot': card.slot.code,
        'cardId': card.card.id,
        'orientation': card.orientation.name,
      };

  MultiDivinationReading _decodeAndValidateOutcome(
    Map<String, Object?> outcome,
    MultiDivinationConfig config,
  ) {
    _requireExactKeys(outcome, const <String>{
      'groupCount',
      'groups',
      'deckOrder',
      'complete',
      'primaryHexagramId',
      'changedHexagramId',
      'contentVersion',
    }, 'Multi-divination outcome');
    final groupCount = _requiredInt(
      outcome,
      'groupCount',
      'Multi-divination outcome',
    );
    if (groupCount < 0 || groupCount > MultiDivinationReading.groupCapacity) {
      throw const FormatException(
        'Multi-divination outcome groupCount must be 0 through 6.',
      );
    }
    final rawGroups = outcome['groups'];
    if (rawGroups is! List || rawGroups.length != groupCount) {
      throw const FormatException(
        'Multi-divination outcome groups length must match groupCount.',
      );
    }
    final deckOrder = _decodeDeckOrder(outcome['deckOrder']);
    final groups = <MultiDivinationGroup>[];
    for (var index = 0; index < rawGroups.length; index++) {
      final rawGroup = rawGroups[index];
      if (rawGroup is! Map) {
        throw FormatException(
          'Multi-divination outcome groups[$index] must be a map.',
        );
      }
      groups.add(
        _decodeGroup(
          _stringKeyedMap(rawGroup, 'Multi-divination outcome groups[$index]'),
          index,
        ),
      );
    }

    final complete = _requiredBool(
      outcome,
      'complete',
      'Multi-divination outcome',
    );
    if (complete != (groupCount == MultiDivinationReading.groupCapacity)) {
      throw const FormatException(
        'Multi-divination outcome complete must match whether six groups exist.',
      );
    }
    final contentVersion = _requiredString(
      outcome,
      'contentVersion',
      'Multi-divination outcome',
    );
    if (contentVersion != MultiDivinationContentCatalog.contentVersion) {
      throw FormatException(
        'Unsupported multi-divination contentVersion: $contentVersion.',
      );
    }

    late final MultiDivinationReading reading;
    try {
      reading = MultiDivinationReading(
        config: config,
        groups: groups,
        deckOrder: deckOrder,
      );
    } on Object catch (error) {
      throw FormatException('Invalid multi-divination reading: $error');
    }
    final primaryId = _optionalString(
      outcome,
      'primaryHexagramId',
      'Multi-divination outcome',
    );
    final changedId = _optionalString(
      outcome,
      'changedHexagramId',
      'Multi-divination outcome',
    );
    if (!complete) {
      if (primaryId != null || changedId != null) {
        throw const FormatException(
          'Incomplete multi-divination outcomes must not contain hexagram ids.',
        );
      }
      return reading;
    }
    final expectedPrimary = reading.primaryHexagram!.id;
    if (primaryId != expectedPrimary) {
      throw FormatException(
        'Multi-divination primaryHexagramId must be $expectedPrimary.',
      );
    }
    if (reading.movingLineIndexes.isEmpty) {
      if (changedId != null) {
        throw const FormatException(
          'A static multi-divination outcome must not contain changedHexagramId.',
        );
      }
    } else {
      final expectedChanged = reading.changedHexagram!.id;
      if (changedId != expectedChanged) {
        throw FormatException(
          'Multi-divination changedHexagramId must be $expectedChanged.',
        );
      }
    }
    return reading;
  }

  MultiDivinationGroup _decodeGroup(
    Map<String, Object?> payload,
    int expectedIndex,
  ) {
    _requireExactKeys(payload, const <String>{
      'sequence',
      'cards',
      'uprightCount',
      'lineValue',
      'lineKind',
    }, 'Multi-divination group $expectedIndex');
    final sequence = _requiredInt(
      payload,
      'sequence',
      'Multi-divination group',
    );
    if (sequence != expectedIndex) {
      throw FormatException(
        'Multi-divination group sequence must be $expectedIndex; got $sequence.',
      );
    }
    final rawCards = payload['cards'];
    if (rawCards is! List ||
        rawCards.length != MultiDivinationReading.cardsPerGroup) {
      throw const FormatException(
        'Multi-divination groups must contain exactly three cards.',
      );
    }
    final cards = <MultiDivinationCard>[];
    for (var index = 0; index < rawCards.length; index++) {
      final rawCard = rawCards[index];
      if (rawCard is! Map) {
        throw FormatException(
          'Multi-divination group cards[$index] must be a map.',
        );
      }
      final cardPayload = _stringKeyedMap(
        rawCard,
        'Multi-divination group cards[$index]',
      );
      _requireExactKeys(cardPayload, const <String>{
        'slot',
        'cardId',
        'orientation',
      }, 'Multi-divination group cards[$index]');
      final slot = _slotByCode(
        _requiredString(cardPayload, 'slot', 'Multi-divination group card'),
        'Multi-divination group cards[$index] slot',
      );
      final expectedSlot = MultiDivinationCardSlot.values[index];
      if (slot != expectedSlot) {
        throw FormatException(
          'Multi-divination group cards[$index] slot must be '
          '${expectedSlot.code}.',
        );
      }
      final cardId = _requiredString(
        cardPayload,
        'cardId',
        'Multi-divination group card',
      );
      final card = TarotDeck.byId[cardId];
      if (card == null) {
        throw FormatException(
          'Unknown tarot card in multi-divination: $cardId.',
        );
      }
      final orientation = _enumByName(
        TarotOrientation.values,
        _requiredString(
          cardPayload,
          'orientation',
          'Multi-divination group card',
        ),
        'Multi-divination group cards[$index] orientation',
      );
      cards.add(
        MultiDivinationCard(slot: slot, card: card, orientation: orientation),
      );
    }
    late final MultiDivinationGroup group;
    try {
      group = MultiDivinationGroup(index: sequence, cards: cards);
    } on Object catch (error) {
      throw FormatException('Invalid multi-divination group $sequence: $error');
    }
    final uprightCount = _requiredInt(
      payload,
      'uprightCount',
      'Multi-divination group',
    );
    if (uprightCount != group.uprightCount) {
      throw FormatException(
        'Multi-divination group $sequence uprightCount must be '
        '${group.uprightCount}.',
      );
    }
    final lineValue = _requiredInt(
      payload,
      'lineValue',
      'Multi-divination group',
    );
    if (lineValue != group.lineValue) {
      throw FormatException(
        'Multi-divination group $sequence lineValue must be ${group.lineValue}.',
      );
    }
    final lineKind = _enumByName(
      LiuyaoLineKind.values,
      _requiredString(payload, 'lineKind', 'Multi-divination group'),
      'Multi-divination group lineKind',
    );
    if (lineKind != group.lineKind) {
      throw FormatException(
        'Multi-divination group $sequence lineKind must be ${group.lineKind.name}.',
      );
    }
    return group;
  }

  MultiDivinationCardSlot _slotByCode(String code, String source) {
    for (final slot in MultiDivinationCardSlot.values) {
      if (slot.code == code) return slot;
    }
    throw FormatException('$source is invalid: $code.');
  }

  List<String>? _decodeDeckOrder(Object? raw) {
    if (raw == null) return null;
    if (raw is! List || raw.length != TarotDeck.standard.length) {
      throw const FormatException(
        'Multi-divination deckOrder must be null or contain all 78 cards.',
      );
    }
    final order = <String>[];
    for (var index = 0; index < raw.length; index++) {
      final value = raw[index];
      if (value is! String || value.isEmpty) {
        throw FormatException(
          'Multi-divination deckOrder[$index] must be a non-empty string.',
        );
      }
      order.add(value);
    }
    try {
      MultiDivinationReading(
        config: const MultiDivinationConfig(),
        deckOrder: order,
      );
    } on Object catch (error) {
      throw FormatException('Invalid multi-divination deckOrder: $error');
    }
    return List<String>.unmodifiable(order);
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

  T _enumByName<T extends Enum>(
    Iterable<T> values,
    String name,
    String source,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw FormatException('$source has unsupported value: $name.');
  }

  String _requiredString(
    Map<String, Object?> payload,
    String key,
    String source,
  ) {
    final value = payload[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('$source $key must be a non-empty string.');
    }
    return value;
  }

  String? _optionalString(
    Map<String, Object?> payload,
    String key,
    String source,
  ) {
    final value = payload[key];
    if (value == null) return null;
    if (value is! String || value.isEmpty) {
      throw FormatException('$source $key must be null or a non-empty string.');
    }
    return value;
  }

  int _requiredInt(Map<String, Object?> payload, String key, String source) {
    final value = payload[key];
    if (value is! int) {
      throw FormatException('$source $key must be an integer.');
    }
    return value;
  }

  bool _requiredBool(Map<String, Object?> payload, String key, String source) {
    final value = payload[key];
    if (value is! bool) {
      throw FormatException('$source $key must be a boolean.');
    }
    return value;
  }
}
