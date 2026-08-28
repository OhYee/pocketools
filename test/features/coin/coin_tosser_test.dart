import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/features/coin/domain/coin_models.dart';
import 'package:pocketools/features/coin/domain/coin_tosser.dart';

void main() {
  group('CoinTosser', () {
    test('maps unbiased binary values to stable raw heads and tails', () {
      final heads = CoinTosser(SequenceRandomSource(const <int>[0]))
          .toss(const CoinTossConfig());
      final tails = CoinTosser(SequenceRandomSource(const <int>[1]))
          .toss(const CoinTossConfig());

      expect(heads.sequence, const <CoinSide>[CoinSide.heads]);
      expect(tails.sequence, const <CoinSide>[CoinSide.tails]);
      expect(heads.stopReason, CoinStopReason.configuredCountReached);
      expect(heads.winner, isNull);
    });

    test('ordinary batch completes configured count in original order', () {
      final random = SequenceRandomSource(const <int>[
        0,
        0,
        1,
        0,
        0,
        1,
        1,
        0,
        1,
        1,
      ]);
      final result = CoinTosser(random)
          .toss(const CoinTossConfig(mode: CoinTossMode.batch, batchCount: 10));

      expect(result.sequence, const <CoinSide>[
        CoinSide.heads,
        CoinSide.heads,
        CoinSide.tails,
        CoinSide.heads,
        CoinSide.heads,
        CoinSide.tails,
        CoinSide.tails,
        CoinSide.heads,
        CoinSide.tails,
        CoinSide.tails,
      ]);
      expect(result.headsCount, 5);
      expect(result.tailsCount, 5);
      expect(result.headsRatio, 0.5);
      expect(random.consumed, 10);
    });

    test('supports the 1 and 100 ordinary batch boundaries', () {
      for (final count in <int>[1, 100]) {
        final random = SequenceRandomSource(List<int>.filled(count, 0));
        final result = CoinTosser(random)
            .toss(CoinTossConfig(mode: CoinTossMode.batch, batchCount: count));
        expect(result.tossCount, count);
        expect(random.consumed, count);
      }
    });

    test('race stops at the first side reaching its target', () {
      final random = SequenceRandomSource(const <int>[0, 1, 0, 1, 0, 1, 1]);
      final result = CoinTosser(random)
          .toss(const CoinTossConfig(mode: CoinTossMode.batch, raceTarget: 3));

      expect(result.sequence, const <CoinSide>[
        CoinSide.heads,
        CoinSide.tails,
        CoinSide.heads,
        CoinSide.tails,
        CoinSide.heads,
      ]);
      expect(result.stopReason, CoinStopReason.raceTargetReached);
      expect(result.winner, CoinSide.heads);
      expect(random.consumed, 5);
      expect(result.config.maximumTosses, 5);
    });

    test('trims custom labels without changing raw structured values', () {
      final result = CoinTosser(SequenceRandomSource(const <int>[0, 1])).toss(
        const CoinTossConfig(
          mode: CoinTossMode.batch,
          batchCount: 2,
          headsLabel: '  A  ',
          tailsLabel: '  B ',
        ),
      );

      expect(result.config.headsLabel, 'A');
      expect(result.config.tailsLabel, 'B');
      expect(result.sequence, const <CoinSide>[CoinSide.heads, CoinSide.tails]);
    });

    test('invalid configurations consume no random values', () {
      final invalid = <CoinTossConfig>[
        const CoinTossConfig(mode: CoinTossMode.batch, batchCount: 0),
        const CoinTossConfig(mode: CoinTossMode.batch, batchCount: 101),
        const CoinTossConfig(headsLabel: ' ', tailsLabel: '反面'),
        const CoinTossConfig(headsLabel: ' A ', tailsLabel: 'A'),
        const CoinTossConfig(raceTarget: 2),
        const CoinTossConfig(mode: CoinTossMode.batch, raceTarget: 101),
      ];

      for (final config in invalid) {
        final random = SequenceRandomSource(const <int>[0]);
        expect(
          () => CoinTosser(random).toss(config),
          throwsA(isA<CoinValidationException>()),
          reason: config.validate().join(' '),
        );
        expect(random.consumed, 0);
      }
    });

    test('result sequence is immutable and copied from its input', () {
      final source = <CoinSide>[CoinSide.heads];
      final result = CoinTossResult(
        config: const CoinTossConfig(),
        sequence: source,
        stopReason: CoinStopReason.configuredCountReached,
      );
      source[0] = CoinSide.tails;

      expect(result.sequence, const <CoinSide>[CoinSide.heads]);
      expect(() => result.sequence.add(CoinSide.tails), throwsUnsupportedError);
    });

    test('publishes stable rule and algorithm versions', () {
      expect(CoinTosser.ruleVersion, 'coin/1.0.0');
      expect(CoinTosser.algorithmVersion, 'random-unbiased-binary/1.0.0');
    });
  });
}
