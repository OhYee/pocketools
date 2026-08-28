import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_caster.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_models.dart';
import 'package:pocketools/features/liuyao/presentation/liuyao_tool_module.dart';
import 'package:pocketools/features/tarot/content/tarot_content_catalog.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';
import 'package:pocketools/features/tarot/domain/tarot_reader.dart';
import 'package:pocketools/features/tarot/presentation/tarot_tool_module.dart';

void main() {
  test('tarot replay strips intention while optional share can declare it', () {
    final module = TarotToolModule();
    final registry = ToolRegistry(<ToolModule>[module]);
    const config = TarotReadingConfig(intention: 'private tarot question');
    final result = TarotReader(
      SequenceRandomSource(List<int>.filled(78, 0)),
      contentVersion: TarotContentCatalog.contentVersion,
    ).draw(config);
    final session = module.toolSessionAdapter.createSession(
      id: 'tarot-private',
      schemaVersion: 1,
      ruleVersion: TarotReader.ruleVersion,
      algorithmVersion: TarotReader.algorithmVersion,
      status: SessionStatus.completed,
      input: config,
      outcome: result,
    );

    final replay = registry.replayRequest(session);
    expect((replay.initialConfig! as TarotReadingConfig).intention, isNull);
    expect(replay.parentSessionId, session.id);
    expect(
      registry.sharePayload(session).plainText,
      isNot(contains('private tarot question')),
    );
    expect(
      registry.optionalShareFields(session).single.value,
      'private tarot question',
    );
  });

  test('liuyao replay strips intention and preserves non-private mode', () {
    final module = LiuyaoToolModule();
    final registry = ToolRegistry(<ToolModule>[module]);
    const config = LiuyaoConfig(
      mode: LiuyaoMode.manual,
      intention: 'private liuyao intention',
    );
    var reading = LiuyaoReading(config: config);
    final caster = LiuyaoCaster(SequenceRandomSource(const <int>[]));
    for (final value in const <int>[6, 7, 8, 9, 7, 8]) {
      reading = caster.appendManualLine(reading, value);
    }
    final session = module.toolSessionAdapter.createSession(
      id: 'liuyao-private',
      schemaVersion: 1,
      ruleVersion: LiuyaoCaster.ruleVersion,
      algorithmVersion: LiuyaoCaster.manualAlgorithmVersion,
      status: SessionStatus.completed,
      input: config,
      outcome: reading,
    );

    final replay = registry.replayRequest(session);
    final replayConfig = replay.initialConfig! as LiuyaoConfig;
    expect(replayConfig.mode, LiuyaoMode.manual);
    expect(replayConfig.intention, isNull);
    expect(
      registry.sharePayload(session).plainText,
      isNot(contains('private liuyao intention')),
    );
    expect(
      registry.optionalShareFields(session).single.value,
      'private liuyao intention',
    );
  });
}
