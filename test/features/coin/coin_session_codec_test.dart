import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/features/coin/domain/coin_models.dart';
import 'package:pocketools/features/coin/presentation/coin_session_codec.dart';

void main() {
  const codec = CoinSessionCodec();

  test('round trips normalized ordinary batch input and ordered outcome', () {
    const config = CoinTossConfig(
      mode: CoinTossMode.batch,
      batchCount: 3,
      headsLabel: ' A ',
      tailsLabel: ' B ',
    );
    final result = CoinTossResult(
      config: config.normalized(),
      sequence: const <CoinSide>[
        CoinSide.heads,
        CoinSide.tails,
        CoinSide.heads,
      ],
      stopReason: CoinStopReason.configuredCountReached,
    );

    final decodedConfig = codec.decodeInput(codec.encodeInput(config));
    final decodedResult = codec.decodeOutcome(
      codec.encodeOutcome(result),
      decodedConfig,
    );

    expect(decodedConfig.headsLabel, 'A');
    expect(decodedConfig.tailsLabel, 'B');
    expect(decodedResult.sequence, result.sequence);
    expect(decodedResult.headsCount, 2);
    expect(decodedResult.tailsCount, 1);
  });

  test('round trips a strict race result', () {
    const config = CoinTossConfig(mode: CoinTossMode.batch, raceTarget: 2);
    final result = CoinTossResult(
      config: config,
      sequence: const <CoinSide>[
        CoinSide.tails,
        CoinSide.heads,
        CoinSide.tails,
      ],
      stopReason: CoinStopReason.raceTargetReached,
      winner: CoinSide.tails,
    );

    final decoded = codec.decodeOutcome(codec.encodeOutcome(result), config);

    expect(decoded.winner, CoinSide.tails);
    expect(decoded.tossCount, 3);
  });

  test('rejects malformed input fields and explicit invalid values', () {
    final valid = <String, Object?>{
      'mode': 'batch',
      'batchCount': 3,
      'headsLabel': '正面',
      'tailsLabel': '反面',
      'raceTarget': null,
    };
    final malformed = <Map<String, Object?>>[
      <String, Object?>{...valid, 'mode': 'other'},
      <String, Object?>{...valid, 'batchCount': 0},
      <String, Object?>{...valid, 'headsLabel': ' '},
      <String, Object?>{...valid, 'tailsLabel': '正面'},
      <String, Object?>{...valid, 'raceTarget': '2'},
      <String, Object?>{...valid, 'raceTarget': 101},
      <String, Object?>{...valid}..remove('headsLabel'),
    ];

    for (final payload in malformed) {
      expect(() => codec.decodeInput(payload), throwsFormatException);
    }
  });

  test('rejects inconsistent ordinary outcomes', () {
    const config = CoinTossConfig(mode: CoinTossMode.batch, batchCount: 3);
    final valid = <String, Object?>{
      'sequence': <Object?>['heads', 'tails', 'heads'],
      'headsCount': 2,
      'tailsCount': 1,
      'stopReason': 'configuredCountReached',
      'winner': null,
    };
    final malformed = <Map<String, Object?>>[
      <String, Object?>{...valid, 'sequence': <Object?>[]},
      <String, Object?>{
        ...valid,
        'sequence': <Object?>['heads', 'tails'],
      },
      <String, Object?>{
        ...valid,
        'sequence': <Object?>['heads', 'edge', 'heads'],
      },
      <String, Object?>{...valid, 'headsCount': 1},
      <String, Object?>{...valid, 'tailsCount': 2},
      <String, Object?>{...valid, 'stopReason': 'raceTargetReached'},
      <String, Object?>{...valid, 'winner': 'heads'},
    ];

    for (final payload in malformed) {
      expect(() => codec.decodeOutcome(payload, config), throwsFormatException);
    }
  });

  test('rejects race sequences that do not stop at the first target', () {
    const config = CoinTossConfig(mode: CoinTossMode.batch, raceTarget: 2);
    final malformed = <Map<String, Object?>>[
      <String, Object?>{
        'sequence': <Object?>['heads', 'tails'],
        'headsCount': 1,
        'tailsCount': 1,
        'stopReason': 'raceTargetReached',
        'winner': 'heads',
      },
      <String, Object?>{
        'sequence': <Object?>['heads', 'heads', 'tails'],
        'headsCount': 2,
        'tailsCount': 1,
        'stopReason': 'raceTargetReached',
        'winner': 'heads',
      },
      <String, Object?>{
        'sequence': <Object?>['heads', 'tails', 'heads'],
        'headsCount': 2,
        'tailsCount': 1,
        'stopReason': 'raceTargetReached',
        'winner': 'tails',
      },
    ];

    for (final payload in malformed) {
      expect(() => codec.decodeOutcome(payload, config), throwsFormatException);
    }
  });

  test('history summary preserves labels sequence counts and versions', () {
    final session = SessionRecord(
      id: 'private-local-id',
      toolId: 'coin',
      schemaVersion: 1,
      ruleVersion: 'coin/1.0.0',
      algorithmVersion: 'random-unbiased-binary/1.0.0',
      status: SessionStatus.completed,
      input: const <String, Object?>{
        'mode': 'batch',
        'batchCount': 3,
        'headsLabel': 'A',
        'tailsLabel': 'B',
        'raceTarget': null,
      },
      outcome: const <String, Object?>{
        'sequence': <Object?>['heads', 'tails', 'heads'],
        'headsCount': 2,
        'tailsCount': 1,
        'stopReason': 'configuredCountReached',
        'winner': null,
      },
    );

    final summary = codec.summarize(session);

    expect(summary, contains('A 2 / B 1'));
    expect(summary, contains('heads,tails,heads'));
    expect(summary, contains('coin/1.0.0'));
    expect(summary, contains('random-unbiased-binary/1.0.0'));
    expect(summary, isNot(contains('private-local-id')));
  });
}
