import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_registry.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_caster.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_models.dart';
import 'package:pocketools/features/liuyao/presentation/liuyao_tool_module.dart';

void main() {
  test(
    'module participates in registry session, history, and share pipeline',
    () {
      final module = LiuyaoToolModule();
      final registry = ToolRegistry(<LiuyaoToolModule>[module]);
      final reading = _reading(<int>[
        6,
        7,
        8,
        9,
        7,
        8,
      ], intention: 'private question');
      final session = module.toolSessionAdapter.createSession(
        id: 'private-id',
        schemaVersion: 1,
        ruleVersion: LiuyaoCaster.ruleVersion,
        algorithmVersion: LiuyaoCaster.manualAlgorithmVersion,
        status: SessionStatus.completed,
        input: reading.config,
        outcome: reading,
        parentSessionId: 'private-parent',
      );

      expect(module.descriptor.id, 'liuyao');
      expect(module.descriptor.route, '/tools/liuyao');
      expect(module.descriptor.availability.name, 'available');
      expect(module.descriptor.icon, Icons.reorder);
      expect(registry.decode(session).outcome, isA<LiuyaoReading>());
      expect(registry.historySummary(session).summary, contains('动爻'));

      final share = registry.sharePayload(session).plainText;
      expect(share, contains('初爻：和值 6'));
      expect(share.indexOf('初爻'), lessThan(share.indexOf('第二爻')));
      expect(share, contains('本卦'));
      expect(share, contains('变卦'));
      expect(share, isNot(contains('Pocketools original')));
      expect(share, isNot(contains('文化学习、娱乐与自我反思')));
      expect(share, isNot(contains('内容边界')));
      expect(share, isNot(contains('private question')));
      expect(share, isNot(contains('private-id')));
      expect(share, isNot(contains('private-parent')));
    },
  );

  test('linked draft preserves only rules and parent relationship', () {
    final module = LiuyaoToolModule();
    const config = LiuyaoConfig(
      mode: LiuyaoMode.manual,
      intention: 'do not copy',
    );
    final draftConfig = config.normalized(includeIntention: false);
    final session = module.toolSessionAdapter.createSession(
      id: 'new-id',
      schemaVersion: 1,
      ruleVersion: LiuyaoCaster.ruleVersion,
      algorithmVersion: LiuyaoCaster.manualAlgorithmVersion,
      status: SessionStatus.draft,
      input: draftConfig,
      outcome: LiuyaoReading(config: draftConfig),
      parentSessionId: 'old-id',
    );

    final decoded = module.toolSessionAdapter.decode(session);
    expect((decoded.input as LiuyaoConfig).mode, LiuyaoMode.manual);
    expect((decoded.input as LiuyaoConfig).normalizedIntention, isNull);
    expect(session.parentSessionId, 'old-id');
  });
}

LiuyaoReading _reading(List<int> values, {String? intention}) => LiuyaoReading(
  config: LiuyaoConfig(mode: LiuyaoMode.manual, intention: intention),
  lines: <LiuyaoLine>[
    for (var index = 0; index < values.length; index++)
      LiuyaoLine(
        index: index,
        value: values[index],
        source: LiuyaoLineSource.manualValue,
      ),
  ],
);
