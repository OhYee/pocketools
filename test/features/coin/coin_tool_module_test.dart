import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/registry/default_tool_registry.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';
import 'package:pocketools/features/coin/domain/coin_models.dart';
import 'package:pocketools/features/coin/domain/coin_tosser.dart';
import 'package:pocketools/features/coin/presentation/coin_tool_module.dart';

void main() {
  test('default registry exposes a real available coin module', () {
    final module = buildDefaultToolRegistry().byId('coin');

    expect(module, isA<CoinToolModule>());
    expect(module!.descriptor.availability, ToolAvailability.available);
    expect(module.descriptor.route, '/tools/coin');
  });

  test('registered module provides sanitized ordered history and sharing', () {
    final module = CoinToolModule();
    final registry = ToolRegistry(<ToolModule>[module]);
    const config = CoinTossConfig(
      mode: CoinTossMode.batch,
      batchCount: 3,
      headsLabel: '甲',
      tailsLabel: '乙',
    );
    final result = CoinTosser(SequenceRandomSource(const <int>[0, 1, 0]))
        .toss(config);
    final session = registry.createCompletedSession(
      toolId: 'coin',
      id: 'sensitive-session-id',
      schemaVersion: 1,
      ruleVersion: CoinTosser.ruleVersion,
      algorithmVersion: CoinTosser.algorithmVersion,
      input: config,
      outcome: result,
      parentSessionId: 'sensitive-parent-id',
    );

    final history = registry.historySummary(session);
    final share = registry.sharePayload(session);

    expect(history.summary, contains('甲 2 / 乙 1'));
    expect(history.summary, contains('heads,tails,heads'));
    expect(history.summary, contains(CoinTosser.ruleVersion));
    expect(share.title, '抛硬币');
    expect(share.plainText, contains('标签：heads=甲；tails=乙'));
    expect(share.plainText, contains('#1 甲（heads）'));
    expect(share.plainText, contains('#2 乙（tails）'));
    expect(share.plainText, contains('计数：甲 2（heads）；乙 1（tails）'));
    expect(share.plainText, contains(CoinTosser.algorithmVersion));
    for (final privateValue in <String>[
      'sensitive-session-id',
      'sensitive-parent-id',
    ]) {
      expect(history.summary, isNot(contains(privateValue)));
      expect(share.plainText, isNot(contains(privateValue)));
    }
  });
}
