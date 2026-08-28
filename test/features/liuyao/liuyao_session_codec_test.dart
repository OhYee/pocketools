import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_models.dart';
import 'package:pocketools/features/liuyao/presentation/liuyao_session_codec.dart';

void main() {
  const codec = LiuyaoSessionCodec();

  test('round-trips an ordered automatic partial draft', () {
    const config = LiuyaoConfig(
      mode: LiuyaoMode.automatic,
      intention: '  本机问题  ',
    );
    final reading = LiuyaoReading(
      config: config,
      lines: <LiuyaoLine>[
        LiuyaoLine(
          index: 0,
          value: 8,
          source: LiuyaoLineSource.automaticCoins,
          coins: const <LiuyaoCoinSide>[
            LiuyaoCoinSide.heads,
            LiuyaoCoinSide.tails,
            LiuyaoCoinSide.heads,
          ],
        ),
      ],
    );

    final decodedInput = codec.decodeInput(codec.encodeInput(config));
    final decoded = codec.decodeOutcome(
      codec.encodeOutcome(reading),
      decodedInput,
    );

    expect(decoded.config.normalizedIntention, '本机问题');
    expect(decoded.lines.single.value, 8);
    expect(decoded.lines.single.coins, reading.lines.single.coins);
    expect(decoded.isComplete, isFalse);
  });

  test('round-trips complete static result without a changed hexagram id', () {
    final reading = _manualReading(<int>[7, 7, 7, 7, 7, 7]);
    final encoded = codec.encodeOutcome(reading);

    expect(encoded['primaryHexagramId'], 'hexagram.01');
    expect(encoded['changedHexagramId'], isNull);
    final decoded = codec.decodeOutcome(encoded, reading.config);
    expect(decoded.isComplete, isTrue);
    expect(decoded.movingLineIndexes, isEmpty);
  });

  test('rejects coin/value mismatches and non-contiguous sequence', () {
    final input = codec.decodeInput(codec.encodeInput(const LiuyaoConfig()));
    final valid = codec.encodeOutcome(
      LiuyaoReading(
        config: input,
        lines: <LiuyaoLine>[
          LiuyaoLine(
            index: 0,
            value: 8,
            source: LiuyaoLineSource.automaticCoins,
            coins: const <LiuyaoCoinSide>[
              LiuyaoCoinSide.heads,
              LiuyaoCoinSide.tails,
              LiuyaoCoinSide.heads,
            ],
          ),
        ],
      ),
    );
    final line = Map<String, Object?>.from(
      (valid['lines']! as List).single as Map,
    );
    final badValue = <String, Object?>{
      ...valid,
      'lines': <Object?>[
        <String, Object?>{...line, 'value': 9},
      ],
    };
    final badSequence = <String, Object?>{
      ...valid,
      'lines': <Object?>[
        <String, Object?>{...line, 'sequence': 1},
      ],
    };

    expect(
      () => codec.decodeOutcome(badValue, input),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => codec.decodeOutcome(badSequence, input),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects inconsistent completion and explicit hexagram ids', () {
    final reading = _manualReading(<int>[6, 7, 8, 9, 7, 8]);
    final encoded = codec.encodeOutcome(reading);
    final badComplete = <String, Object?>{...encoded, 'complete': false};
    final badPrimary = <String, Object?>{
      ...encoded,
      'primaryHexagramId': 'hexagram.64',
    };
    final badChanged = <String, Object?>{
      ...encoded,
      'changedHexagramId': 'hexagram.01',
    };

    expect(
      () => codec.decodeOutcome(badComplete, reading.config),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => codec.decodeOutcome(badPrimary, reading.config),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => codec.decodeOutcome(badChanged, reading.config),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects mode/source mismatch, unknown fields, and content version', () {
    final reading = _manualReading(<int>[7]);
    final encoded = codec.encodeOutcome(reading);
    expect(
      () => codec.decodeOutcome(
        encoded,
        const LiuyaoConfig(mode: LiuyaoMode.automatic),
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => codec.decodeOutcome(<String, Object?>{
        ...encoded,
        'extra': true,
      }, reading.config),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => codec.decodeOutcome(<String, Object?>{
        ...encoded,
        'contentVersion': 'unknown',
      }, reading.config),
      throwsA(isA<FormatException>()),
    );
  });

  test('summary excludes private intention and local session id', () {
    final reading = _manualReading(<int>[7, 7], intention: 'private-question');
    final session = SessionRecord(
      id: 'private-session-id',
      toolId: 'liuyao',
      schemaVersion: 1,
      ruleVersion: 'rule',
      algorithmVersion: 'algorithm',
      status: SessionStatus.ready,
      input: codec.encodeInput(reading.config),
      outcome: codec.encodeOutcome(reading),
    );

    expect(codec.summarize(session), '手工录入 · 已完成 2/6 爻');
    expect(codec.summarize(session), isNot(contains('private-question')));
    expect(codec.summarize(session), isNot(contains('private-session-id')));
  });
}

LiuyaoReading _manualReading(List<int> values, {String? intention}) =>
    LiuyaoReading(
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
