import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/features/cards/domain/card_drawer.dart';
import 'package:pocketools/features/cards/domain/card_models.dart';
import 'package:pocketools/features/cards/presentation/card_session_codec.dart';

void main() {
  test('card session codec preserves deterministic draw order', () {
    const codec = CardSessionCodec();
    const config = CardDrawConfig(drawCount: 2, includeJokers: true);
    final result = CardDrawer(SequenceRandomSource(List<int>.filled(53, 0)))
        .draw(config);
    final input = codec.encodeInput(config);
    final outcome = codec.encodeOutcome(result);
    final decodedConfig = codec.decodeInput(input);
    final decodedResult = codec.decodeOutcome(outcome, decodedConfig);
    final session = SessionRecord(
      id: 'cards-1',
      toolId: codec.toolId,
      schemaVersion: 1,
      ruleVersion: CardDrawer.ruleVersion,
      algorithmVersion: 'random-unbiased-u32/1',
      status: SessionStatus.completed,
      input: input,
      outcome: outcome,
    );

    expect(
      decodedResult.cards.map((card) => card.id),
      result.cards.map((card) => card.id),
    );
    expect(codec.summarize(session), '扑克牌 · 抽取 2 张');
  });

  test('card session codec rejects duplicate card ids', () {
    const codec = CardSessionCodec();
    const config = CardDrawConfig(drawCount: 2);

    expect(
      () => codec.decodeOutcome(<String, Object?>{
        'cards': <Object?>['clubs-two', 'clubs-two'],
        'remainingCount': 50,
      }, config),
      throwsA(
        anyOf(
          isA<FormatException>(),
          isA<StateError>(),
          isA<ArgumentError>(),
          isA<CardValidationException>(),
        ),
      ),
    );
  });

  test('card session codec round-trips physical copies from two decks', () {
    const codec = CardSessionCodec();
    const config = CardDrawConfig(drawCount: 2, deckCount: 2);
    final result = CardDrawResult(
      config: config,
      cards: const <PlayingCard>[
        PlayingCard.standard(CardSuit.clubs, CardRank.two),
        PlayingCard.standard(CardSuit.clubs, CardRank.two, deckIndex: 2),
      ],
    );

    final decodedConfig = codec.decodeInput(codec.encodeInput(config));
    final decodedResult = codec.decodeOutcome(
      codec.encodeOutcome(result),
      decodedConfig,
    );

    expect(decodedConfig.deckCount, 2);
    expect(decodedResult.cards.map((card) => card.id), <String>[
      'clubs-two',
      'deck-2-clubs-two',
    ]);
    expect(decodedResult.remainingCount, 102);
  });

  test('card session codec rejects an inconsistent remaining count', () {
    const codec = CardSessionCodec();
    const config = CardDrawConfig(drawCount: 2);

    expect(
      () => codec.decodeOutcome(<String, Object?>{
        'cards': <Object?>['clubs-two', 'hearts-ace'],
        'remainingCount': 49,
      }, config),
      throwsA(
        anyOf(
          isA<FormatException>(),
          isA<StateError>(),
          isA<ArgumentError>(),
          isA<CardValidationException>(),
        ),
      ),
    );
  });
}
