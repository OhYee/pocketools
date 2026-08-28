import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';
import 'package:pocketools/features/cards/domain/card_drawer.dart';
import 'package:pocketools/features/cards/domain/card_models.dart';
import 'package:pocketools/features/cards/presentation/card_tool_module.dart';

void main() {
  test('registered card module provides ordered structured sharing', () {
    final module = CardToolModule();
    final registry = ToolRegistry(<ToolModule>[module]);
    const config = CardDrawConfig(drawCount: 3);
    final result = CardDrawer(SequenceRandomSource(List<int>.filled(51, 0)))
        .draw(config);
    final session = registry.createCompletedSession(
      toolId: 'cards',
      id: 'cards-share',
      schemaVersion: 1,
      ruleVersion: CardDrawer.ruleVersion,
      algorithmVersion: CardDrawer.algorithmVersion,
      input: config,
      outcome: result,
    );

    final share = registry.sharePayload(session);

    expect(module.descriptor.availability, ToolAvailability.available);
    expect(share.title, '抽扑克牌');
    expect(share.plainText, contains('标准牌组 · 不含大小王 · 52 张 · 抽取 3 张 · 无放回'));
    expect(share.plainText, contains('#1 梅花 3'));
    expect(share.plainText, contains('#2 梅花 4'));
    expect(share.plainText, contains('#3 梅花 5'));
    expect(share.plainText, contains('剩余 49 张'));
  });
}
