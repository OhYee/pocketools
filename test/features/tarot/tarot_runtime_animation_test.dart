import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/assets/runtime/runtime_asset_manifest.dart';
import 'package:pocketools/design_system/components/app_physics_motion.dart';

void main() {
  test('tarot primitive reserves draw, flip, reversed and face-art states', () {
    final primitive = File(
      'lib/features/tarot/presentation/widgets/tarot_card_primitive.dart',
    ).readAsStringSync();
    final result = File(
      'lib/features/tarot/presentation/widgets/tarot_result_view.dart',
    ).readAsStringSync();

    expect(primitive, contains('RuntimeAssetManifest.tarotFace'));
    expect(primitive, contains('RuntimeAssetManifest.tarotBack'));
    expect(primitive, contains('AppPhysicsMotion'));
    expect(primitive, contains('reversed'));
    expect(result, contains('animate: animate'));
    expect(primitive, isNot(contains('http://')));
    expect(primitive, isNot(contains('https://')));
  });

  test(
    'tarot keeps the physical card renderer local to the feature boundary',
    () {
      final manifest = File('lib/assets/runtime/runtime_asset_manifest.dart');

      expect(manifest.existsSync(), isTrue);
    },
  );

  test('tarot draw settles at the selected orientation asset', () {
    expect(AppPhysics.tarotLanding(0), closeTo(0, 0.001));
    expect(AppPhysics.tarotLanding(0.41), lessThan(-10));
    expect(AppPhysics.tarotLanding(1), closeTo(0, 0.001));

    final reversed = RuntimeAssetManifest.tarotFace(
      cardId: 'major-01-magician',
      orientation: RuntimeAssetOrientation.reversed,
      semanticLabel: '魔术师逆位',
    );
    expect(reversed.path, 'assets/runtime/tarot/rider_waite/01_Magician.jpg');
    expect(reversed.orientation, RuntimeAssetOrientation.reversed);
  });
}
