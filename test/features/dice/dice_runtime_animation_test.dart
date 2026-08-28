import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/assets/runtime/runtime_asset_manifest.dart';
import 'package:pocketools/design_system/components/app_physics_motion.dart';

void main() {
  test('D20 tile renders a deterministic rolling face primitive', () {
    final tile = File(
      'lib/features/dice/presentation/widgets/dice_roll_tile.dart',
    ).readAsStringSync();
    final page = File('lib/features/dice/presentation/dice_tool_page.dart')
        .readAsStringSync();

    expect(tile, contains('D20RollPrimitive'));
    expect(tile, contains('RuntimeAssetManifest.d20Face'));
    expect(tile, contains('rotateZ('));
    expect(tile, contains('math.sin('));
    expect(tile, isNot(contains('..rotateY(rotation)')));
    expect(tile, contains('stopFace'));
    expect(page, isNot(contains('DiceRollTile(')));
    expect(page, contains('GenerationPhase.revealing'));
    expect(tile, contains('showValue'));
    expect(page, contains('showValue:'));
    expect(page, contains('result != null'));
    expect(tile, isNot(contains('RandomSource')));
    expect(tile, isNot(contains('http://')));
    expect(tile, isNot(contains('https://')));
  });

  test('D20 runtime asset contract stays local and versioned', () {
    final manifest = File('lib/assets/runtime/runtime_asset_manifest.dart');

    expect(manifest.existsSync(), isTrue);
  });

  test(
    'D20 trajectory has a flight arc and a deterministic stop face path',
    () {
      expect(AppPhysics.d20Landing(0), closeTo(0, 0.001));
      expect(AppPhysics.d20Landing(0.39), lessThan(-15));
      expect(AppPhysics.d20Landing(0.78), closeTo(0, 0.001));

      final face = RuntimeAssetManifest.d20Face(
        value: 20,
        semanticLabel: 'D20 20 点面',
      );
      expect(face.path, 'assets/runtime/d20_blank.png');
      expect(face.kind, RuntimeAssetKind.d20Face);
    },
  );
}
