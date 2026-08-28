import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_caster.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_hexagrams.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_models.dart';

void main() {
  group('Liuyao line rules', () {
    test('maps 6, 7, 8, and 9 to fixed natures and changes', () {
      final kinds = <int, LiuyaoLineKind>{
        6: LiuyaoLineKind.oldYin,
        7: LiuyaoLineKind.youngYang,
        8: LiuyaoLineKind.youngYin,
        9: LiuyaoLineKind.oldYang,
      };

      for (final entry in kinds.entries) {
        expect(LiuyaoLineKind.fromValue(entry.key), entry.value);
      }
      expect(LiuyaoLineKind.oldYin.nature, LiuyaoLineNature.yin);
      expect(LiuyaoLineKind.oldYin.changedNature, LiuyaoLineNature.yang);
      expect(LiuyaoLineKind.youngYang.changedNature, LiuyaoLineNature.yang);
      expect(LiuyaoLineKind.youngYin.changedNature, LiuyaoLineNature.yin);
      expect(LiuyaoLineKind.oldYang.nature, LiuyaoLineNature.yang);
      expect(LiuyaoLineKind.oldYang.changedNature, LiuyaoLineNature.yin);
    });

    test('automatic line freezes three coin sides and their sum', () {
      final random = SequenceRandomSource(<int>[0, 1, 0]);
      final reading = const LiuyaoCaster(_RandomProxy());
      final result = LiuyaoCaster(random)
          .appendAutomaticLine(LiuyaoReading(config: const LiuyaoConfig()));

      expect(reading, isA<LiuyaoCaster>());
      expect(result.lines.single.value, 8);
      expect(result.lines.single.coins, <LiuyaoCoinSide>[
        LiuyaoCoinSide.heads,
        LiuyaoCoinSide.tails,
        LiuyaoCoinSide.heads,
      ]);
      expect(random.consumed, 3);
    });

    test('manual line does not consume random values', () {
      final random = SequenceRandomSource(<int>[1]);
      final result = LiuyaoCaster(random).appendManualLine(
        LiuyaoReading(config: const LiuyaoConfig(mode: LiuyaoMode.manual)),
        9,
      );

      expect(result.lines.single.kind, LiuyaoLineKind.oldYang);
      expect(result.lines.single.coins, isNull);
      expect(random.consumed, 0);
    });

    test('invalid config and completed reading consume no entropy', () {
      final invalidRandom = SequenceRandomSource(<int>[0, 0, 0]);
      expect(
        () => LiuyaoReading(config: const LiuyaoConfig(intention: '\u0001')),
        throwsArgumentError,
      );
      expect(invalidRandom.consumed, 0);

      final complete = _manualReading(<int>[7, 7, 7, 7, 7, 7]);
      final random = SequenceRandomSource(<int>[0, 0, 0]);
      expect(
        () => LiuyaoCaster(random).appendAutomaticLine(complete),
        throwsA(isA<ArgumentError>()),
      );
      expect(random.consumed, 0);
    });

    test('undo works only for incomplete drafts', () {
      final draft = _manualReading(<int>[6, 7]);
      final undone = draft.undoLastLine();
      expect(undone.lines.map((line) => line.value), <int>[6]);
      expect(
        () => _manualReading(<int>[6, 7, 8, 9, 6, 7]).undoLastLine(),
        throwsStateError,
      );
    });
  });

  group('King Wen mapping', () {
    test('trigram ids and binary lines are unique and stable', () {
      expect(LiuyaoTrigrams.all, hasLength(8));
      expect(LiuyaoTrigrams.all.map((item) => item.id).toSet(), hasLength(8));
      expect(
        LiuyaoTrigrams.all.map((item) => item.lines.join()).toSet(),
        hasLength(8),
      );
      expect(LiuyaoTrigrams.qian.lines, <int>[1, 1, 1]);
      expect(LiuyaoTrigrams.kun.lines, <int>[0, 0, 0]);
    });

    test('all 64 upper/lower fixed vectors resolve to King Wen numbers', () {
      const matrix = <List<int>>[
        <int>[1, 10, 13, 25, 44, 6, 33, 12],
        <int>[43, 58, 49, 17, 28, 47, 31, 45],
        <int>[14, 38, 30, 21, 50, 64, 56, 35],
        <int>[34, 54, 55, 51, 32, 40, 62, 16],
        <int>[9, 61, 37, 42, 57, 59, 53, 20],
        <int>[5, 60, 63, 3, 48, 29, 39, 8],
        <int>[26, 41, 22, 27, 18, 4, 52, 23],
        <int>[11, 19, 36, 24, 46, 7, 15, 2],
      ];

      for (var upperIndex = 0; upperIndex < 8; upperIndex++) {
        for (var lowerIndex = 0; lowerIndex < 8; lowerIndex++) {
          final upper = LiuyaoTrigrams.all[upperIndex];
          final lower = LiuyaoTrigrams.all[lowerIndex];
          final values = <int>[
            ...lower.lines.map((value) => value == 1 ? 7 : 8),
            ...upper.lines.map((value) => value == 1 ? 7 : 8),
          ];
          final resolved = LiuyaoHexagrams.resolve(
            _manualReading(values).lines,
          );
          expect(
            resolved.kingWenNumber,
            matrix[upperIndex][lowerIndex],
            reason: 'upper=${upper.id}, lower=${lower.id}',
          );
        }
      }
    });

    test('moving lines alone form the changed hexagram', () {
      final reading = _manualReading(<int>[9, 7, 7, 7, 7, 9]);
      expect(LiuyaoHexagrams.resolve(reading.lines).kingWenNumber, 1);
      final changed = LiuyaoHexagrams.resolve(reading.lines, changed: true);
      expect(changed.upper, LiuyaoTrigrams.dui);
      expect(changed.lower, LiuyaoTrigrams.xun);
      expect(changed.kingWenNumber, 28);
    });
  });
}

LiuyaoReading _manualReading(List<int> values) => LiuyaoReading(
  config: const LiuyaoConfig(mode: LiuyaoMode.manual),
  lines: <LiuyaoLine>[
    for (var index = 0; index < values.length; index++)
      LiuyaoLine(
        index: index,
        value: values[index],
        source: LiuyaoLineSource.manualValue,
      ),
  ],
);

final class _RandomProxy implements RandomSource {
  const _RandomProxy();

  @override
  int nextInt(int maxExclusive) => 0;
}
