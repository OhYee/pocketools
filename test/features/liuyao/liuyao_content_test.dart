import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/features/liuyao/content/liuyao_content_catalog.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_hexagrams.dart';
import 'package:pocketools/features/liuyao/domain/liuyao_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'original content covers all hexagrams with complete stable metadata',
    () {
      expect(LiuyaoContentCatalog.validate(), isEmpty);
      expect(LiuyaoContentCatalog.all, hasLength(64));
      expect(
        LiuyaoContentCatalog.all.map((content) => content.hexagramId).toSet(),
        hasLength(64),
      );
      for (final content in LiuyaoContentCatalog.all) {
        expect(content.title, isNotEmpty);
        expect(content.structureSummary, isNotEmpty);
        expect(content.classicText, isNotEmpty);
        expect(content.reflectionPrompt, isNotEmpty);
      }
    },
  );

  test(
    'static reading has explicit unchanged relationship and no changed content',
    () {
      final explanation = const LiuyaoInterpretationComposer().compose(
        _reading(<int>[7, 7, 7, 7, 7, 7]),
      );
      expect(explanation.changeRelationship, '无动爻，本卦不变。');
      expect(explanation.changed, isNull);
    },
  );

  test('moving reading explains structural change', () {
    final explanation = const LiuyaoInterpretationComposer().compose(
      _reading(<int>[6, 7, 8, 9, 7, 8]),
    );
    expect(explanation.changed, isNotNull);
    expect(explanation.changeRelationship, contains('第1爻由阴变阳'));
    expect(explanation.changeRelationship, contains('第4爻由阳变阴'));
  });

  test(
    'bundled line texts expose traditional line titles and originals',
    () async {
      final qian = await LiuyaoContentCatalog.lineContentsFor(
        LiuyaoHexagrams.all.first,
      );
      final kun = await LiuyaoContentCatalog.lineContentsFor(
        LiuyaoHexagrams.all[1],
      );

      expect(qian, hasLength(6));
      expect(qian.first.title, '初九');
      expect(qian.first.classicText, contains('潜龙勿用'));
      expect(qian.last.title, '上九');
      expect(kun.first.title, '初六');
      expect(kun[1].title, '六二');
      expect(kun.first.classicText, contains('履霜'));
      expect(
        LiuyaoContentCatalog.commonLineInterpretation(
          content: kun.first,
          moving: true,
        ),
        contains('重点结合爻辞'),
      );
    },
  );
}

LiuyaoReading _reading(List<int> values) => LiuyaoReading(
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
