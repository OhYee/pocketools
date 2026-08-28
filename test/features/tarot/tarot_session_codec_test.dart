import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';
import 'package:pocketools/features/tarot/domain/tarot_reader.dart';
import 'package:pocketools/features/tarot/presentation/tarot_session_codec.dart';

void main() {
  const codec = TarotSessionCodec();

  test(
    'round trips ordered cards, positions, directions and content version',
    () {
      const config = TarotReadingConfig(
        spread: TarotSpreadPreset.pastPresentFuture,
        includeMinorArcana: false,
        revealMode: TarotRevealMode.allAtOnce,
        intention: '  private reflection  ',
      );
      final result = TarotReader(
        SequenceRandomSource(<int>[...List<int>.filled(21, 0), 1, 0, 1]),
        contentVersion: '1.0.0',
      ).draw(config);

      expect(codec.encodeInput(config)['includeMinorArcana'], isFalse);
      final decodedConfig = codec.decodeInput(codec.encodeInput(config));
      final decoded = codec.decodeOutcome(
        codec.encodeOutcome(result),
        decodedConfig,
      );

      expect(decodedConfig.spread, config.spread);
      expect(decodedConfig.includeMinorArcana, isFalse);
      expect(decodedConfig.revealMode, config.revealMode);
      expect(decodedConfig.intention, 'private reflection');
      expect(
        decoded.cards.map((card) => card.card.id),
        result.cards.map((card) => card.card.id),
      );
      expect(
        decoded.cards.map((card) => card.orientation),
        result.cards.map((card) => card.orientation),
      );
      expect(decoded.contentVersion, '1.0.0');
    },
  );

  test('round trips a partial spread produced by one physical deck tap', () {
    const config = TarotReadingConfig(
      spread: TarotSpreadPreset.pastPresentFuture,
    );
    final drawn = TarotReader(
      SequenceRandomSource(<int>[1, 0]),
      contentVersion: '1.0.0',
    ).drawOne(config, position: TarotPosition.present);
    final result = TarotReadingResult(
      config: config,
      cards: <TarotDrawnCard>[drawn],
      contentVersion: '1.0.0',
    );

    final decoded = codec.decodeOutcome(
      codec.encodeOutcome(result),
      codec.decodeInput(codec.encodeInput(config)),
    );

    expect(decoded.cards, hasLength(1));
    expect(decoded.cards.single.position, TarotPosition.present);
  });

  test('rejects malformed and internally inconsistent input', () {
    final valid = <String, Object?>{
      'spread': 'dailyCard',
      'useReversals': true,
      'revealMode': 'sequential',
      'drawCount': 1,
      'positions': <Object?>['dailyGuidance'],
    };
    final malformed = <Map<String, Object?>>[
      <String, Object?>{...valid, 'spread': 'unknown'},
      <String, Object?>{...valid, 'useReversals': 1},
      <String, Object?>{...valid, 'includeMinorArcana': 'false'},
      <String, Object?>{...valid, 'revealMode': 'unknown'},
      <String, Object?>{...valid, 'intention': 3},
      <String, Object?>{...valid, 'intention': 'invalid\u0001text'},
      <String, Object?>{
        ...valid,
        'intention': 'x' * (TarotReadingConfig.maximumIntentionLength + 1),
      },
      <String, Object?>{...valid, 'drawCount': 3},
      <String, Object?>{
        ...valid,
        'positions': <Object?>['future'],
      },
      <String, Object?>{...valid, 'extra': true},
      <String, Object?>{...valid}..remove('spread'),
    ];

    for (final payload in malformed) {
      expect(() => codec.decodeInput(payload), throwsFormatException);
    }
  });

  test(
    'rejects duplicate, unknown, reordered and invalid-direction outcomes',
    () {
      const config = TarotReadingConfig(
        spread: TarotSpreadPreset.pastPresentFuture,
      );
      final valid = <String, Object?>{
        'cards': <Object?>[
          <String, Object?>{
            'sequence': 0,
            'cardId': 'major-01-magician',
            'position': 'past',
            'orientation': 'upright',
          },
          <String, Object?>{
            'sequence': 1,
            'cardId': 'major-02-high-priestess',
            'position': 'present',
            'orientation': 'reversed',
          },
          <String, Object?>{
            'sequence': 2,
            'cardId': 'major-03-empress',
            'position': 'future',
            'orientation': 'upright',
          },
        ],
        'contentVersion': '1.0.0',
      };
      final cards = valid['cards']! as List<Object?>;
      final malformed = <Map<String, Object?>>[
        <String, Object?>{
          ...valid,
          'cards': <Object?>[cards[0], cards[0], cards[2]],
        },
        <String, Object?>{
          ...valid,
          'cards': <Object?>[
            <String, Object?>{
              ...(cards[0]! as Map<String, Object?>),
              'cardId': 'unknown',
            },
            cards[1],
            cards[2],
          ],
        },
        <String, Object?>{
          ...valid,
          'cards': <Object?>[
            <String, Object?>{
              ...(cards[0]! as Map<String, Object?>),
              'sequence': 1,
            },
            cards[1],
            cards[2],
          ],
        },
        <String, Object?>{
          ...valid,
          'cards': <Object?>[
            <String, Object?>{
              ...(cards[0]! as Map<String, Object?>),
              'position': 'future',
            },
            cards[1],
            cards[2],
          ],
        },
        <String, Object?>{...valid, 'contentVersion': '../invalid value'},
        <String, Object?>{...valid, 'extra': true},
      ];

      for (final payload in malformed) {
        expect(
          () => codec.decodeOutcome(payload, config),
          throwsFormatException,
        );
      }

      const uprightOnly = TarotReadingConfig(useReversals: false);
      expect(
        () => codec.decodeOutcome(<String, Object?>{
          'cards': <Object?>[
            <String, Object?>{
              'sequence': 0,
              'cardId': 'major-01-magician',
              'position': 'dailyGuidance',
              'orientation': 'reversed',
            },
          ],
          'contentVersion': '1.0.0',
        }, uprightOnly),
        throwsFormatException,
      );

      expect(
        () => codec.decodeOutcome(<String, Object?>{
          'cards': <Object?>[
            <String, Object?>{
              'sequence': 0,
              'cardId': 'minor-wands-ace',
              'position': 'dailyGuidance',
              'orientation': 'upright',
            },
          ],
          'contentVersion': '1.0.0',
        }, const TarotReadingConfig(includeMinorArcana: false)),
        throwsFormatException,
      );
    },
  );

  test('summary preserves order and versions without session identifiers', () {
    final session = SessionRecord(
      id: 'private-tarot-session',
      toolId: 'tarot',
      schemaVersion: 1,
      ruleVersion: TarotReader.ruleVersion,
      algorithmVersion: TarotReader.algorithmVersion,
      status: SessionStatus.completed,
      input: const <String, Object?>{
        'spread': 'dailyCard',
        'useReversals': true,
        'revealMode': 'sequential',
        'intention': 'private-tarot-question',
        'drawCount': 1,
        'positions': <Object?>['dailyGuidance'],
      },
      outcome: const <String, Object?>{
        'cards': <Object?>[
          <String, Object?>{
            'sequence': 0,
            'cardId': 'major-01-magician',
            'position': 'dailyGuidance',
            'orientation': 'reversed',
          },
        ],
        'contentVersion': '1.0.0',
      },
    );

    final summary = codec.summarize(session);

    expect(summary, contains('今日提示:魔术师(逆位)'));
    expect(summary, contains('内容 1.0.0'));
    expect(summary, contains(TarotReader.ruleVersion));
    expect(summary, contains(TarotReader.algorithmVersion));
    expect(summary, isNot(contains('private-tarot-session')));
    expect(summary, isNot(contains('private-tarot-question')));
  });
}
