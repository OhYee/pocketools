import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/features/dice/domain/dice_models.dart';
import 'package:pocketools/features/dice/domain/dice_roller.dart';
import 'package:pocketools/features/dice/presentation/dice_session_codec.dart';

void main() {
  test('dice session codec preserves input, roll order, and summary', () {
    const codec = DiceSessionCodec();
    const config = DicePoolConfig(
      diceCount: 2,
      diceSides: 20,
      aggregation: DiceAggregation.keepHighest,
      keepCount: 1,
      modifier: 3,
      dc: 15,
    );
    final result = DiceRoller(SequenceRandomSource(const <int>[4, 15]))
        .roll(config);
    final input = codec.encodeInput(config);
    final outcome = codec.encodeOutcome(result);
    final decodedConfig = codec.decodeInput(input);
    final decodedResult = codec.decodeOutcome(outcome, decodedConfig);
    final session = SessionRecord(
      id: 'dice-1',
      toolId: codec.toolId,
      schemaVersion: 1,
      ruleVersion: DiceRoller.ruleVersion,
      algorithmVersion: DiceRoller.algorithmVersion,
      status: SessionStatus.completed,
      input: input,
      outcome: outcome,
    );

    expect(decodedConfig.mode, DiceMode.advantage);
    expect(decodedResult.rolls.map((roll) => roll.value), <int>[5, 16]);
    expect(decodedResult.rolls.map((roll) => roll.isKept), <bool>[false, true]);
    expect(decodedResult.total, 19);
    expect(codec.summarize(session), '优势检定 · 总值 19');
  });

  test('fixed 4d20 vector round-trips stable kept indices and total 41', () {
    const codec = DiceSessionCodec();
    const config = DicePoolConfig(
      diceCount: 4,
      diceSides: 20,
      aggregation: DiceAggregation.keepHighest,
      keepCount: 3,
      modifier: 5,
      dc: 35,
    );
    final result = DiceRoller(SequenceRandomSource(const <int>[7, 15, 3, 11]))
        .roll(config);

    final decoded = codec.decodeOutcome(
      codec.encodeOutcome(result),
      codec.decodeInput(codec.encodeInput(config)),
    );

    expect(decoded.rolls.map((roll) => roll.value), <int>[8, 16, 4, 12]);
    expect(decoded.rolls.map((roll) => roll.isKept), <bool>[
      true,
      true,
      false,
      true,
    ]);
    expect(decoded.keptInAggregationOrder.map((roll) => roll.index), <int>[
      2,
      4,
      1,
    ]);
    expect(decoded.total, 41);
    expect(decoded.dcOutcome, DcOutcome.reached);
  });

  test('strict codec rejects polluted mode, rolls, kept flags and total', () {
    const codec = DiceSessionCodec();
    final validInput = codec.encodeInput(DicePoolConfig.advantage(dc: 15));
    final validOutcome = codec.encodeOutcome(
      DiceRoller(SequenceRandomSource(const <int>[4, 15]))
          .roll(DicePoolConfig.advantage(dc: 15)),
    );

    for (final invalidInput in <Map<String, Object?>>[
      <String, Object?>{...validInput, 'mode': 'normal'},
      <String, Object?>{...validInput, 'unexpected': true},
      <String, Object?>{...validInput, 'diceCount': '2'},
    ]) {
      expect(() => codec.decodeInput(invalidInput), throwsFormatException);
    }

    final config = codec.decodeInput(validInput);
    for (final invalidOutcome in <Map<String, Object?>>[
      <String, Object?>{...validOutcome, 'total': 18},
      <String, Object?>{
        ...validOutcome,
        'keptOrder': <Object?>[1],
      },
      <String, Object?>{
        ...validOutcome,
        'rolls': <Object?>[
          <String, Object?>{'index': 1, 'value': 5, 'kept': true},
          <String, Object?>{'index': 2, 'value': 16, 'kept': true},
        ],
      },
      <String, Object?>{...validOutcome, 'dcOutcome': 'notReached'},
      <String, Object?>{...validOutcome, 'unexpected': true},
    ]) {
      expect(
        () => codec.decodeOutcome(invalidOutcome, config),
        throwsFormatException,
      );
    }
  });
}
