import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/features/cards/domain/card_models.dart';
import 'package:pocketools/features/cards/presentation/card_session_codec.dart';

void main() {
  const codec = CardSessionCodec();

  test('card codec rejects inconsistent input schema and deck size', () {
    expect(
      () => codec.decodeInput(<String, Object?>{
        'drawCount': 2,
        'includeJokers': false,
        'deckSize': 54,
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => codec.decodeInput(<String, Object?>{
        'drawCount': '2',
        'includeJokers': false,
        'deckSize': 52,
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('card codec rejects invalid cards and card-count mismatches', () {
    expect(
      () => codec.decodeOutcome(<String, Object?>{
        'cards': <Object?>[],
        'remainingCount': 52,
      }, const CardDrawConfig(drawCount: 2)),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => codec.decodeOutcome(<String, Object?>{
        'cards': <Object?>['joker-small'],
        'remainingCount': 51,
      }, const CardDrawConfig(drawCount: 1)),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => codec.decodeOutcome(<String, Object?>{
        'cards': <Object?>['stars-one'],
        'remainingCount': 51,
      }, const CardDrawConfig(drawCount: 1)),
      throwsA(isA<FormatException>()),
    );
  });

  test('card codec accepts a partial interactive draw up to its target', () {
    final result = codec.decodeOutcome(<String, Object?>{
      'cards': <Object?>['clubs-two'],
      'remainingCount': 51,
    }, const CardDrawConfig(drawCount: 2));

    expect(result.cards.map((card) => card.id), <String>['clubs-two']);
    expect(result.config.drawCount, 2);
    expect(result.remainingCount, 51);
  });

  test('card codec rejects illegal and duplicate jokers', () {
    final invalidOutcomes = <Map<String, Object?>>[
      <String, Object?>{
        'cards': <Object?>['joker-medium'],
        'remainingCount': 53,
      },
      <String, Object?>{
        'cards': <Object?>['joker-small', 'joker-small'],
        'remainingCount': 52,
      },
    ];

    expect(
      () => codec.decodeOutcome(
        invalidOutcomes[0],
        const CardDrawConfig(drawCount: 1, includeJokers: true),
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => codec.decodeOutcome(
        invalidOutcomes[1],
        const CardDrawConfig(drawCount: 2, includeJokers: true),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('card codec accepts both legal jokers only in a 54-card deck', () {
    final result = codec.decodeOutcome(<String, Object?>{
      'cards': <Object?>['joker-small', 'joker-big'],
      'remainingCount': 52,
    }, const CardDrawConfig(drawCount: 2, includeJokers: true));

    expect(result.cards.map((card) => card.id), <String>[
      'joker-small',
      'joker-big',
    ]);
    expect(result.remainingCount, 52);
  });

  test('card codec reads the phase-one schema-v1 payload without deckSize', () {
    final config = codec.decodeInput(<String, Object?>{
      'drawCount': 2,
      'includeJokers': false,
    });
    final result = codec.decodeOutcome(<String, Object?>{
      'cards': <Object?>['clubs-two', 'hearts-ace'],
      'remainingCount': 50,
    }, config);

    expect(config.deckSize, 52);
    expect(result.cards.map((card) => card.id), <String>[
      'clubs-two',
      'hearts-ace',
    ]);
    expect(result.remainingCount, 50);
  });

  test(
    'card codec rejects missing required legacy fields and extra jokers',
    () {
      expect(
        () => codec.decodeInput(<String, Object?>{
          'drawCount': 1,
          'deckSize': 52,
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => codec.decodeOutcome(<String, Object?>{
          'cards': <Object?>['joker-small'],
          'remainingCount': 51,
        }, const CardDrawConfig(drawCount: 1)),
        throwsA(isA<FormatException>()),
      );
    },
  );
}
