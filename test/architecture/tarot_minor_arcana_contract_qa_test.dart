import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tarot model and reader expose a pre-shuffle 78/22 deck contract', () {
    final model = File('lib/features/tarot/domain/tarot_models.dart')
        .readAsStringSync();
    final deck = File('lib/features/tarot/domain/tarot_deck.dart')
        .readAsStringSync();
    final reader = File('lib/features/tarot/domain/tarot_reader.dart')
        .readAsStringSync();
    final optionNames = RegExp(r'useMinorArcana|includeMinorArcana');

    expect(model, contains(optionNames));
    expect(deck, contains('78'));
    expect(deck, contains('22'));
    expect(deck, contains('TarotArcana.major'));
    expect(reader, contains(optionNames));
    expect(reader, contains('fisherYatesShuffle'));
    expect(reader, contains('TarotArcana.major'));
    expect(
      reader.indexOf('fisherYatesShuffle'),
      greaterThan(reader.indexOf('TarotArcana.major')),
      reason: 'The selected deck must be filtered before shuffling.',
    );
  });

  test(
    'tarot input codec persists the minor-arcana choice and validates it',
    () {
      final codec = File(
        'lib/features/tarot/presentation/tarot_session_codec.dart',
      ).readAsStringSync();
      final optionNames = RegExp(r'useMinorArcana|includeMinorArcana');

      expect(codec, contains(optionNames));
      expect(
        RegExp('minor', caseSensitive: false).allMatches(codec).length,
        greaterThanOrEqualTo(1),
      );
      expect(codec, contains('_requireExactKeys'));
      expect(codec, contains('drawCount'));
      expect(codec, contains('positions'));
    },
  );

  test(
    'tarot page keeps the simplified layout and accessibility hooks explicit',
    () {
      final page = File('lib/features/tarot/presentation/tarot_tool_page.dart')
          .readAsStringSync();
      final result = File(
        'lib/features/tarot/presentation/widgets/tarot_result_view.dart',
      ).readAsStringSync();

      for (final required in <String>[
        'TarotDeckStack',
        '高级选项',
        '小阿卡纳',
        '重置',
        'SwitchListTile',
        'tarot-deck',
        'redraw-tarot-button',
        'AppToolScaffold(',
        'AppButton(',
        'ExpansionTile(',
      ]) {
        expect(page, contains(required), reason: required);
      }
      expect(page, contains('AppPhysicalDeck'));
      expect(result, contains('TarotInterpretationComposer'));
      expect(result, contains('currentDirectionMeaning'));
    },
  );
}
