import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/assets/runtime/runtime_asset_manifest.dart';
import 'package:pocketools/design_system/components/app_runtime_asset.dart';
import 'package:pocketools/design_system/components/app_physics_motion.dart';

void main() {
  test(
    'coin motion owns a local face manifest and a physical landing layer',
    () {
      final primitive = File(
        'lib/features/coin/presentation/widgets/coin_primitive.dart',
      ).readAsStringSync();

      expect(primitive, contains('RuntimeAssetManifest.coinFace'));
      expect(primitive, contains('AppPhysicsMotion'));
      expect(primitive, contains('coinLanding'));
      expect(primitive, isNot(contains('http://')));
      expect(primitive, isNot(contains('https://')));
    },
  );

  test('independent coin flips around the horizontal X axis', () {
    final primitive = File(
      'lib/features/coin/presentation/widgets/coin_primitive.dart',
    ).readAsStringSync();

    expect(primitive, contains('rotateX(rotation)'));
    expect(primitive, isNot(contains('rotateY(rotation)')));
  });

  test('shared physics primitive is available to feature animations', () {
    final physics = File(
      'lib/design_system/components/app_physics_motion.dart',
    );

    expect(physics.existsSync(), isTrue);
  });

  test(
    'coin arc rises, lands, and settles without changing the frozen side',
    () {
      expect(AppPhysics.coinLanding(0), closeTo(0, 0.001));
      expect(AppPhysics.coinLanding(0.36), lessThan(-40));
      expect(AppPhysics.coinLanding(0.72), closeTo(0, 0.001));
      expect(AppPhysics.coinLanding(1), closeTo(0, 0.001));

      final heads = RuntimeAssetManifest.coinFace(
        side: 'heads',
        semanticLabel: '正面',
      );
      expect(heads.path, 'assets/runtime/coin_heads.png');
      expect(heads.kind, RuntimeAssetKind.coinFace);

      final edge = RuntimeAssetManifest.coinEdge();
      expect(edge.path, 'assets/runtime/coin_edge.png');
      expect(edge.kind, RuntimeAssetKind.coinEdge);
    },
  );

  testWidgets(
    'reduced motion samples the final state and injected art stays local',
    (tester) async {
      final samples = <double>[];
      final asset = RuntimeAssetManifest.coinFace(
        side: 'tails',
        semanticLabel: '反面',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              AppPhysicsMotion(
                duration: const Duration(seconds: 1),
                animate: false,
                builder: (context, progress, child) {
                  samples.add(progress);
                  return Text(progress.toStringAsFixed(1));
                },
              ),
              RuntimeAssetSlot(
                asset: asset,
                fallback: const Text('fallback'),
                assetBuilder: (context, reference, fallback) =>
                    Text(reference.path),
              ),
            ],
          ),
        ),
      );

      expect(samples.last, 1);
      expect(find.text('1.0'), findsOneWidget);
      expect(find.text('assets/runtime/coin_tails.png'), findsOneWidget);
    },
  );
}
