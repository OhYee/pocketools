import 'dart:math';

/// Session identity entropy is intentionally independent from tool randomness.
abstract interface class SessionIdSource {
  String next();
}

typedef SecureSessionEntropyFactory = Random Function();

final class SessionIdGenerationException implements Exception {
  const SessionIdGenerationException(this.message);

  final String message;

  @override
  String toString() => 'SessionIdGenerationException: $message';
}

/// UUID-v4-compatible, collision-resistant application session IDs.
final class SecureSessionIdSource implements SessionIdSource {
  factory SecureSessionIdSource({
    Random? entropy,
    SecureSessionEntropyFactory? entropyFactory,
  }) => SecureSessionIdSource._(entropy, entropyFactory ?? Random.secure);

  SecureSessionIdSource._(this._entropy, this._entropyFactory);

  Random? _entropy;
  final SecureSessionEntropyFactory _entropyFactory;

  @override
  String next() {
    late final List<int> bytes;
    try {
      final entropy = _entropy ??= _entropyFactory();
      bytes = List<int>.generate(
        16,
        (_) => entropy.nextInt(256),
        growable: false,
      );
    } on Object {
      throw const SessionIdGenerationException(
        'Secure entropy is unavailable; no session was created.',
      );
    }
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final hex = bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
