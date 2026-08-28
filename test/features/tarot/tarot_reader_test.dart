import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/features/tarot/domain/tarot_deck.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';
import 'package:pocketools/features/tarot/domain/tarot_reader.dart';

void main() {
  group('TarotReader', () {
    test('all-zero fixed vector preserves ordered three-card positions', () {
      final entropy = <int>[...List<int>.filled(77, 0), 1, 0, 1];
      final random = SequenceRandomSource(entropy);
      final result = TarotReader(random, contentVersion: '1.0.0').draw(
        const TarotReadingConfig(spread: TarotSpreadPreset.pastPresentFuture),
      );

      expect(result.cards.map((drawn) => drawn.card.id), <String>[
        'major-01-magician',
        'major-02-high-priestess',
        'major-03-empress',
      ]);
      expect(result.cards.map((drawn) => drawn.position), <TarotPosition>[
        TarotPosition.past,
        TarotPosition.present,
        TarotPosition.future,
      ]);
      expect(result.cards.map((drawn) => drawn.orientation), <TarotOrientation>[
        TarotOrientation.reversed,
        TarotOrientation.upright,
        TarotOrientation.reversed,
      ]);
      expect(result.cards.map((drawn) => drawn.card.id).toSet(), hasLength(3));
      expect(random.consumed, 80);
    });

    test('reversals disabled never requests direction entropy', () {
      final random = SequenceRandomSource(List<int>.filled(77, 0));
      final result = TarotReader(random, contentVersion: '1.0.0').draw(
        const TarotReadingConfig(
          spread: TarotSpreadPreset.pastPresentFuture,
          useReversals: false,
        ),
      );

      expect(random.consumed, 77);
      expect(
        result.cards.every(
          (drawn) => drawn.orientation == TarotOrientation.upright,
        ),
        isTrue,
      );
    });

    test('drawOne assigns the requested position without batch shuffling', () {
      final random = SequenceRandomSource(<int>[0, 1, 0, 0]);
      final reader = TarotReader(random, contentVersion: '1.0.0');
      const config = TarotReadingConfig(
        spread: TarotSpreadPreset.pastPresentFuture,
      );

      final past = reader.drawOne(config, position: TarotPosition.past);
      final present = reader.drawOne(
        config,
        position: TarotPosition.present,
        excludedCardIds: <String>[past.card.id],
      );

      expect(past.position, TarotPosition.past);
      expect(present.position, TarotPosition.present);
      expect(past.card.id, isNot(present.card.id));
      expect(random.consumed, 4);
    });

    test('minor arcana disabled shuffles only the 22 major cards', () {
      final random = SequenceRandomSource(<int>[
        ...List<int>.filled(21, 0),
        1,
        0,
        1,
      ]);
      final result = TarotReader(random, contentVersion: '1.0.0').draw(
        const TarotReadingConfig(
          spread: TarotSpreadPreset.pastPresentFuture,
          includeMinorArcana: false,
        ),
      );

      expect(
        result.cards.every((drawn) => drawn.card.arcana == TarotArcana.major),
        isTrue,
      );
      expect(result.cards.map((drawn) => drawn.card.id), <String>[
        'major-01-magician',
        'major-02-high-priestess',
        'major-03-empress',
      ]);
      expect(random.consumed, 24);
      expect(result.config.includeMinorArcana, isFalse);
    });

    test(
      'each drawn card consumes exactly one independent direction value',
      () {
        final single = SequenceRandomSource(<int>[
          ...List<int>.filled(77, 0),
          1,
        ]);
        TarotReader(single, contentVersion: '1.0.0').draw(
          const TarotReadingConfig(spread: TarotSpreadPreset.singleQuestion),
        );

        final triple = SequenceRandomSource(<int>[
          ...List<int>.filled(77, 0),
          0,
          1,
          0,
        ]);
        TarotReader(triple, contentVersion: '1.0.0').draw(
          const TarotReadingConfig(spread: TarotSpreadPreset.pastPresentFuture),
        );

        expect(single.consumed, 78);
        expect(triple.consumed, 80);
      },
    );

    test('invalid deck and content version consume no random values', () {
      final random = _CountingRandomSource();

      expect(
        () => TarotReader(
          random,
          contentVersion: '',
          deck: TarotDeck.standard.take(77),
        ).draw(const TarotReadingConfig()),
        throwsA(isA<TarotValidationException>()),
      );
      expect(
        () => TarotReader(random, contentVersion: '1.0.0').draw(
          TarotReadingConfig(
            intention: 'x' * (TarotReadingConfig.maximumIntentionLength + 1),
          ),
        ),
        throwsA(isA<TarotValidationException>()),
      );
      expect(random.consumed, 0);
    });

    test('result card collection is immutable', () {
      final result = TarotReader(
        SequenceRandomSource(<int>[...List<int>.filled(77, 0), 0]),
        contentVersion: '1.0.0',
      ).draw(const TarotReadingConfig());

      expect(
        () => result.cards.add(result.cards.single),
        throwsUnsupportedError,
      );
    });
  });
}

final class _CountingRandomSource implements RandomSource {
  var consumed = 0;

  @override
  int nextInt(int maxExclusive) {
    consumed++;
    return 0;
  }
}
