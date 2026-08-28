import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_registry.dart';
import 'package:pocketools/features/tarot/content/tarot_content_catalog.dart';
import 'package:pocketools/features/tarot/domain/tarot_deck.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';
import 'package:pocketools/features/tarot/domain/tarot_reader.dart';
import 'package:pocketools/features/tarot/presentation/tarot_session_codec.dart';
import 'package:pocketools/features/tarot/presentation/tarot_tool_module.dart';

void main() {
  group('Stage 2B2 independent tarot domain audit', () {
    test('the complete 78-card identity and index snapshot stays stable', () {
      const expectedIds = <String>[
        'major-00-fool',
        'major-01-magician',
        'major-02-high-priestess',
        'major-03-empress',
        'major-04-emperor',
        'major-05-hierophant',
        'major-06-lovers',
        'major-07-chariot',
        'major-08-strength',
        'major-09-hermit',
        'major-10-wheel-of-fortune',
        'major-11-justice',
        'major-12-hanged-man',
        'major-13-death',
        'major-14-temperance',
        'major-15-devil',
        'major-16-tower',
        'major-17-star',
        'major-18-moon',
        'major-19-sun',
        'major-20-judgement',
        'major-21-world',
        'minor-wands-ace',
        'minor-wands-two',
        'minor-wands-three',
        'minor-wands-four',
        'minor-wands-five',
        'minor-wands-six',
        'minor-wands-seven',
        'minor-wands-eight',
        'minor-wands-nine',
        'minor-wands-ten',
        'minor-wands-page',
        'minor-wands-knight',
        'minor-wands-queen',
        'minor-wands-king',
        'minor-cups-ace',
        'minor-cups-two',
        'minor-cups-three',
        'minor-cups-four',
        'minor-cups-five',
        'minor-cups-six',
        'minor-cups-seven',
        'minor-cups-eight',
        'minor-cups-nine',
        'minor-cups-ten',
        'minor-cups-page',
        'minor-cups-knight',
        'minor-cups-queen',
        'minor-cups-king',
        'minor-swords-ace',
        'minor-swords-two',
        'minor-swords-three',
        'minor-swords-four',
        'minor-swords-five',
        'minor-swords-six',
        'minor-swords-seven',
        'minor-swords-eight',
        'minor-swords-nine',
        'minor-swords-ten',
        'minor-swords-page',
        'minor-swords-knight',
        'minor-swords-queen',
        'minor-swords-king',
        'minor-pentacles-ace',
        'minor-pentacles-two',
        'minor-pentacles-three',
        'minor-pentacles-four',
        'minor-pentacles-five',
        'minor-pentacles-six',
        'minor-pentacles-seven',
        'minor-pentacles-eight',
        'minor-pentacles-nine',
        'minor-pentacles-ten',
        'minor-pentacles-page',
        'minor-pentacles-knight',
        'minor-pentacles-queen',
        'minor-pentacles-king',
      ];
      final deck = TarotDeck.standard;

      expect(deck.map((card) => card.id).toList(), expectedIds);
      expect(deck.map((card) => card.name).toSet(), hasLength(78));
      expect(
        deck.map((card) => card.deckIndex),
        List<int>.generate(78, (i) => i),
      );
      expect(
        deck.take(22).map((card) => card.majorNumber),
        List<int>.generate(22, (i) => i),
      );
      for (final entry in deck.indexed) {
        expect(TarotDeck.byId[entry.$2.id], same(entry.$2));
      }
      expect(() => TarotDeck.byId.clear(), throwsUnsupportedError);
    });

    test('all cards and directions expose complete immutable content', () {
      const composer = TarotInterpretationComposer();

      for (final card in TarotDeck.standard) {
        final content = TarotContentCatalog.entryFor(card.id);
        expect(content.cardId, card.id);
        expect(content.uprightKeywords.length, greaterThanOrEqualTo(3));
        expect(content.reversedKeywords.length, greaterThanOrEqualTo(3));
        expect(content.traditionalSymbols, isNotEmpty);
        expect(content.reflectionQuestions.length, inInclusiveRange(1, 3));
        for (final values in <List<String>>[
          content.uprightKeywords,
          content.reversedKeywords,
          content.traditionalSymbols,
          content.reflectionQuestions,
        ]) {
          expect(values.every((value) => value.trim().isNotEmpty), isTrue);
        }
        expect(content.uprightMeaning.trim(), isNotEmpty);
        expect(content.reversedMeaning.trim(), isNotEmpty);

        for (final position in TarotPosition.values) {
          for (final orientation in TarotOrientation.values) {
            final interpretation = composer.resolve(
              TarotDrawnCard(
                card: card,
                position: position,
                orientation: orientation,
              ),
            );
            expect(interpretation.currentDirectionMeaning.trim(), isNotEmpty);
            expect(interpretation.positionMeaning.trim(), isNotEmpty);
            expect(
              interpretation.positionMeaning.length,
              lessThanOrEqualTo(120),
              reason: '${card.id}/${position.name}/${orientation.name}',
            );
          }
        }
      }

      final first = TarotContentCatalog.entryFor(TarotDeck.standard.first.id);
      expect(
        () => first.uprightKeywords.add('mutation'),
        throwsUnsupportedError,
      );
      expect(() => first.reflectionQuestions.clear(), throwsUnsupportedError);
      expect(() => TarotContentCatalog.entries.clear(), throwsUnsupportedError);
    });

    test(
      'all spreads preserve positions and no-replacement across vectors',
      () {
        for (final spread in TarotSpreadPreset.values) {
          for (final useReversals in <bool>[false, true]) {
            for (var seed = 1; seed <= 32; seed++) {
              final random = _BoundRecordingRandomSource(seed);
              final config = TarotReadingConfig(
                spread: spread,
                useReversals: useReversals,
              );
              final result = TarotReader(
                random,
                contentVersion: TarotContentCatalog.contentVersion,
              ).draw(config);

              expect(result.cards, hasLength(config.drawCount));
              expect(
                result.cards.map((card) => card.position).toList(),
                config.positions,
              );
              expect(
                result.cards.map((card) => card.card.id).toSet(),
                hasLength(config.drawCount),
              );
              expect(random.bounds, <int>[
                ...List<int>.generate(77, (index) => 78 - index),
                if (useReversals) ...List<int>.filled(config.drawCount, 2),
              ]);
              if (!useReversals) {
                expect(
                  result.cards.every(
                    (card) => card.orientation == TarotOrientation.upright,
                  ),
                  isTrue,
                );
              }
            }
          }
        }
      },
    );

    test('daily and question presets remain distinct one-card contracts', () {
      for (final entry in <(TarotSpreadPreset, TarotPosition)>[
        (TarotSpreadPreset.dailyCard, TarotPosition.dailyGuidance),
        (TarotSpreadPreset.singleQuestion, TarotPosition.coreMessage),
      ]) {
        final random = SequenceRandomSource(<int>[
          ...List<int>.filled(77, 0),
          1,
        ]);
        final result = TarotReader(
          random,
          contentVersion: TarotContentCatalog.contentVersion,
        ).draw(TarotReadingConfig(spread: entry.$1));

        expect(result.cards, hasLength(1));
        expect(result.cards.single.card.id, 'major-01-magician');
        expect(result.cards.single.position, entry.$2);
        expect(result.cards.single.orientation, TarotOrientation.reversed);
        expect(random.consumed, 78);
      }
    });

    test('random failure cannot return a partial or fabricated reading', () {
      for (final failAfter in <int>[0, 1, 76, 77, 79]) {
        final random = _FailingRandomSource(failAfter: failAfter);
        expect(
          () =>
              TarotReader(
                random,
                contentVersion: TarotContentCatalog.contentVersion,
              ).draw(
                const TarotReadingConfig(
                  spread: TarotSpreadPreset.pastPresentFuture,
                ),
              ),
          throwsStateError,
          reason: 'failAfter=$failAfter',
        );
        expect(random.calls, failAfter + 1);
      }
    });
  });

  group('Stage 2B2 independent tarot codec and privacy audit', () {
    const codec = TarotSessionCodec();
    const tripleConfig = TarotReadingConfig(
      spread: TarotSpreadPreset.pastPresentFuture,
    );

    test(
      'codec rejects outcome identity, order and type pollution attacks',
      () {
        final valid = _validTripleOutcome();
        final attacks = <Map<String, Object?>>[
          <String, Object?>{...valid, 'cards': 'not-a-list'},
          <String, Object?>{...valid, 'cards': <Object?>[]},
          <String, Object?>{
            ...valid,
            'cards': _replaceCardField(valid, 0, 'cardId', 'unknown-card'),
          },
          <String, Object?>{
            ...valid,
            'cards': _replaceCardField(valid, 1, 'cardId', 'major-01-magician'),
          },
          <String, Object?>{
            ...valid,
            'cards': _replaceCardField(valid, 0, 'position', 'future'),
          },
          <String, Object?>{
            ...valid,
            'cards': _replaceCardField(valid, 0, 'position', 'unknown'),
          },
          <String, Object?>{
            ...valid,
            'cards': _replaceCardField(valid, 0, 'orientation', 'sideways'),
          },
          <String, Object?>{
            ...valid,
            'cards': _replaceCardField(valid, 0, 'sequence', 1.0),
          },
          <String, Object?>{
            ...valid,
            'cards': _replaceCardField(valid, 0, 'cardId', 7),
          },
          <String, Object?>{
            ...valid,
            'cards': _replaceCardField(valid, 0, 'orientation', true),
          },
          <String, Object?>{
            ...valid,
            'cards': <Object?>[
              <Object?, Object?>{0: 'illegal-key'},
              ...(_cards(valid).skip(1)),
            ],
          },
          <String, Object?>{...valid, 'contentVersion': null},
          <String, Object?>{...valid, 'contentVersion': 1},
          <String, Object?>{...valid, 'contentVersion': ''},
          <String, Object?>{...valid, 'contentVersion': 'invalid value'},
          <String, Object?>{...valid, 'contentVersion': 'v' * 65},
          <String, Object?>{...valid, 'unexpected': true},
        ];

        for (final attack in attacks) {
          expect(
            () => codec.decodeOutcome(attack, tripleConfig),
            throwsFormatException,
            reason: attack.toString(),
          );
        }

        expect(
          () => codec.decodeOutcome(<String, Object?>{
            ..._validSingleOutcome(),
            'cards': _replaceCardField(
              _validSingleOutcome(),
              0,
              'orientation',
              'reversed',
            ),
          }, const TarotReadingConfig(useReversals: false)),
          throwsFormatException,
        );
      },
    );

    test('codec rejects input shape and scalar type pollution attacks', () {
      final valid = <String, Object?>{
        'spread': 'dailyCard',
        'useReversals': true,
        'revealMode': 'sequential',
        'intention': null,
        'drawCount': 1,
        'positions': <Object?>['dailyGuidance'],
      };
      final attacks = <Map<String, Object?>>[
        <String, Object?>{...valid, 'spread': 0},
        <String, Object?>{...valid, 'useReversals': 'true'},
        <String, Object?>{...valid, 'revealMode': false},
        <String, Object?>{...valid, 'intention': <Object?>[]},
        <String, Object?>{...valid, 'drawCount': true},
        <String, Object?>{...valid, 'drawCount': 1.0},
        <String, Object?>{...valid, 'positions': 'dailyGuidance'},
        <String, Object?>{
          ...valid,
          'positions': <Object?>[1],
        },
        <String, Object?>{...valid}..remove('positions'),
        <String, Object?>{...valid, 'extra': null},
      ];

      for (final attack in attacks) {
        expect(
          () => codec.decodeInput(attack),
          throwsFormatException,
          reason: attack.toString(),
        );
      }
    });

    test(
      'legacy nullable intention restores without changing the session',
      () async {
        final repository = InMemorySessionRepository();
        final module = TarotToolModule(sessionRepository: repository);
        final adapter = module.toolSessionAdapter;
        final session = SessionRecord(
          id: 'legacy-tarot-session',
          toolId: 'tarot',
          schemaVersion: 1,
          ruleVersion: TarotReader.ruleVersion,
          algorithmVersion: TarotReader.algorithmVersion,
          status: SessionStatus.completed,
          input: const <String, Object?>{
            'spread': 'dailyCard',
            'useReversals': true,
            'revealMode': 'sequential',
            'drawCount': 1,
            'positions': <Object?>['dailyGuidance'],
          },
          outcome: _validSingleOutcome(),
          parentSessionId: 'legacy-parent',
        );

        await repository.save(session);
        final restored = await repository.findById(session.id);
        final firstDecode = adapter.decode(restored!);
        final secondDecode = adapter.decode(restored);

        expect(restored, same(session));
        expect(restored.id, 'legacy-tarot-session');
        expect(restored.parentSessionId, 'legacy-parent');
        expect((firstDecode.input as TarotReadingConfig).intention, isNull);
        expect(
          (firstDecode.outcome as TarotReadingResult).cards.single.card.id,
          'major-01-magician',
        );
        expect(
          (secondDecode.outcome as TarotReadingResult).cards.single.card.id,
          'major-01-magician',
        );
      },
    );

    test(
      'registry history and share keep results but redact private fields',
      () {
        const privateText = 'QA_PRIVATE_TAROT_QUESTION_AND_NOTE_8B2';
        const sessionId = 'QA_PRIVATE_TAROT_SESSION_8B2';
        const parentId = 'QA_PRIVATE_TAROT_PARENT_8B2';
        final module = TarotToolModule();
        final registry = ToolRegistry(<TarotToolModule>[module]);
        const config = TarotReadingConfig(
          spread: TarotSpreadPreset.pastPresentFuture,
          intention: privateText,
        );
        final result = TarotReader(
          SequenceRandomSource(<int>[...List<int>.filled(77, 0), 0, 1, 0]),
          contentVersion: TarotContentCatalog.contentVersion,
        ).draw(config);
        final session = registry.createCompletedSession(
          toolId: 'tarot',
          id: sessionId,
          schemaVersion: 1,
          ruleVersion: TarotReader.ruleVersion,
          algorithmVersion: TarotReader.algorithmVersion,
          input: config,
          outcome: result,
          parentSessionId: parentId,
        );

        final history = registry.historySummary(session);
        final share = registry.sharePayload(session);
        for (final visible in <String>[
          '过去:魔术师(正位)',
          TarotReader.ruleVersion,
          TarotReader.algorithmVersion,
        ]) {
          expect(history.summary, contains(visible));
        }
        expect(share.plainText, contains('过去：魔术师（正位）'));
        expect(share.plainText, isNot(contains('Pocketools original')));
        expect(share.plainText, isNot(contains('不是专业建议')));
        for (final privateValue in <String>[privateText, sessionId, parentId]) {
          expect(history.summary, isNot(contains(privateValue)));
          expect(share.summary, isNot(contains(privateValue)));
          expect(share.plainText, isNot(contains(privateValue)));
        }
      },
    );
  });

  test(
    'original content avoids external quotation and deterministic claims',
    () {
      final contentText = <String>[
        for (final content in TarotContentCatalog.entries.values) ...<String>[
          ...content.uprightKeywords,
          ...content.reversedKeywords,
          ...content.traditionalSymbols,
          content.uprightMeaning,
          content.reversedMeaning,
          ...content.reflectionQuestions,
        ],
      ].join('\n');

      for (final forbidden in <String>[
        'http://',
        'https://',
        'www.',
        '摘录自',
        '原文引自',
        '逐字翻译',
        'Rider-Waite',
        '莱德伟特',
        '你注定',
        '一定会发生',
        '必定发生',
        '百分之百',
        '准确率',
        '保证结果',
        '诊断为',
        '治疗方案是',
        '法律结论是',
        '必须买入',
        '必须卖出',
      ]) {
        expect(contentText, isNot(contains(forbidden)), reason: forbidden);
      }
      expect(contentText, isNot(contains('内容边界')));
      expect(contentText, isNot(contains('专业建议')));
    },
  );
}

Map<String, Object?> _validTripleOutcome() => <String, Object?>{
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

Map<String, Object?> _validSingleOutcome() => <String, Object?>{
  'cards': <Object?>[
    <String, Object?>{
      'sequence': 0,
      'cardId': 'major-01-magician',
      'position': 'dailyGuidance',
      'orientation': 'upright',
    },
  ],
  'contentVersion': '1.0.0',
};

List<Object?> _cards(Map<String, Object?> outcome) =>
    List<Object?>.of(outcome['cards']! as List<Object?>);

List<Object?> _replaceCardField(
  Map<String, Object?> outcome,
  int index,
  String key,
  Object? value,
) {
  final cards = _cards(outcome);
  cards[index] = <String, Object?>{
    ...(cards[index]! as Map<String, Object?>),
    key: value,
  };
  return cards;
}

final class _BoundRecordingRandomSource implements RandomSource {
  _BoundRecordingRandomSource(this._state);

  int _state;
  final List<int> bounds = <int>[];

  @override
  int nextInt(int maxExclusive) {
    bounds.add(maxExclusive);
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state % maxExclusive;
  }
}

final class _FailingRandomSource implements RandomSource {
  _FailingRandomSource({required this.failAfter});

  final int failAfter;
  var calls = 0;

  @override
  int nextInt(int maxExclusive) {
    calls++;
    if (calls > failAfter) throw StateError('Injected entropy failure.');
    return 0;
  }
}
