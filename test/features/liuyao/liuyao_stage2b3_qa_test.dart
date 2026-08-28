import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_registry.dart';
import 'package:pocketools/features/liuyao/content/liuyao_content_catalog.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_caster.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_hexagrams.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_models.dart';
import 'package:pocketools/features/liuyao/presentation/liuyao_session_codec.dart';
import 'package:pocketools/features/liuyao/presentation/liuyao_tool_module.dart';

void main() {
  group('Stage 2B3 independent trigram and King Wen snapshot', () {
    test('eight bottom-up binary trigrams keep stable ids and names', () {
      expect(LiuyaoTrigrams.all, hasLength(_expectedTrigrams.length));

      for (var index = 0; index < _expectedTrigrams.length; index++) {
        final expected = _expectedTrigrams[index];
        final actual = LiuyaoTrigrams.all[index];
        expect(actual.id, expected.id, reason: 'trigram index $index');
        expect(actual.name, expected.name, reason: expected.id);
        expect(actual.lines, expected.bottomUpBits, reason: expected.id);
        expect(LiuyaoTrigrams.byId(expected.id), same(actual));
        expect(
          LiuyaoTrigrams.fromLines(expected.bottomUpBits),
          same(actual),
          reason: expected.id,
        );
      }

      expect(
        LiuyaoTrigrams.all.map((trigram) => trigram.id).toSet(),
        hasLength(8),
      );
      expect(
        LiuyaoTrigrams.all.map((trigram) => trigram.name).toSet(),
        hasLength(8),
      );
      expect(
        LiuyaoTrigrams.all.map((trigram) => trigram.lines.join()).toSet(),
        hasLength(8),
      );
    });

    test(
      'all 64 names and upper lower combinations match an independent map',
      () {
        expect(_expectedHexagrams, hasLength(64));
        expect(
          _expectedHexagrams.map((item) => item.number),
          List<int>.generate(64, (index) => index + 1),
        );

        for (final expected in _expectedHexagrams) {
          final expectedId =
              'hexagram.${expected.number.toString().padLeft(2, '0')}';
          final upper = LiuyaoTrigrams.byId(expected.upperId);
          final lower = LiuyaoTrigrams.byId(expected.lowerId);
          final byNumber = LiuyaoHexagrams.byNumber(expected.number);

          expect(
            byNumber.id,
            expectedId,
            reason: 'King Wen ${expected.number}',
          );
          expect(byNumber.name, expected.name, reason: expectedId);
          expect(byNumber.upper.id, expected.upperId, reason: expectedId);
          expect(byNumber.lower.id, expected.lowerId, reason: expectedId);
          expect(LiuyaoHexagrams.byId(expectedId), same(byNumber));
          expect(
            LiuyaoHexagrams.fromTrigrams(upper: upper, lower: lower),
            same(byNumber),
            reason: expectedId,
          );

          final reading = _manualReading(<int>[
            ..._bitsFor(expected.lowerId).map(_staticValueForBit),
            ..._bitsFor(expected.upperId).map(_staticValueForBit),
          ]);
          final resolved = LiuyaoHexagrams.resolve(reading.lines);
          expect(resolved.id, expectedId, reason: expectedId);
          expect(resolved.name, expected.name, reason: expectedId);
          expect(resolved.upper.id, expected.upperId, reason: expectedId);
          expect(resolved.lower.id, expected.lowerId, reason: expectedId);
        }
      },
    );
  });

  group('Stage 2B3 independent line and entropy audit', () {
    test('6 7 8 9 map to exact original and changed line contracts', () {
      const expectations =
          <
            ({
              int value,
              LiuyaoLineKind kind,
              LiuyaoLineNature original,
              bool moving,
              LiuyaoLineNature changed,
            })
          >[
            (
              value: 6,
              kind: LiuyaoLineKind.oldYin,
              original: LiuyaoLineNature.yin,
              moving: true,
              changed: LiuyaoLineNature.yang,
            ),
            (
              value: 7,
              kind: LiuyaoLineKind.youngYang,
              original: LiuyaoLineNature.yang,
              moving: false,
              changed: LiuyaoLineNature.yang,
            ),
            (
              value: 8,
              kind: LiuyaoLineKind.youngYin,
              original: LiuyaoLineNature.yin,
              moving: false,
              changed: LiuyaoLineNature.yin,
            ),
            (
              value: 9,
              kind: LiuyaoLineKind.oldYang,
              original: LiuyaoLineNature.yang,
              moving: true,
              changed: LiuyaoLineNature.yin,
            ),
          ];

      for (final expected in expectations) {
        final line = LiuyaoLine(
          index: 0,
          value: expected.value,
          source: LiuyaoLineSource.manualValue,
        );
        expect(line.kind, expected.kind, reason: '${expected.value}');
        expect(line.nature, expected.original, reason: '${expected.value}');
        expect(line.isMoving, expected.moving, reason: '${expected.value}');
        expect(
          line.changedNature,
          expected.changed,
          reason: '${expected.value}',
        );
      }
    });

    test('changed hexagram flips only old yin and old yang positions', () {
      final reading = _manualReading(<int>[6, 7, 8, 9, 6, 9]);
      const originalBits = <int>[0, 1, 0, 1, 0, 1];
      const changedBits = <int>[1, 1, 0, 0, 1, 0];

      expect(_natureBits(reading, changed: false), originalBits);
      expect(_natureBits(reading, changed: true), changedBits);
      for (var index = 0; index < reading.lines.length; index++) {
        final line = reading.lines[index];
        expect(
          changedBits[index] != originalBits[index],
          line.value == 6 || line.value == 9,
          reason: 'line $index value ${line.value}',
        );
      }

      final primary = LiuyaoHexagrams.resolve(reading.lines);
      final changed = LiuyaoHexagrams.resolve(reading.lines, changed: true);
      expect(primary.lower.lines, originalBits.take(3));
      expect(primary.upper.lines, originalBits.skip(3));
      expect(changed.lower.lines, changedBits.take(3));
      expect(changed.upper.lines, changedBits.skip(3));
    });

    test(
      'all eight coin vectors use heads 3 tails 2 and three binary draws',
      () {
        expect(LiuyaoCoinSide.heads.points, 3);
        expect(LiuyaoCoinSide.tails.points, 2);

        for (var vector = 0; vector < 8; vector++) {
          final bits = <int>[(vector >> 2) & 1, (vector >> 1) & 1, vector & 1];
          final random = _BoundRecordingRandomSource(bits);
          final result = LiuyaoCaster(random)
              .appendAutomaticLine(LiuyaoReading(config: const LiuyaoConfig()));
          final expectedCoins = bits
              .map(
                (bit) => bit == 0 ? LiuyaoCoinSide.heads : LiuyaoCoinSide.tails,
              )
              .toList(growable: false);
          final expectedValue = expectedCoins.fold<int>(
            0,
            (sum, coin) => sum + coin.points,
          );

          expect(random.bounds, <int>[2, 2, 2], reason: 'vector=$bits');
          expect(result.lines.single.coins, expectedCoins, reason: '$bits');
          expect(result.lines.single.value, expectedValue, reason: '$bits');
        }
      },
    );

    test('six automatic lines consume exactly 18 binary draws bottom-up', () {
      const entropy = <int>[
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        1,
        0,
        0,
        1,
        1,
        1,
        0,
        0,
        1,
        0,
        1,
      ];
      final random = _BoundRecordingRandomSource(entropy);
      final caster = LiuyaoCaster(random);
      var reading = LiuyaoReading(config: const LiuyaoConfig());
      for (var index = 0; index < LiuyaoReading.lineCapacity; index++) {
        reading = caster.appendAutomaticLine(reading);
      }

      expect(random.bounds, List<int>.filled(18, 2));
      expect(reading.lines.map((line) => line.index), <int>[0, 1, 2, 3, 4, 5]);
      expect(reading.lines.map((line) => line.value), <int>[9, 8, 8, 7, 8, 7]);
      expect(reading.isComplete, isTrue);
    });

    test('random failures never return or append a partial automatic line', () {
      for (final failAt in <int>[0, 1, 2]) {
        final source = _FailingRandomSource(failAt: failAt);
        final original = LiuyaoReading(config: const LiuyaoConfig());

        expect(
          () => LiuyaoCaster(source).appendAutomaticLine(original),
          throwsStateError,
          reason: 'failAt=$failAt',
        );
        expect(source.calls, failAt + 1);
        expect(original.lines, isEmpty);
        expect(original.nextLineIndex, 0);
      }
    });

    test('manual values and invalid boundaries consume no random values', () {
      for (final value in <int>[6, 7, 8, 9]) {
        final random = _BoundRecordingRandomSource(const <int>[]);
        final result = LiuyaoCaster(random).appendManualLine(
          LiuyaoReading(config: const LiuyaoConfig(mode: LiuyaoMode.manual)),
          value,
        );
        expect(result.lines.single.value, value);
        expect(result.lines.single.source, LiuyaoLineSource.manualValue);
        expect(result.lines.single.coins, isNull);
        expect(random.bounds, isEmpty);
      }

      for (final invalid in <int>[-1, 0, 5, 10, 999]) {
        final random = _BoundRecordingRandomSource(const <int>[]);
        final original = LiuyaoReading(
          config: const LiuyaoConfig(mode: LiuyaoMode.manual),
        );
        expect(
          () => LiuyaoCaster(random).appendManualLine(original, invalid),
          throwsArgumentError,
          reason: 'invalid=$invalid',
        );
        expect(random.bounds, isEmpty);
        expect(original.lines, isEmpty);
      }
    });

    test(
      'draft undo is copy-on-write and completed readings are immutable',
      () {
        final draft = _manualReading(<int>[6, 7, 8]);
        final undone = draft.undoLastLine();
        expect(draft.lines.map((line) => line.value), <int>[6, 7, 8]);
        expect(undone.lines.map((line) => line.value), <int>[6, 7]);
        expect(() => draft.lines.removeLast(), throwsUnsupportedError);

        final automatic = LiuyaoReading(
          config: const LiuyaoConfig(),
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
        expect(
          () => automatic.lines.single.coins!.clear(),
          throwsUnsupportedError,
        );

        final complete = _manualReading(<int>[6, 7, 8, 9, 7, 8]);
        expect(() => complete.undoLastLine(), throwsStateError);
        expect(
          () => complete.append(
            LiuyaoLine(
              index: 0,
              value: 7,
              source: LiuyaoLineSource.manualValue,
            ),
          ),
          throwsStateError,
        );
        expect(() => complete.lines.clear(), throwsUnsupportedError);
      },
    );
  });

  group('Stage 2B3 independent codec and recovery attacks', () {
    const codec = LiuyaoSessionCodec();

    test(
      'input codec rejects unknown mode missing extra and scalar pollution',
      () {
        final valid = codec.encodeInput(
          const LiuyaoConfig(mode: LiuyaoMode.manual, intention: 'local'),
        );
        final attacks = <Map<String, Object?>>[
          <String, Object?>{...valid, 'mode': 'oracle'},
          <String, Object?>{...valid, 'mode': 1},
          <String, Object?>{...valid, 'intention': <Object?>[]},
          <String, Object?>{...valid, 'lineCapacity': 5},
          <String, Object?>{...valid, 'lineCapacity': 6.0},
          <String, Object?>{...valid, 'extra': true},
          _withoutKey(valid, 'mode'),
          _withoutKey(valid, 'intention'),
          _withoutKey(valid, 'lineCapacity'),
        ];

        for (final attack in attacks) {
          expect(
            () => codec.decodeInput(attack),
            throwsFormatException,
            reason: attack.toString(),
          );
        }
      },
    );

    test(
      'outcome codec rejects line identity source kind coin and type attacks',
      () {
        final config = const LiuyaoConfig();
        final valid = codec.encodeOutcome(_automaticDraft());
        final validLine = _lineAt(valid, 0);
        final attacks = <Map<String, Object?>>[
          <String, Object?>{...valid, 'lineCount': 1.0},
          <String, Object?>{...valid, 'lines': 'not-a-list'},
          <String, Object?>{...valid, 'complete': 'false'},
          <String, Object?>{...valid, 'contentVersion': 'unknown'},
          <String, Object?>{...valid, 'extra': true},
          _withoutKey(valid, 'lines'),
          <String, Object?>{
            ...valid,
            'lines': <Object?>[
              <String, Object?>{...validLine, 'sequence': 1},
            ],
          },
          <String, Object?>{
            ...valid,
            'lines': <Object?>[
              <String, Object?>{...validLine, 'value': 5},
            ],
          },
          <String, Object?>{
            ...valid,
            'lines': <Object?>[
              <String, Object?>{...validLine, 'value': 9},
            ],
          },
          <String, Object?>{
            ...valid,
            'lines': <Object?>[
              <String, Object?>{...validLine, 'source': 'automatic'},
            ],
          },
          <String, Object?>{
            ...valid,
            'lines': <Object?>[
              <String, Object?>{...validLine, 'kind': 'oldYin'},
            ],
          },
          <String, Object?>{
            ...valid,
            'lines': <Object?>[
              <String, Object?>{
                ...validLine,
                'coins': <Object?>['heads', 'tails'],
              },
            ],
          },
          <String, Object?>{
            ...valid,
            'lines': <Object?>[
              <String, Object?>{
                ...validLine,
                'coins': <Object?>['heads', 'tails', 'edge'],
              },
            ],
          },
          <String, Object?>{
            ...valid,
            'lines': <Object?>[
              <String, Object?>{...validLine, 'coins': true},
            ],
          },
          <String, Object?>{
            ...valid,
            'lines': <Object?>[
              <Object?, Object?>{0: 'illegal-key'},
            ],
          },
        ];

        for (final attack in attacks) {
          expect(
            () => codec.decodeOutcome(attack, config),
            throwsFormatException,
            reason: attack.toString(),
          );
        }

        expect(
          () => codec.decodeOutcome(
            valid,
            const LiuyaoConfig(mode: LiuyaoMode.manual),
          ),
          throwsFormatException,
        );
      },
    );

    test('codec rejects inconsistent complete and hexagram states', () {
      final moving = _manualReading(<int>[6, 7, 8, 9, 7, 8]);
      final validMoving = codec.encodeOutcome(moving);
      final staticReading = _manualReading(<int>[7, 7, 7, 7, 7, 7]);
      final validStatic = codec.encodeOutcome(staticReading);
      final attacks = <(Map<String, Object?>, LiuyaoConfig)>[
        (<String, Object?>{...validMoving, 'complete': false}, moving.config),
        (<String, Object?>{...validMoving, 'lineCount': 5}, moving.config),
        (
          <String, Object?>{...validMoving, 'primaryHexagramId': 'hexagram.64'},
          moving.config,
        ),
        (
          <String, Object?>{...validMoving, 'changedHexagramId': 'hexagram.01'},
          moving.config,
        ),
        (
          <String, Object?>{...validStatic, 'changedHexagramId': 'hexagram.01'},
          staticReading.config,
        ),
        (
          <String, Object?>{
            ...codec.encodeOutcome(_manualReading(<int>[7, 8])),
            'primaryHexagramId': 'hexagram.01',
          },
          const LiuyaoConfig(mode: LiuyaoMode.manual),
        ),
      ];

      for (final attack in attacks) {
        expect(
          () => codec.decodeOutcome(attack.$1, attack.$2),
          throwsFormatException,
          reason: attack.$1.toString(),
        );
      }
    });

    test(
      'valid draft and complete envelopes restore the same session identity',
      () async {
        final repository = InMemorySessionRepository();
        final module = LiuyaoToolModule(sessionRepository: repository);
        final draft = _manualReading(<int>[6, 7]);
        final complete = _manualReading(<int>[6, 7, 8, 9, 7, 8]);
        final draftSession = module.toolSessionAdapter.createSession(
          id: 'qa-liuyao-draft',
          schemaVersion: 1,
          ruleVersion: LiuyaoCaster.ruleVersion,
          algorithmVersion: LiuyaoCaster.manualAlgorithmVersion,
          status: SessionStatus.ready,
          input: draft.config,
          outcome: draft,
          parentSessionId: 'qa-draft-parent',
        );
        final completeSession = module.toolSessionAdapter.createSession(
          id: 'qa-liuyao-complete',
          schemaVersion: 1,
          ruleVersion: LiuyaoCaster.ruleVersion,
          algorithmVersion: LiuyaoCaster.manualAlgorithmVersion,
          status: SessionStatus.completed,
          input: complete.config,
          outcome: complete,
          parentSessionId: 'qa-complete-parent',
        );

        await repository.save(draftSession);
        await repository.save(completeSession);
        for (final expected in <SessionRecord>[draftSession, completeSession]) {
          final restored = await repository.findById(expected.id);
          expect(restored, same(expected));
          final decoded = module.toolSessionAdapter.decode(restored!);
          final reading = decoded.outcome as LiuyaoReading;
          expect(restored.id, expected.id);
          expect(restored.parentSessionId, expected.parentSessionId);
          expect(restored.ruleVersion, LiuyaoCaster.ruleVersion);
          expect(
            reading.lines.map((line) => line.value),
            (expected.id == draftSession.id ? draft : complete).lines.map(
              (line) => line.value,
            ),
          );
        }
      },
    );
  });

  group('Stage 2B3 independent content history and privacy audit', () {
    test('all 64 bundled content entries are complete', () {
      expect(LiuyaoContentCatalog.validate(), isEmpty);
      expect(LiuyaoContentCatalog.all, hasLength(64));

      for (var index = 0; index < _expectedHexagrams.length; index++) {
        final expected = _expectedHexagrams[index];
        final content = LiuyaoContentCatalog.all[index];
        expect(
          content.hexagramId,
          'hexagram.${expected.number.toString().padLeft(2, '0')}',
        );
        expect(content.title, contains(expected.name));
        expect(content.structureSummary.trim(), isNotEmpty);
        expect(content.reflectionPrompt.trim(), isNotEmpty);
      }
      expect(() => LiuyaoContentCatalog.all.clear(), throwsUnsupportedError);
    });

    test(
      'all bundled text avoids external quotation and deterministic advice',
      () {
        final text = <String>[
          for (final content in LiuyaoContentCatalog.all) ...<String>[
            content.title,
            content.structureSummary,
            content.reflectionPrompt,
          ],
        ].join('\n');

        for (final forbidden in <String>[
          'http://',
          'https://',
          'www.',
          '摘录自',
          '原文引自',
          '逐字翻译',
          '现代译文如下',
          '你注定',
          '必然发生',
          '一定会发生',
          '大吉',
          '大凶',
          '准确率',
          '诊断为',
          '治疗方案是',
          '法律结论是',
          '必须买入',
          '必须卖出',
        ]) {
          expect(text, isNot(contains(forbidden)), reason: forbidden);
        }
        expect(text, isNot(contains('内容边界')));
        expect(text, isNot(contains('专业建议')));
      },
    );

    test(
      'history and share retain structure and versions while redacting privacy',
      () {
        const privateText = 'QA_PRIVATE_LIUYAO_INTENTION_2B3';
        const sessionId = 'QA_PRIVATE_LIUYAO_SESSION_2B3';
        const parentId = 'QA_PRIVATE_LIUYAO_PARENT_2B3';
        final module = LiuyaoToolModule();
        final registry = ToolRegistry(<LiuyaoToolModule>[module]);
        final reading = _manualReading(<int>[
          6,
          7,
          8,
          9,
          7,
          8,
        ], intention: privateText);
        final session = registry.createCompletedSession(
          toolId: 'liuyao',
          id: sessionId,
          schemaVersion: 1,
          ruleVersion: LiuyaoCaster.ruleVersion,
          algorithmVersion: LiuyaoCaster.manualAlgorithmVersion,
          input: reading.config,
          outcome: reading,
          parentSessionId: parentId,
        );

        final history = registry.historySummary(session);
        final share = registry.sharePayload(session);
        final decoded = registry.decode(session).outcome as LiuyaoReading;
        final primary = LiuyaoHexagrams.resolve(decoded.lines);
        final changed = LiuyaoHexagrams.resolve(decoded.lines, changed: true);

        expect(
          history.summary,
          contains('第 ${primary.kingWenNumber} 卦 ${primary.name}'),
        );
        expect(history.summary, contains('动爻 1、4'));
        expect(session.outcome['primaryHexagramId'], primary.id);
        expect(session.outcome['changedHexagramId'], changed.id);
        expect(session.ruleVersion, LiuyaoCaster.ruleVersion);
        expect(share.plainText, contains('本卦：'));
        expect(share.plainText, contains('变卦：'));
        expect(share.plainText, contains('动爻 1、4'));
        expect(share.plainText, contains('规则版本：${LiuyaoCaster.ruleVersion}'));
        expect(
          share.plainText,
          contains('算法版本：${LiuyaoCaster.manualAlgorithmVersion}'),
        );
        for (final privateValue in <String>[privateText, sessionId, parentId]) {
          expect(history.summary, isNot(contains(privateValue)));
          expect(share.summary, isNot(contains(privateValue)));
          expect(share.plainText, isNot(contains(privateValue)));
        }
      },
    );

    test(
      'static result says unchanged and never manufactures a changed hexagram',
      () {
        final module = LiuyaoToolModule();
        final registry = ToolRegistry(<LiuyaoToolModule>[module]);
        final reading = _manualReading(<int>[7, 8, 7, 8, 7, 8]);
        final session = registry.createCompletedSession(
          toolId: 'liuyao',
          id: 'static-reading',
          schemaVersion: 1,
          ruleVersion: LiuyaoCaster.ruleVersion,
          algorithmVersion: LiuyaoCaster.manualAlgorithmVersion,
          input: reading.config,
          outcome: reading,
        );

        final history = registry.historySummary(session);
        final share = registry.sharePayload(session);
        expect(history.summary, contains('无动爻'));
        expect(session.outcome['changedHexagramId'], isNull);
        expect(share.plainText, contains('无动爻，本卦不变。'));
        expect(share.plainText, isNot(contains('变卦：')));
      },
    );
  });
}

Map<String, Object?> _withoutKey(Map<String, Object?> source, String key) =>
    <String, Object?>{...source}..remove(key);

Map<String, Object?> _lineAt(Map<String, Object?> outcome, int index) =>
    Map<String, Object?>.from(
      (outcome['lines']! as List<Object?>)[index]! as Map,
    );

LiuyaoReading _automaticDraft() => LiuyaoReading(
  config: const LiuyaoConfig(),
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

List<int> _natureBits(LiuyaoReading reading, {required bool changed}) => reading
    .lines
    .map(
      (line) =>
          (changed ? line.changedNature : line.nature) == LiuyaoLineNature.yang
          ? 1
          : 0,
    )
    .toList(growable: false);

int _staticValueForBit(int bit) => bit == 1 ? 7 : 8;

List<int> _bitsFor(String trigramId) => _expectedTrigrams
    .singleWhere((expected) => expected.id == trigramId)
    .bottomUpBits;

final class _BoundRecordingRandomSource implements RandomSource {
  _BoundRecordingRandomSource(Iterable<int> values)
    : _values = List<int>.unmodifiable(values);

  final List<int> _values;
  final List<int> bounds = <int>[];
  var _index = 0;

  @override
  int nextInt(int maxExclusive) {
    bounds.add(maxExclusive);
    if (_index >= _values.length) {
      throw StateError('Independent entropy vector exhausted.');
    }
    final value = _values[_index++];
    if (value < 0 || value >= maxExclusive) {
      throw StateError('Vector value $value is outside bound $maxExclusive.');
    }
    return value;
  }
}

final class _FailingRandomSource implements RandomSource {
  _FailingRandomSource({required this.failAt});

  final int failAt;
  var calls = 0;

  @override
  int nextInt(int maxExclusive) {
    final current = calls++;
    if (current == failAt) throw StateError('Injected entropy failure.');
    return 0;
  }
}

const _expectedTrigrams = <({String id, String name, List<int> bottomUpBits})>[
  (id: 'trigram.qian', name: '乾', bottomUpBits: <int>[1, 1, 1]),
  (id: 'trigram.dui', name: '兑', bottomUpBits: <int>[1, 1, 0]),
  (id: 'trigram.li', name: '离', bottomUpBits: <int>[1, 0, 1]),
  (id: 'trigram.zhen', name: '震', bottomUpBits: <int>[1, 0, 0]),
  (id: 'trigram.xun', name: '巽', bottomUpBits: <int>[0, 1, 1]),
  (id: 'trigram.kan', name: '坎', bottomUpBits: <int>[0, 1, 0]),
  (id: 'trigram.gen', name: '艮', bottomUpBits: <int>[0, 0, 1]),
  (id: 'trigram.kun', name: '坤', bottomUpBits: <int>[0, 0, 0]),
];

const _expectedHexagrams =
    <({int number, String name, String upperId, String lowerId})>[
      (number: 1, name: '乾', upperId: 'trigram.qian', lowerId: 'trigram.qian'),
      (number: 2, name: '坤', upperId: 'trigram.kun', lowerId: 'trigram.kun'),
      (number: 3, name: '屯', upperId: 'trigram.kan', lowerId: 'trigram.zhen'),
      (number: 4, name: '蒙', upperId: 'trigram.gen', lowerId: 'trigram.kan'),
      (number: 5, name: '需', upperId: 'trigram.kan', lowerId: 'trigram.qian'),
      (number: 6, name: '讼', upperId: 'trigram.qian', lowerId: 'trigram.kan'),
      (number: 7, name: '师', upperId: 'trigram.kun', lowerId: 'trigram.kan'),
      (number: 8, name: '比', upperId: 'trigram.kan', lowerId: 'trigram.kun'),
      (number: 9, name: '小畜', upperId: 'trigram.xun', lowerId: 'trigram.qian'),
      (number: 10, name: '履', upperId: 'trigram.qian', lowerId: 'trigram.dui'),
      (number: 11, name: '泰', upperId: 'trigram.kun', lowerId: 'trigram.qian'),
      (number: 12, name: '否', upperId: 'trigram.qian', lowerId: 'trigram.kun'),
      (number: 13, name: '同人', upperId: 'trigram.qian', lowerId: 'trigram.li'),
      (number: 14, name: '大有', upperId: 'trigram.li', lowerId: 'trigram.qian'),
      (number: 15, name: '谦', upperId: 'trigram.kun', lowerId: 'trigram.gen'),
      (number: 16, name: '豫', upperId: 'trigram.zhen', lowerId: 'trigram.kun'),
      (number: 17, name: '随', upperId: 'trigram.dui', lowerId: 'trigram.zhen'),
      (number: 18, name: '蛊', upperId: 'trigram.gen', lowerId: 'trigram.xun'),
      (number: 19, name: '临', upperId: 'trigram.kun', lowerId: 'trigram.dui'),
      (number: 20, name: '观', upperId: 'trigram.xun', lowerId: 'trigram.kun'),
      (number: 21, name: '噬嗑', upperId: 'trigram.li', lowerId: 'trigram.zhen'),
      (number: 22, name: '贲', upperId: 'trigram.gen', lowerId: 'trigram.li'),
      (number: 23, name: '剥', upperId: 'trigram.gen', lowerId: 'trigram.kun'),
      (number: 24, name: '复', upperId: 'trigram.kun', lowerId: 'trigram.zhen'),
      (
        number: 25,
        name: '无妄',
        upperId: 'trigram.qian',
        lowerId: 'trigram.zhen',
      ),
      (number: 26, name: '大畜', upperId: 'trigram.gen', lowerId: 'trigram.qian'),
      (number: 27, name: '颐', upperId: 'trigram.gen', lowerId: 'trigram.zhen'),
      (number: 28, name: '大过', upperId: 'trigram.dui', lowerId: 'trigram.xun'),
      (number: 29, name: '坎', upperId: 'trigram.kan', lowerId: 'trigram.kan'),
      (number: 30, name: '离', upperId: 'trigram.li', lowerId: 'trigram.li'),
      (number: 31, name: '咸', upperId: 'trigram.dui', lowerId: 'trigram.gen'),
      (number: 32, name: '恒', upperId: 'trigram.zhen', lowerId: 'trigram.xun'),
      (number: 33, name: '遁', upperId: 'trigram.qian', lowerId: 'trigram.gen'),
      (
        number: 34,
        name: '大壮',
        upperId: 'trigram.zhen',
        lowerId: 'trigram.qian',
      ),
      (number: 35, name: '晋', upperId: 'trigram.li', lowerId: 'trigram.kun'),
      (number: 36, name: '明夷', upperId: 'trigram.kun', lowerId: 'trigram.li'),
      (number: 37, name: '家人', upperId: 'trigram.xun', lowerId: 'trigram.li'),
      (number: 38, name: '睽', upperId: 'trigram.li', lowerId: 'trigram.dui'),
      (number: 39, name: '蹇', upperId: 'trigram.kan', lowerId: 'trigram.gen'),
      (number: 40, name: '解', upperId: 'trigram.zhen', lowerId: 'trigram.kan'),
      (number: 41, name: '损', upperId: 'trigram.gen', lowerId: 'trigram.dui'),
      (number: 42, name: '益', upperId: 'trigram.xun', lowerId: 'trigram.zhen'),
      (number: 43, name: '夬', upperId: 'trigram.dui', lowerId: 'trigram.qian'),
      (number: 44, name: '姤', upperId: 'trigram.qian', lowerId: 'trigram.xun'),
      (number: 45, name: '萃', upperId: 'trigram.dui', lowerId: 'trigram.kun'),
      (number: 46, name: '升', upperId: 'trigram.kun', lowerId: 'trigram.xun'),
      (number: 47, name: '困', upperId: 'trigram.dui', lowerId: 'trigram.kan'),
      (number: 48, name: '井', upperId: 'trigram.kan', lowerId: 'trigram.xun'),
      (number: 49, name: '革', upperId: 'trigram.dui', lowerId: 'trigram.li'),
      (number: 50, name: '鼎', upperId: 'trigram.li', lowerId: 'trigram.xun'),
      (number: 51, name: '震', upperId: 'trigram.zhen', lowerId: 'trigram.zhen'),
      (number: 52, name: '艮', upperId: 'trigram.gen', lowerId: 'trigram.gen'),
      (number: 53, name: '渐', upperId: 'trigram.xun', lowerId: 'trigram.gen'),
      (number: 54, name: '归妹', upperId: 'trigram.zhen', lowerId: 'trigram.dui'),
      (number: 55, name: '丰', upperId: 'trigram.zhen', lowerId: 'trigram.li'),
      (number: 56, name: '旅', upperId: 'trigram.li', lowerId: 'trigram.gen'),
      (number: 57, name: '巽', upperId: 'trigram.xun', lowerId: 'trigram.xun'),
      (number: 58, name: '兑', upperId: 'trigram.dui', lowerId: 'trigram.dui'),
      (number: 59, name: '涣', upperId: 'trigram.xun', lowerId: 'trigram.kan'),
      (number: 60, name: '节', upperId: 'trigram.kan', lowerId: 'trigram.dui'),
      (number: 61, name: '中孚', upperId: 'trigram.xun', lowerId: 'trigram.dui'),
      (number: 62, name: '小过', upperId: 'trigram.zhen', lowerId: 'trigram.gen'),
      (number: 63, name: '既济', upperId: 'trigram.kan', lowerId: 'trigram.li'),
      (number: 64, name: '未济', upperId: 'trigram.li', lowerId: 'trigram.kan'),
    ];
