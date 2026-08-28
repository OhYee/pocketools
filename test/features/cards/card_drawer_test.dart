import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/features/cards/domain/card_drawer.dart';
import 'package:pocketools/features/cards/domain/card_models.dart';

void main() {
  group('standard deck', () {
    test('defaults to a 52-card deck without jokers', () {
      const config = CardDrawConfig(drawCount: 1);
      final random = _MaximumRandomSource();
      final result = CardDrawer(random).draw(config);

      expect(config.includeJokers, isFalse);
      expect(config.deckSize, 52);
      expect(result.cards.single.id, 'clubs-two');
      expect(result.remainingCount, 51);
      expect(random.consumed, 51);
    });

    test('draws 52 unique neutral cards without jokers', () {
      final result = CardDrawer(SequenceRandomSource(List<int>.filled(51, 0)))
          .draw(const CardDrawConfig(drawCount: 52));

      expect(result.cards, hasLength(52));
      expect(result.cards.map((card) => card.id).toSet(), hasLength(52));
      expect(result.cards.where((card) => card.isJoker), isEmpty);
      expect(result.remainingCount, 0);
    });

    test('adds small and big jokers for a 54-card deck', () {
      final result = CardDrawer(SequenceRandomSource(List<int>.filled(53, 0)))
          .draw(const CardDrawConfig(drawCount: 54, includeJokers: true));

      expect(result.cards, hasLength(54));
      expect(result.cards.map((card) => card.id).toSet(), hasLength(54));
      expect(
        result.cards.where((card) => card.isJoker).map((card) => card.joker),
        containsAll(<JokerKind>[JokerKind.small, JokerKind.big]),
      );
    });

    test('draws distinct physical copies across multiple decks', () {
      const config = CardDrawConfig(drawCount: 104, deckCount: 2);
      final result = CardDrawer(SequenceRandomSource(List<int>.filled(103, 0)))
          .draw(config);

      expect(result.cards, hasLength(104));
      expect(result.cards.map((card) => card.id).toSet(), hasLength(104));
      expect(
        result.cards
            .where(
              (card) =>
                  card.suit == CardSuit.clubs && card.rank == CardRank.two,
            )
            .map((card) => card.deckIndex),
        containsAll(<int>[1, 2]),
      );
      expect(result.remainingCount, 0);
    });

    test('draw order is deterministic for the same random sequence', () {
      const config = CardDrawConfig(drawCount: 5, includeJokers: true);
      final sequence = List<int>.generate(53, (index) => index % (54 - index));
      final first = CardDrawer(SequenceRandomSource(sequence)).draw(config);
      final second = CardDrawer(SequenceRandomSource(sequence)).draw(config);

      expect(
        first.cards.map((card) => card.id),
        second.cards.map((card) => card.id),
      );
      expect(() => first.cards.add(first.cards.first), throwsUnsupportedError);
    });

    test('all-zero fixed vector has an explicit stable order', () {
      final result = CardDrawer(SequenceRandomSource(List<int>.filled(51, 0)))
          .draw(const CardDrawConfig(drawCount: 5));

      expect(result.cards.map((card) => card.id), <String>[
        'clubs-three',
        'clubs-four',
        'clubs-five',
        'clubs-six',
        'clubs-seven',
      ]);
      expect(result.remainingCount, 47);
    });
  });

  test('validates draw count against the active deck size', () {
    expect(const CardDrawConfig(drawCount: 1).validate(), isEmpty);
    expect(const CardDrawConfig(drawCount: 52).validate(), isEmpty);
    expect(
      const CardDrawConfig(drawCount: 54, includeJokers: true).validate(),
      isEmpty,
    );
    expect(const CardDrawConfig(drawCount: 0).validate(), isNotEmpty);
    expect(const CardDrawConfig(drawCount: 53).validate(), isNotEmpty);
    expect(
      const CardDrawConfig(drawCount: 55, includeJokers: true).validate(),
      isNotEmpty,
    );
  });

  test('invalid draw count consumes no randomness', () {
    final random = _RecordingRandomSource();

    expect(
      () => CardDrawer(random).draw(const CardDrawConfig(drawCount: 0)),
      throwsA(isA<CardValidationException>()),
    );
    expect(random.consumed, 0);
  });

  test('random failure exposes no partial card result', () {
    final random = _ThrowingRandomSource(throwAfter: 3);

    expect(
      () => CardDrawer(random).draw(const CardDrawConfig(drawCount: 1)),
      throwsStateError,
    );
    expect(random.consumed, 3);
  });
}

final class _MaximumRandomSource implements RandomSource {
  var consumed = 0;

  @override
  int nextInt(int maxExclusive) {
    consumed++;
    return maxExclusive - 1;
  }
}

final class _RecordingRandomSource implements RandomSource {
  var consumed = 0;

  @override
  int nextInt(int maxExclusive) {
    consumed++;
    return 0;
  }
}

final class _ThrowingRandomSource implements RandomSource {
  _ThrowingRandomSource({required this.throwAfter});

  final int throwAfter;
  var consumed = 0;

  @override
  int nextInt(int maxExclusive) {
    if (consumed == throwAfter) throw StateError('Random source failed.');
    consumed++;
    return 0;
  }
}
