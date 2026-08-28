import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/features/cards/presentation/card_session_codec.dart';

void main() {
  const codec = CardSessionCodec();

  test('schema-v1 input without deckSize restores a 52-card draw', () {
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

  test('schema-v1 input without deckSize restores a 54-card draw', () {
    final config = codec.decodeInput(<String, Object?>{
      'drawCount': 2,
      'includeJokers': true,
    });
    final result = codec.decodeOutcome(<String, Object?>{
      'cards': <Object?>['joker-small', 'joker-big'],
      'remainingCount': 52,
    }, config);

    expect(config.deckSize, 54);
    expect(result.cards.map((card) => card.id), <String>[
      'joker-small',
      'joker-big',
    ]);
    expect(result.remainingCount, 52);
  });
}
