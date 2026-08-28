import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';

void main() {
  group('unbiased bounded integers', () {
    test('rejects uint32 values outside the unbiased limit', () {
      final entropy = _SequenceEntropy(<int>[0xffffffff, 5]);
      final random = UnbiasedRandomSource(entropy);

      expect(random.nextInt(10), 5);
      expect(entropy.consumed, 2);
    });

    test('accepts both edges immediately below the rejection limit', () {
      const uint32Range = 0x100000000;
      const bound = 10;
      const limit = uint32Range - (uint32Range % bound);
      final entropy = _SequenceEntropy(<int>[0, limit - 1]);
      final random = UnbiasedRandomSource(entropy);

      expect(random.nextInt(bound), 0);
      expect(random.nextInt(bound), 9);
      expect(entropy.consumed, 2);
    });

    test('rejects the limit and uint32 maximum before accepting', () {
      const uint32Range = 0x100000000;
      const bound = 10;
      const limit = uint32Range - (uint32Range % bound);
      final entropy = _SequenceEntropy(<int>[limit, 0xffffffff, 7]);
      final random = UnbiasedRandomSource(entropy);

      expect(random.nextInt(bound), 7);
      expect(entropy.consumed, 3);
    });

    test('does not reject when the bound divides the uint32 range', () {
      final entropy = _SequenceEntropy(<int>[0xffffffff]);
      final random = UnbiasedRandomSource(entropy);

      expect(random.nextInt(256), 255);
      expect(entropy.consumed, 1);
    });

    test('supports one and the complete uint32 range', () {
      final entropy = _SequenceEntropy(<int>[0xffffffff, 0xffffffff]);
      final random = UnbiasedRandomSource(entropy);

      expect(random.nextInt(1), 0);
      expect(random.nextInt(0x100000000), 0xffffffff);
    });

    test('rejects invalid bounds before consuming entropy', () {
      final entropy = _SequenceEntropy(<int>[0]);
      final random = UnbiasedRandomSource(entropy);

      expect(() => random.nextInt(0), throwsRangeError);
      expect(() => random.nextInt(-1), throwsRangeError);
      expect(() => random.nextInt(0x100000001), throwsRangeError);
      expect(entropy.consumed, 0);
    });

    test('rejects entropy outside uint32', () {
      expect(
        () => UnbiasedRandomSource(_SequenceEntropy(<int>[-1])).nextInt(2),
        throwsStateError,
      );
      expect(
        () =>
            UnbiasedRandomSource(_SequenceEntropy(<int>[0x100000000]))
                .nextInt(2),
        throwsStateError,
      );
    });

    test('propagates entropy failure after a rejected candidate', () {
      final entropy = _FailingEntropy(<int>[0xffffffff]);
      final random = UnbiasedRandomSource(entropy);

      expect(() => random.nextInt(10), throwsStateError);
      expect(entropy.consumed, 1);
    });

    test('secure production adapter stays within bounds', () {
      final random = SecureRandomSource();
      for (var index = 0; index < 100; index++) {
        expect(random.nextInt(54), inInclusiveRange(0, 53));
      }
    });
  });

  group('Fisher-Yates', () {
    test('is deterministic and does not mutate input', () {
      final input = <String>['a', 'b', 'c'];
      final shuffled = fisherYatesShuffle(
        input,
        SequenceRandomSource(<int>[1, 0]),
      );

      expect(shuffled, <String>['c', 'a', 'b']);
      expect(input, <String>['a', 'b', 'c']);
      expect(() => shuffled.add('d'), throwsUnsupportedError);
    });

    test('uses descending inclusive bounds and supports edge swaps', () {
      final random = _RecordingRandomSource(<int>[3, 0, 1]);

      final shuffled = fisherYatesShuffle(<String>['a', 'b', 'c', 'd'], random);

      expect(random.bounds, <int>[4, 3, 2]);
      expect(shuffled, <String>['c', 'b', 'a', 'd']);
    });

    test('does not request randomness for empty and singleton inputs', () {
      final random = _RecordingRandomSource(const <int>[]);

      expect(fisherYatesShuffle<String>(const <String>[], random), isEmpty);
      expect(
        fisherYatesShuffle<String>(const <String>['only'], random),
        <String>['only'],
      );
      expect(random.bounds, isEmpty);
    });

    test('does not expose a partial result when randomness fails', () {
      final input = <String>['a', 'b', 'c', 'd'];
      final random = _ThrowingRandomSource(throwAfter: 1);

      expect(() => fisherYatesShuffle(input, random), throwsStateError);
      expect(input, <String>['a', 'b', 'c', 'd']);
    });
  });
}

final class _SequenceEntropy implements EntropySource {
  _SequenceEntropy(this._values);

  final List<int> _values;
  var consumed = 0;

  @override
  int nextUint32() => _values[consumed++];
}

final class _FailingEntropy implements EntropySource {
  _FailingEntropy(this._values);

  final List<int> _values;
  var consumed = 0;

  @override
  int nextUint32() {
    if (consumed == _values.length) {
      throw StateError('Entropy unavailable.');
    }
    return _values[consumed++];
  }
}

final class _RecordingRandomSource implements RandomSource {
  _RecordingRandomSource(this._values);

  final List<int> _values;
  final List<int> bounds = <int>[];
  var _cursor = 0;

  @override
  int nextInt(int maxExclusive) {
    bounds.add(maxExclusive);
    return _values[_cursor++];
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
