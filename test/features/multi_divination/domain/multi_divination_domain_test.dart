import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_hexagrams.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_models.dart';
import 'package:pocketools/features/multi_divination/content/multi_divination_content_catalog.dart';
import 'package:pocketools/features/multi_divination/content/multi_divination_interpretation.dart';
import 'package:pocketools/features/multi_divination/domain/multi_divination_models.dart';
import 'package:pocketools/features/multi_divination/domain/multi_divination_reader.dart';
import 'package:pocketools/features/tarot/domain/tarot_deck.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';

void main() {
  group('Multi-divination three-card line rules', () {
    test('counts upright cards and maps 0, 1, 2, and 3 to 6, 7, 8, 9', () {
      const expected = <int, LiuyaoLineKind>{
        0: LiuyaoLineKind.oldYin,
        1: LiuyaoLineKind.youngYang,
        2: LiuyaoLineKind.youngYin,
        3: LiuyaoLineKind.oldYang,
      };

      for (final entry in expected.entries) {
        final group = _groupForUprightCount(entry.key, index: entry.key);
        expect(group.uprightCount, entry.key);
        expect(group.lineValue, entry.value.value);
        expect(group.lineKind, entry.value);
        expect(group.cards.map((card) => card.orientationBit), hasLength(3));
      }
    });

    test('requires exactly A, B, and C and never treats them as coins', () {
      final group = _groupForUprightCount(1, index: 0);

      expect(group.cards.map((card) => card.slot.code), <String>[
        'A',
        'B',
        'C',
      ]);
      final reading = MultiDivinationReading(
        config: const MultiDivinationConfig(),
        groups: <MultiDivinationGroup>[group],
      );
      expect(reading.liuyaoLines.single.source, LiuyaoLineSource.manualValue);
      expect(reading.liuyaoLines.single.coins, isNull);
      expect(
        () => MultiDivinationGroup(
          index: 0,
          cards: <MultiDivinationCard>[
            group.cards.first,
            group.cards.first,
            group.cards.last,
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('Multi-divination deck rules', () {
    test('shuffles the complete tarot deck once and draws 18 unique cards', () {
      final random = _TrackingRandomSource();
      final reader = MultiDivinationReader(random);
      var reading = MultiDivinationReading(
        config: const MultiDivinationConfig(),
      );

      for (
        var index = 0;
        index < MultiDivinationReading.groupCapacity;
        index++
      ) {
        reading = reader.appendGroup(reading);
      }

      expect(reading.isComplete, isTrue);
      final cards = reading.groups.expand((group) => group.cards).toList();
      expect(cards, hasLength(18));
      expect(cards.map((card) => card.card.id).toSet(), hasLength(18));
      expect(
        cards.every((card) => TarotDeck.byId.containsKey(card.card.id)),
        isTrue,
      );
      expect(random.maxima, <int>[
        for (var max = TarotDeck.standard.length; max >= 2; max--) max,
        ...List<int>.filled(18, 2),
      ]);

      expect(() => reader.appendGroup(reading), throwsStateError);
      expect(random.consumed, 95);
    });

    test('persists the one-time deck order for continued drafts', () {
      final firstRandom = _TrackingRandomSource();
      final first = MultiDivinationReader(firstRandom).appendGroup(
        MultiDivinationReading(config: const MultiDivinationConfig()),
      );

      expect(first.deckOrder, hasLength(TarotDeck.standard.length));

      final continuationRandom = _OrientationOnlyRandomSource();
      final second = MultiDivinationReader(continuationRandom)
          .appendGroup(first);

      expect(continuationRandom.maxima, <int>[2, 2, 2]);
      expect(
        second.groups[1].cards.map((card) => card.card.id),
        isNot(
          anyOf(
            contains(first.groups.first.cards[0].card.id),
            contains(first.groups.first.cards[1].card.id),
            contains(first.groups.first.cards[2].card.id),
          ),
        ),
      );
      expect(second.deckOrder, orderedEquals(first.deckOrder!));
    });

    test(
      'appends groups in initial-to-top order and rejects global duplicates',
      () {
        var reading = MultiDivinationReading(
          config: const MultiDivinationConfig(),
        );
        for (var index = 0; index < 2; index++) {
          reading = reading.append(
            _groupForUprightCount(index, index: index, cardOffset: index * 3),
          );
        }

        expect(reading.nextGroupIndex, 2);
        expect(reading.groups.map((group) => group.lineNumber), <int>[1, 2]);
        expect(reading.primaryHexagram, isNull);
        expect(reading.changedHexagram, isNull);
        expect(
          () =>
              reading.append(_groupForUprightCount(3, index: 2, cardOffset: 0)),
          throwsArgumentError,
        );
      },
    );

    test(
      'resolves primary, moving lines, and changed hexagram after six groups',
      () {
        const values = <int>[6, 7, 8, 9, 7, 8];
        var reading = MultiDivinationReading(
          config: const MultiDivinationConfig(),
        );
        for (var index = 0; index < values.length; index++) {
          reading = reading.append(
            _groupForLineValue(
              values[index],
              index: index,
              cardOffset: index * 3,
            ),
          );
        }

        expect(reading.isComplete, isTrue);
        expect(reading.lineValues, values);
        expect(reading.movingLineIndexes, <int>[0, 3]);
        final expectedLines = <LiuyaoLine>[
          for (var index = 0; index < values.length; index++)
            LiuyaoLine(
              index: index,
              value: values[index],
              source: LiuyaoLineSource.manualValue,
            ),
        ];
        expect(
          reading.primaryHexagram,
          same(LiuyaoHexagrams.resolve(expectedLines)),
        );
        expect(
          reading.changedHexagram,
          same(LiuyaoHexagrams.resolve(expectedLines, changed: true)),
        );
      },
    );
  });

  group('Multi-divination interpretation content', () {
    test(
      'standard mode composes only A1-A6 with existing tarot interpretations',
      () {
        var reading = MultiDivinationReading(
          config: const MultiDivinationConfig(),
        );
        for (
          var index = 0;
          index < MultiDivinationReading.groupCapacity;
          index++
        ) {
          reading = reading.append(
            _groupForUprightCount(
              index % 4,
              index: index,
              cardOffset: index * 3,
            ),
          );
        }

        expect(MultiDivinationContentCatalog.validate(), isEmpty);
        final explanation = const MultiDivinationInterpretationComposer()
            .resolve(reading);

        expect(explanation.interpretedSlots, <MultiDivinationCardSlot>[
          MultiDivinationCardSlot.a,
        ]);
        expect(explanation.groups, hasLength(6));
        expect(explanation.primaryInterpretations, hasLength(6));
        expect(
          explanation.primaryInterpretations.map(
            (interpretation) => interpretation.drawnCard.card.id,
          ),
          reading.groups.map((group) => group.primaryCard.card.id),
        );
        expect(
          explanation.groups.every(
            (group) => group.interpretations.length == 1,
          ),
          isTrue,
        );
        expect(explanation.combinationHint, isNot(contains('内容边界')));
        expect(explanation.combinationHint, isNot(contains('专业建议')));
      },
    );
  });
}

MultiDivinationGroup _groupForUprightCount(
  int uprightCount, {
  required int index,
  int cardOffset = 0,
}) {
  final orientations = <TarotOrientation>[
    for (var cardIndex = 0; cardIndex < 3; cardIndex++)
      cardIndex < uprightCount
          ? TarotOrientation.upright
          : TarotOrientation.reversed,
  ];
  return MultiDivinationGroup(
    index: index,
    cards: <MultiDivinationCard>[
      for (var cardIndex = 0; cardIndex < 3; cardIndex++)
        MultiDivinationCard(
          slot: MultiDivinationCardSlot.values[cardIndex],
          card: TarotDeck.standard[cardOffset + cardIndex],
          orientation: orientations[cardIndex],
        ),
    ],
  );
}

MultiDivinationGroup _groupForLineValue(
  int value, {
  required int index,
  required int cardOffset,
}) {
  final kind = LiuyaoLineKind.fromValue(value);
  final uprightCount = switch (kind) {
    LiuyaoLineKind.oldYin => 0,
    LiuyaoLineKind.youngYang => 1,
    LiuyaoLineKind.youngYin => 2,
    LiuyaoLineKind.oldYang => 3,
  };
  return _groupForUprightCount(
    uprightCount,
    index: index,
    cardOffset: cardOffset,
  );
}

final class _TrackingRandomSource implements RandomSource {
  final List<int> maxima = <int>[];

  int get consumed => maxima.length;

  @override
  int nextInt(int maxExclusive) {
    maxima.add(maxExclusive);
    return 0;
  }
}

final class _OrientationOnlyRandomSource implements RandomSource {
  final List<int> maxima = <int>[];

  @override
  int nextInt(int maxExclusive) {
    maxima.add(maxExclusive);
    if (maxExclusive != 2) {
      throw StateError('A restored draft must not reshuffle its deck.');
    }
    return 0;
  }
}
