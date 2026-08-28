import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tarot and playing cards share the physical deck interaction', () {
    final tarot = File('lib/features/tarot/presentation/tarot_tool_page.dart')
        .readAsStringSync();
    final cards = File('lib/features/cards/presentation/card_tool_page.dart')
        .readAsStringSync();
    final shared = File('lib/design_system/components/app_physical_deck.dart')
        .readAsStringSync();

    expect(tarot, contains('AppPhysicalDeck'));
    expect(cards, contains('AppPhysicalDeck'));
    expect(shared, contains('AppPhysicalAction'));
    expect(shared, contains('AppDeckResultFlow'));
  });

  test('DND, coin, and Liuyao share the physical entity contract', () {
    for (final path in <String>[
      'lib/features/dice/presentation/dice_tool_page.dart',
      'lib/features/coin/presentation/coin_tool_page.dart',
      'lib/features/liuyao/presentation/liuyao_tool_page.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('AppEntityStateView'), reason: path);
      expect(source, contains('AppPhysicalAction'), reason: path);
    }
  });
}
