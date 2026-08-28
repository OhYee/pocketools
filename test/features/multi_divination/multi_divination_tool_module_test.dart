import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_id_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';
import 'package:pocketools/features/multi_divination/domain/multi_divination_models.dart';
import 'package:pocketools/features/multi_divination/domain/multi_divination_reader.dart';
import 'package:pocketools/features/multi_divination/presentation/multi_divination_tool_module.dart';

void main() {
  test('module adapter provides privacy-safe history and share payloads', () {
    final module = MultiDivinationToolModule(
      sessionRepository: InMemorySessionRepository(),
      sessionIdSource: _FixedIdSource(),
    );
    final registry = ToolRegistry(<ToolModule>[module]);
    final config = const MultiDivinationConfig(intention: 'private question');
    final reading = _completeReading(config);
    final session = registry.createCompletedSession(
      toolId: module.descriptor.id,
      id: 'private-session',
      schemaVersion: 1,
      ruleVersion: MultiDivinationReading.ruleVersion,
      algorithmVersion: MultiDivinationReading.algorithmVersion,
      input: config,
      outcome: reading,
    );

    final history = registry.historySummary(session);
    final share = registry.sharePayload(session);

    expect(module.descriptor.id, 'multi_divination');
    expect(module.descriptor.name, '多重占卜');
    expect(history.summary, contains('本卦'));
    expect(history.summary, contains('变卦'));
    expect(share.plainText, contains('标准融合'));
    expect(share.plainText, contains('本卦'));
    expect(share.plainText, isNot(contains('内容边界')));
    expect(share.plainText, isNot(contains('专业建议')));
    expect(share.plainText, isNot(contains('Pocketools original')));
    expect(share.plainText, isNot(contains('Apache-2.0')));
    expect(share.plainText, isNot(contains('private question')));
    expect(share.plainText, isNot(contains('private-session')));
  });

  test('module replay omits the private intention', () {
    final module = MultiDivinationToolModule(
      sessionRepository: InMemorySessionRepository(),
      sessionIdSource: _FixedIdSource(),
    );
    final config = const MultiDivinationConfig(intention: 'private question');
    final reading = MultiDivinationReading(config: config);
    final session = module.toolSessionAdapter.createSession(
      id: 'session',
      schemaVersion: 1,
      ruleVersion: MultiDivinationReading.ruleVersion,
      algorithmVersion: MultiDivinationReading.algorithmVersion,
      status: SessionStatus.draft,
      input: config,
      outcome: reading,
    );
    final decoded = module.toolSessionAdapter.decode(session);

    final replayed = module.replayInput(session, decoded);
    expect(replayed, isA<MultiDivinationConfig>());
    expect((replayed as MultiDivinationConfig).normalizedIntention, isNull);
    expect(
      module.optionalShareFields(session, decoded).single.value,
      'private question',
    );
  });
}

MultiDivinationReading _completeReading(MultiDivinationConfig config) {
  var reading = MultiDivinationReading(config: config);
  final reader = MultiDivinationReader(
    SequenceRandomSource(<int>[
      ...List<int>.filled(77, 0),
      ...List<int>.filled(18, 0),
    ]),
  );
  for (var index = 0; index < MultiDivinationReading.groupCapacity; index++) {
    reading = reader.appendGroup(reading);
  }
  return reading;
}

final class _FixedIdSource implements SessionIdSource {
  @override
  String next() => 'fixed';
}
