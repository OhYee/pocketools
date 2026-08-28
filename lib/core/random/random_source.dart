import 'dart:math';

/// Supplies bounded random integers with uniform semantics.
abstract interface class RandomSource {
  int nextInt(int maxExclusive);
}

/// Supplies unsigned 32-bit entropy words without domain knowledge.
abstract interface class EntropySource {
  int nextUint32();
}

/// Production entropy backed by the platform cryptographically secure source.
final class SecureEntropySource implements EntropySource {
  SecureEntropySource();

  Random? _random;

  @override
  int nextUint32() {
    final random = _random ??= Random.secure();
    var value = 0;
    for (var index = 0; index < 4; index++) {
      value = (value << 8) | random.nextInt(256);
    }
    return value;
  }
}

/// Converts 32-bit entropy into unbiased bounded integers using rejection.
class UnbiasedRandomSource implements RandomSource {
  UnbiasedRandomSource(this._entropy);

  static const int _uint32Range = 0x100000000;
  final EntropySource _entropy;

  @override
  int nextInt(int maxExclusive) {
    if (maxExclusive <= 0 || maxExclusive > _uint32Range) {
      throw RangeError.range(maxExclusive, 1, _uint32Range, 'maxExclusive');
    }

    final limit = _uint32Range - (_uint32Range % maxExclusive);
    while (true) {
      final candidate = _entropy.nextUint32();
      if (candidate < 0 || candidate >= _uint32Range) {
        throw StateError('EntropySource returned a value outside uint32.');
      }
      if (candidate < limit) {
        return candidate % maxExclusive;
      }
    }
  }
}

/// Default production random source for Android and Web.
final class SecureRandomSource extends UnbiasedRandomSource {
  SecureRandomSource() : super(SecureEntropySource());
}

/// Deterministic bounded values for domain and widget tests.
final class SequenceRandomSource implements RandomSource {
  SequenceRandomSource(Iterable<int> values)
    : _values = List<int>.unmodifiable(values);

  final List<int> _values;
  var _cursor = 0;

  int get consumed => _cursor;

  @override
  int nextInt(int maxExclusive) {
    if (maxExclusive <= 0) {
      throw RangeError.value(maxExclusive, 'maxExclusive');
    }
    if (_cursor >= _values.length) {
      throw StateError('Deterministic random sequence is exhausted.');
    }
    final value = _values[_cursor++];
    if (value < 0 || value >= maxExclusive) {
      throw StateError(
        'Deterministic value $value is outside [0, $maxExclusive).',
      );
    }
    return value;
  }
}

/// Shared Fisher-Yates implementation. The input is never mutated.
List<T> fisherYatesShuffle<T>(Iterable<T> input, RandomSource random) {
  final output = List<T>.of(input);
  for (var index = output.length - 1; index > 0; index--) {
    final swapIndex = random.nextInt(index + 1);
    final value = output[index];
    output[index] = output[swapIndex];
    output[swapIndex] = value;
  }
  return List<T>.unmodifiable(output);
}
