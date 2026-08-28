import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/session/session_id_source.dart';

void main() {
  test('secure session id entropy is acquired lazily', () {
    var factoryCalls = 0;
    final source = SecureSessionIdSource(
      entropyFactory: () {
        factoryCalls++;
        return Random(7);
      },
    );

    expect(factoryCalls, 0);
    expect(
      source.next(),
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(factoryCalls, 1);
    source.next();
    expect(factoryCalls, 1);
  });

  test('secure entropy failure is deferred until next', () {
    final source = SecureSessionIdSource(
      entropyFactory: () => throw StateError('entropy unavailable'),
    );

    expect(
      source.next,
      throwsA(
        isA<SessionIdGenerationException>().having(
          (error) => error.message,
          'message',
          contains('no session was created'),
        ),
      ),
    );
  });
}
