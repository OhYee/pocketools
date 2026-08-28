import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/features/tarot/content/tarot_content_catalog.dart';
import 'package:pocketools/features/tarot/domain/tarot_deck.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';
import 'package:pocketools/features/tarot/domain/tarot_reader.dart';
import 'package:pocketools/features/tarot/presentation/tarot_session_codec.dart';

import 'tarot_minor_arcana_qa_support.dart';

void main() {
  test(
    'default tarot draw uses 78-card entropy while the off mode uses 22 majors',
    () {
      final defaultRandom = TarotMinorArcanaQaRandomSource();
      final defaultConfig = TarotReadingConfig(
        spread: TarotSpreadPreset.pastPresentFuture,
        useReversals: false,
      );
      final defaultResult = TarotReader(
        defaultRandom,
        contentVersion: TarotContentCatalog.contentVersion,
      ).draw(defaultConfig);

      expect(TarotMinorArcanaQa.useMinorArcana(defaultResult.config), isTrue);
      expect(defaultResult.cards, hasLength(3));
      expect(
        defaultRandom.bounds,
        List<int>.generate(77, (index) => 78 - index),
      );

      final majorOnlyRandom = TarotMinorArcanaQaRandomSource();
      final majorOnlyConfig = TarotMinorArcanaQa.config(
        useMinorArcana: false,
        spread: TarotSpreadPreset.pastPresentFuture,
        useReversals: false,
      );
      final majorOnlyResult = TarotReader(
        majorOnlyRandom,
        contentVersion: TarotContentCatalog.contentVersion,
      ).draw(majorOnlyConfig);

      expect(
        TarotMinorArcanaQa.useMinorArcana(majorOnlyResult.config),
        isFalse,
      );
      expect(
        majorOnlyRandom.bounds,
        List<int>.generate(21, (index) => 22 - index),
      );
      expect(
        majorOnlyResult.cards.every(
          (drawn) => drawn.card.arcana == TarotArcana.major,
        ),
        isTrue,
      );
    },
  );

  test(
    'fixed vectors keep shuffle and orientation calls exact in both deck modes',
    () {
      for (final useMinorArcana in <bool>[true, false]) {
        for (final useReversals in <bool>[true, false]) {
          final random = TarotMinorArcanaQaRandomSource();
          final config = TarotMinorArcanaQa.config(
            useMinorArcana: useMinorArcana,
            spread: TarotSpreadPreset.pastPresentFuture,
            useReversals: useReversals,
          );
          final result = TarotReader(
            random,
            contentVersion: TarotContentCatalog.contentVersion,
          ).draw(config);
          final deckSize = useMinorArcana ? 78 : 22;

          expect(random.bounds, <int>[
            ...List<int>.generate(deckSize - 1, (index) => deckSize - index),
            if (useReversals) ...List<int>.filled(config.drawCount, 2),
          ], reason: 'minor=$useMinorArcana/reversals=$useReversals');
          expect(
            result.cards.map((drawn) => drawn.card.id).toSet(),
            hasLength(3),
          );
          if (!useMinorArcana) {
            expect(
              result.cards.every(
                (drawn) => drawn.card.arcana == TarotArcana.major,
              ),
              isTrue,
            );
          }
          if (!useReversals) {
            expect(
              result.cards.every(
                (drawn) => drawn.orientation == TarotOrientation.upright,
              ),
              isTrue,
            );
          }
        }
      }
    },
  );

  test(
    'session input codec round-trips the minor-arcana selection exactly',
    () {
      const codec = TarotSessionCodec();
      final original = TarotMinorArcanaQa.config(
        useMinorArcana: false,
        spread: TarotSpreadPreset.pastPresentFuture,
        useReversals: false,
        revealMode: TarotRevealMode.allAtOnce,
        intention: '  仅使用大阿卡纳  ',
      );

      final encoded = codec.encodeInput(original);
      final key = TarotMinorArcanaQa.inputKey(encoded);
      expect(encoded[key], isFalse);
      expect(encoded['drawCount'], 3);
      expect(encoded['positions'], <String>['past', 'present', 'future']);

      final decoded = codec.decodeInput(encoded);
      expect(TarotMinorArcanaQa.useMinorArcana(decoded), isFalse);
      expect(decoded.intention, '仅使用大阿卡纳');
      expect(codec.encodeInput(decoded), encoded);
    },
  );

  test(
    'minor card outcome keeps stable ID mapping and interpretation content',
    () {
      const codec = TarotSessionCodec();
      final config = TarotMinorArcanaQa.config(useMinorArcana: true);
      final card = TarotDeck.byId['minor-wands-ace'];
      expect(card, isNotNull);

      final result = TarotReadingResult(
        config: config,
        cards: <TarotDrawnCard>[
          TarotDrawnCard(
            card: card!,
            position: TarotPosition.dailyGuidance,
            orientation: TarotOrientation.upright,
          ),
        ],
        contentVersion: TarotContentCatalog.contentVersion,
      );
      final restored = codec.decodeOutcome(codec.encodeOutcome(result), config);
      final restoredCard = restored.cards.single.card;
      final interpretation = const TarotInterpretationComposer().resolve(
        restored.cards.single,
      );

      expect(restoredCard.id, 'minor-wands-ace');
      expect(restoredCard.name, '权杖一');
      expect(restoredCard.arcana, TarotArcana.minor);
      expect(
        TarotContentCatalog.entryFor(restoredCard.id).cardId,
        restoredCard.id,
      );
      expect(interpretation.drawnCard.card, same(restoredCard));
      expect(interpretation.keywords, isNotEmpty);
      expect(interpretation.traditionalSymbols, isNotEmpty);
      expect(interpretation.currentDirectionMeaning, isNotEmpty);
      expect(interpretation.positionMeaning, isNotEmpty);
    },
  );
}
