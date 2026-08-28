import 'dart:collection';

import '../domain/tarot_models.dart';

final class TarotCardContent {
  TarotCardContent({
    required this.cardId,
    required List<String> uprightKeywords,
    required List<String> reversedKeywords,
    required List<String> traditionalSymbols,
    required this.uprightMeaning,
    required this.reversedMeaning,
    required List<String> reflectionQuestions,
  }) : uprightKeywords = UnmodifiableListView<String>(
         List<String>.of(uprightKeywords),
       ),
       reversedKeywords = UnmodifiableListView<String>(
         List<String>.of(reversedKeywords),
       ),
       traditionalSymbols = UnmodifiableListView<String>(
         List<String>.of(traditionalSymbols),
       ),
       reflectionQuestions = UnmodifiableListView<String>(
         List<String>.of(reflectionQuestions),
       );

  final String cardId;
  final List<String> uprightKeywords;
  final List<String> reversedKeywords;
  final List<String> traditionalSymbols;
  final String uprightMeaning;
  final String reversedMeaning;
  final List<String> reflectionQuestions;
}

final class TarotCardInterpretation {
  TarotCardInterpretation({
    required this.drawnCard,
    required List<String> keywords,
    required List<String> traditionalSymbols,
    required this.uprightMeaning,
    required this.reversedMeaning,
    required this.currentDirectionMeaning,
    required this.positionMeaning,
    required List<String> reflectionQuestions,
  }) : keywords = UnmodifiableListView<String>(List<String>.of(keywords)),
       traditionalSymbols = UnmodifiableListView<String>(
         List<String>.of(traditionalSymbols),
       ),
       reflectionQuestions = UnmodifiableListView<String>(
         List<String>.of(reflectionQuestions),
       );

  final TarotDrawnCard drawnCard;
  final List<String> keywords;
  final List<String> traditionalSymbols;
  final String uprightMeaning;
  final String reversedMeaning;
  final String currentDirectionMeaning;
  final String positionMeaning;
  final List<String> reflectionQuestions;
}
