import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/features/multi_divination/content/multi_divination_content_catalog.dart';
import 'package:pocketools/features/multi_divination/domain/multi_divination_models.dart';
import 'package:pocketools/features/multi_divination/domain/multi_divination_reader.dart';
import 'package:pocketools/features/multi_divination/presentation/multi_divination_session_codec.dart';
import 'package:pocketools/features/tarot/domain/tarot_deck.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';

void main() {
  const codec = MultiDivinationSessionCodec();

  test('round-trips a partial draft with ordered A/B/C cards', () {
    const config = MultiDivinationConfig(intention: '  私密问题  ');
    final reading = _readingWithGroups(2, config: config);

    final encodedInput = codec.encodeInput(config);
    final decodedInput = codec.decodeInput(encodedInput);
    final encodedOutcome = codec.encodeOutcome(reading);
    final decoded = codec.decodeOutcome(encodedOutcome, decodedInput);

    expect(decodedInput.normalizedIntention, '私密问题');
    expect(decoded.groups, hasLength(2));
    expect(decoded.groups.first.cards.map((card) => card.slot.code), <String>[
      'A',
      'B',
      'C',
    ]);
    expect(decoded.groups.first.lineValue, reading.groups.first.lineValue);
    expect(
      decoded.groups.first.cards.map((card) => card.card.id),
      reading.groups.first.cards.map((card) => card.card.id),
    );
    expect(decoded.isComplete, isFalse);
    expect(encodedOutcome['complete'], isFalse);
    expect(encodedOutcome['primaryHexagramId'], isNull);
    expect(encodedOutcome['changedHexagramId'], isNull);
  });

  test('round-trips a complete reading with derived hexagram ids', () {
    final reading = _readingWithGroups(6);
    final encoded = codec.encodeOutcome(reading);

    expect(encoded['groupCount'], 6);
    expect(encoded['complete'], isTrue);
    expect(encoded['primaryHexagramId'], reading.primaryHexagram!.id);
    expect(encoded['changedHexagramId'], reading.changedHexagram!.id);
    expect(
      encoded['contentVersion'],
      MultiDivinationContentCatalog.contentVersion,
    );

    final decoded = codec.decodeOutcome(
      encoded,
      codec.decodeInput(codec.encodeInput(reading.config)),
    );
    expect(decoded.isComplete, isTrue);
    expect(decoded.lineValues, reading.lineValues);
    expect(decoded.movingLineIndexes, reading.movingLineIndexes);
    expect(decoded.primaryHexagram, same(reading.primaryHexagram));
    expect(decoded.changedHexagram, same(reading.changedHexagram));
  });

  test('round-trips the one-time deck order for a generated draft', () {
    final reading =
        MultiDivinationReader(
          SequenceRandomSource(<int>[...List<int>.filled(77, 0), 0, 0, 0]),
        ).appendGroup(
          MultiDivinationReading(config: const MultiDivinationConfig()),
        );

    final encoded = codec.encodeOutcome(reading);
    final decoded = codec.decodeOutcome(
      encoded,
      codec.decodeInput(codec.encodeInput(reading.config)),
    );

    expect(encoded['deckOrder'], hasLength(TarotDeck.standard.length));
    expect(decoded.deckOrder, orderedEquals(reading.deckOrder!));
  });

  test(
    'rejects duplicate cards, forged derived fields, and malformed sequences',
    () {
      final reading = _readingWithGroups(2);
      final valid = codec.encodeOutcome(reading);
      final groups = (valid['groups']! as List<Object?>);
      final firstGroup = Map<String, Object?>.from(groups.first! as Map);
      final firstCards = (firstGroup['cards']! as List<Object?>);
      final firstCard = Map<String, Object?>.from(firstCards.first! as Map);

      final duplicateCard = <String, Object?>{
        ...valid,
        'groups': <Object?>[
          <String, Object?>{
            ...firstGroup,
            'cards': <Object?>[firstCard, firstCards[1], firstCards[2]],
          },
          <String, Object?>{
            ...Map<String, Object?>.from(groups[1]! as Map),
            'cards': <Object?>[
              firstCard,
              (groups[1]! as Map)['cards'] is List
                  ? ((groups[1]! as Map)['cards'] as List<Object?>)[1]
                  : null,
              ((groups[1]! as Map)['cards'] as List<Object?>)[2],
            ],
          },
        ],
      };
      final forgedLine = <String, Object?>{
        ...valid,
        'groups': <Object?>[
          <String, Object?>{...firstGroup, 'lineValue': 9},
          groups[1],
        ],
      };
      final badSequence = <String, Object?>{
        ...valid,
        'groups': <Object?>[
          <String, Object?>{...firstGroup, 'sequence': 1},
          groups[1],
        ],
      };

      for (final malformed in <Map<String, Object?>>[
        duplicateCard,
        forgedLine,
        badSequence,
        <String, Object?>{...valid, 'extra': true},
        <String, Object?>{...valid, 'contentVersion': 'unknown'},
      ]) {
        expect(
          () => codec.decodeOutcome(
            malformed,
            codec.decodeInput(codec.encodeInput(reading.config)),
          ),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'rejects primary or changed ids on incomplete outcomes and input drift',
    () {
      final reading = _readingWithGroups(2);
      final valid = codec.encodeOutcome(reading);
      final withPrimary = <String, Object?>{
        ...valid,
        'primaryHexagramId': 'hexagram.01',
      };
      final withChanged = <String, Object?>{
        ...valid,
        'changedHexagramId': 'hexagram.01',
      };
      final decodedInput = codec.decodeInput(codec.encodeInput(reading.config));

      expect(
        () => codec.decodeOutcome(withPrimary, decodedInput),
        throwsFormatException,
      );
      expect(
        () => codec.decodeOutcome(withChanged, decodedInput),
        throwsFormatException,
      );
      expect(
        () => codec.decodeInput(<String, Object?>{
          ...codec.encodeInput(reading.config),
          'mode': 'unknown',
        }),
        throwsFormatException,
      );
      expect(
        () => codec.decodeInput(<String, Object?>{
          ...codec.encodeInput(reading.config),
          'extra': true,
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'summary exposes progress or structure without private input or session id',
    () {
      final reading = _readingWithGroups(
        2,
        config: const MultiDivinationConfig(intention: 'private-question'),
      );
      final session = SessionRecord(
        id: 'private-session-id',
        toolId: codec.toolId,
        schemaVersion: 1,
        ruleVersion: MultiDivinationReading.ruleVersion,
        algorithmVersion: MultiDivinationReading.algorithmVersion,
        status: SessionStatus.draft,
        input: codec.encodeInput(reading.config),
        outcome: codec.encodeOutcome(reading),
      );

      final summary = codec.summarize(session);
      expect(summary, contains('已完成 2/6 组'));
      expect(summary, isNot(contains('private-question')));
      expect(summary, isNot(contains('private-session-id')));

      final complete = SessionRecord(
        id: 'complete-session',
        toolId: codec.toolId,
        schemaVersion: 1,
        ruleVersion: MultiDivinationReading.ruleVersion,
        algorithmVersion: MultiDivinationReading.algorithmVersion,
        status: SessionStatus.completed,
        input: codec.encodeInput(const MultiDivinationConfig()),
        outcome: codec.encodeOutcome(_readingWithGroups(6)),
      );
      expect(codec.summarize(complete), contains('本卦'));
      expect(codec.summarize(complete), contains('动爻'));
      expect(codec.summarize(complete), contains('变卦'));
    },
  );
}

MultiDivinationReading _readingWithGroups(
  int count, {
  MultiDivinationConfig config = const MultiDivinationConfig(),
}) {
  var reading = MultiDivinationReading(config: config);
  for (var index = 0; index < count; index++) {
    reading = reading.append(
      MultiDivinationGroup(
        index: index,
        cards: <MultiDivinationCard>[
          for (var cardIndex = 0; cardIndex < 3; cardIndex++)
            MultiDivinationCard(
              slot: MultiDivinationCardSlot.values[cardIndex],
              card: TarotDeck.standard[index * 3 + cardIndex],
              orientation: index == 0
                  ? TarotOrientation.reversed
                  : (index + cardIndex).isEven
                  ? TarotOrientation.upright
                  : TarotOrientation.reversed,
            ),
        ],
      ),
    );
  }
  return reading;
}
