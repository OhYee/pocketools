import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/assets/runtime/runtime_asset_manifest.dart';

void main() {
  test('playing card back is a shipped physical runtime asset', () {
    final asset = RuntimeAssetManifest.playingCardBack();

    expect(asset.kind, RuntimeAssetKind.playingCardBack);
    expect(asset.path, 'assets/runtime/playing_card_back.png');
    expect(File(asset.path).existsSync(), isTrue);
  });

  test(
    'playing card faces keep physical paper and ink contrast in dark mode',
    () {
      final source = File(
        'lib/features/cards/presentation/widgets/playing_card_view.dart',
      ).readAsStringSync();

      expect(source, contains('AppPhysicalColors.cardPaper'));
      expect(source, contains('AppPhysicalColors.cardInk'));
      expect(source, contains('RuntimeAssetManifest.playingCardBack'));
    },
  );
}
