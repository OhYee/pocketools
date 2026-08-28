import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/session/session_id_source.dart';

void main() {
  group('Stage 2C independent secure session identifiers', () {
    test(
      'construction is lazy and a temporary factory failure is recoverable',
      () {
        var factoryCalls = 0;
        final source = SecureSessionIdSource(
          entropyFactory: () {
            factoryCalls++;
            if (factoryCalls == 1) {
              throw StateError('temporary entropy failure');
            }
            return Random(0x2C);
          },
        );

        expect(factoryCalls, 0);
        expect(source.next, throwsA(isA<SessionIdGenerationException>()));
        expect(factoryCalls, 1);
        expect(source.next(), _uuidV4);
        expect(factoryCalls, 2);
      },
    );

    test('2048 generated IDs are unique UUID v4 with RFC variant bits', () {
      final source = SecureSessionIdSource(entropy: Random(0x5EC0DE));
      final values = List<String>.generate(2048, (_) => source.next());

      expect(values.toSet(), hasLength(values.length));
      for (final value in values) {
        expect(value, _uuidV4);
        final hex = value.replaceAll('-', '');
        final bytes = List<int>.generate(
          16,
          (index) =>
              int.parse(hex.substring(index * 2, index * 2 + 2), radix: 16),
        );
        expect(bytes[6] & 0xF0, 0x40, reason: value);
        expect(bytes[8] & 0xC0, 0x80, reason: value);
      }
    });
  });
}

final Matcher _uuidV4 = matches(
  RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  ),
);
