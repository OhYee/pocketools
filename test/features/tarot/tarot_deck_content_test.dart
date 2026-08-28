import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/assets/runtime/runtime_asset_manifest.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/features/tarot/content/tarot_content_catalog.dart';
import 'package:pocketools/features/tarot/domain/tarot_deck.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';
import 'package:pocketools/features/tarot/domain/tarot_reader.dart';

void main() {
  test('stable deck contains 22 majors and four complete 14-card suits', () {
    final deck = TarotDeck.standard;

    expect(TarotDeck.validate(deck), isEmpty);
    expect(deck, hasLength(78));
    expect(deck.map((card) => card.id).toSet(), hasLength(78));
    expect(
      deck.where((card) => card.arcana == TarotArcana.major),
      hasLength(22),
    );
    for (final suit in TarotSuit.values) {
      final cards = deck.where((card) => card.suit == suit).toList();
      expect(cards, hasLength(14), reason: suit.name);
      expect(cards.map((card) => card.rank).toSet(), TarotRank.values.toSet());
    }
    expect(() => deck.clear(), throwsUnsupportedError);
  });

  test('every card has complete original interpretation fields', () {
    expect(TarotContentCatalog.validate(), isEmpty);
    expect(TarotContentCatalog.entries, hasLength(78));

    for (final card in TarotDeck.standard) {
      final entry = TarotContentCatalog.entryFor(card.id);
      expect(entry.cardId, card.id);
      expect(
        entry.uprightKeywords.where((value) => value.trim().isEmpty),
        isEmpty,
      );
      expect(
        entry.reversedKeywords.where((value) => value.trim().isEmpty),
        isEmpty,
      );
      expect(
        entry.traditionalSymbols.where((value) => value.trim().isEmpty),
        isEmpty,
      );
      expect(entry.uprightMeaning.trim(), isNotEmpty, reason: card.id);
      expect(entry.reversedMeaning.trim(), isNotEmpty, reason: card.id);
      expect(
        entry.reflectionQuestions.where((value) => value.trim().isEmpty),
        isEmpty,
      );
    }
  });

  test(
    'major cards use independent text while minor cards remain complete',
    () {
      final majorMeanings = TarotDeck.standard
          .where((card) => card.arcana == TarotArcana.major)
          .map((card) => TarotContentCatalog.entryFor(card.id).uprightMeaning)
          .toSet();
      final minorEntries = TarotDeck.standard
          .where((card) => card.arcana == TarotArcana.minor)
          .map((card) => TarotContentCatalog.entryFor(card.id));

      expect(majorMeanings, hasLength(22));
      expect(
        minorEntries.every(
          (entry) =>
              entry.uprightMeaning.isNotEmpty &&
              entry.reversedMeaning.isNotEmpty &&
              entry.traditionalSymbols.length >= 2,
        ),
        isTrue,
      );
    },
  );

  test('composer yields complete upright and reversed interpretations', () {
    const composer = TarotInterpretationComposer();
    for (final card in TarotDeck.standard) {
      for (final orientation in TarotOrientation.values) {
        final interpretation = composer.resolve(
          TarotDrawnCard(
            card: card,
            position: TarotPosition.coreMessage,
            orientation: orientation,
          ),
        );
        expect(interpretation.keywords, isNotEmpty, reason: card.id);
        expect(interpretation.traditionalSymbols, isNotEmpty, reason: card.id);
        expect(interpretation.uprightMeaning.trim(), isNotEmpty);
        expect(interpretation.reversedMeaning.trim(), isNotEmpty);
        expect(interpretation.currentDirectionMeaning.trim(), isNotEmpty);
        expect(interpretation.positionMeaning.trim(), isNotEmpty);
        expect(interpretation.reflectionQuestions, isNotEmpty);
      }
    }
  });

  test('major-only results keep content and manifest mappings valid', () {
    final result = TarotReader(
      SequenceRandomSource(<int>[...List<int>.filled(21, 0), 0]),
      contentVersion: TarotContentCatalog.contentVersion,
    ).draw(const TarotReadingConfig(includeMinorArcana: false));
    const composer = TarotInterpretationComposer();

    for (final drawn in result.cards) {
      expect(drawn.card.arcana, TarotArcana.major);
      expect(composer.resolve(drawn).currentDirectionMeaning, isNotEmpty);
      final asset = RuntimeAssetManifest.tarotFace(
        cardId: drawn.card.id,
        orientation: RuntimeAssetOrientation.upright,
        semanticLabel: drawn.card.name,
      );
      expect(asset.path, contains('rider_waite/'));
      expect(asset.path, endsWith('.jpg'));
    }
  });
}
