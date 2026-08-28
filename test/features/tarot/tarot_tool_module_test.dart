import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/registry/default_tool_registry.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';
import 'package:pocketools/features/tarot/content/tarot_content_catalog.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';
import 'package:pocketools/features/tarot/domain/tarot_reader.dart';
import 'package:pocketools/features/tarot/presentation/tarot_tool_module.dart';

void main() {
  test('default registry exposes a real available tarot module', () {
    final module = buildDefaultToolRegistry().byId('tarot');

    expect(module, isA<TarotToolModule>());
    expect(module!.descriptor.availability, ToolAvailability.available);
    expect(module.descriptor.route, '/tools/tarot');
  });

  test('history and share are ordered, versioned and sanitized', () {
    final module = TarotToolModule();
    final registry = ToolRegistry(<ToolModule>[module]);
    const config = TarotReadingConfig(
      spread: TarotSpreadPreset.pastPresentFuture,
      includeMinorArcana: false,
      intention: 'private open question',
    );
    final result = TarotReader(
      SequenceRandomSource(<int>[...List<int>.filled(21, 0), 1, 0, 1]),
      contentVersion: TarotContentCatalog.contentVersion,
    ).draw(config);
    final session = registry.createCompletedSession(
      toolId: 'tarot',
      id: 'sensitive-session-id',
      schemaVersion: 1,
      ruleVersion: TarotReader.ruleVersion,
      algorithmVersion: TarotReader.algorithmVersion,
      input: config,
      outcome: result,
      parentSessionId: 'sensitive-parent-id',
    );

    final history = registry.historySummary(session);
    final share = registry.sharePayload(session);

    expect(history.summary, contains('过去:魔术师(逆位)'));
    expect(history.summary, contains('现在:女祭司(正位)'));
    expect(history.summary, contains('未来:女皇(逆位)'));
    expect(history.summary, contains('仅大阿卡那（22 张）'));
    expect(history.summary, contains(TarotReader.algorithmVersion));
    expect(share.plainText, contains('过去：魔术师（逆位）'));
    expect(share.plainText, contains('仅大阿卡那（22 张）'));
    expect(share.plainText, contains('简短解读：'));
    expect(share.plainText, contains('组合提示'));
    expect(share.plainText, isNot(contains('不是专业建议')));
    expect(share.plainText, isNot(contains('Pocketools original')));
    expect(share.plainText, isNot(contains('Apache-2.0')));
    expect(share.plainText, isNot(contains('candidate')));
    for (final privateValue in <String>[
      'sensitive-session-id',
      'sensitive-parent-id',
      'private open question',
    ]) {
      expect(history.summary, isNot(contains(privateValue)));
      expect(share.plainText, isNot(contains(privateValue)));
    }
  });
}
