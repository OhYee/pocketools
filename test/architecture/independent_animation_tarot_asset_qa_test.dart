import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/assets/runtime/runtime_asset_manifest.dart';
import 'package:pocketools/features/tarot/content/tarot_content_catalog.dart';
import 'package:pocketools/features/tarot/domain/tarot_deck.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';

void main() {
  test(
    'physical animation contract keeps a real lift-flip-impact timeline',
    () {
      final coinPrimitive = File(
        'lib/features/coin/presentation/widgets/coin_primitive.dart',
      ).readAsStringSync();
      final tarotPrimitive = File(
        'lib/features/tarot/presentation/widgets/tarot_card_primitive.dart',
      ).readAsStringSync();

      for (final token in <String>[
        'AppPhysicsMotion',
        'AppPhysics.coinLanding',
        'AppPhysics.spin',
        'Transform.translate',
        'rotateX(rotation)',
      ]) {
        expect(coinPrimitive, contains(token), reason: token);
      }
      expect(coinPrimitive, contains('CoinSide side'));
      expect(coinPrimitive, isNot(contains('RandomSource')));
      expect(coinPrimitive, isNot(contains('nextInt(')));

      for (final token in <String>[
        'AppPhysicsMotion',
        'AppPhysics.tarotLanding',
        'Transform.translate',
        'rotateY(angle)',
        'TarotOrientation.reversed',
        'TarotCardBack',
        'RuntimeAssetManifest.tarotFace',
        'RuntimeAssetManifest.tarotBack',
        'AppMotionValues.tarotFlipProgress',
      ]) {
        expect(tarotPrimitive, contains(token), reason: token);
      }
      expect(tarotPrimitive, isNot(contains('RandomSource')));
      expect(tarotPrimitive, isNot(contains('nextInt(')));
    },
  );

  test(
    'all tool pages persist the frozen result before timed presentation',
    () {
      final pageSources = <String, String>{
        'coin': File('lib/features/coin/presentation/coin_tool_page.dart')
            .readAsStringSync(),
        'dice': File('lib/features/dice/presentation/dice_tool_page.dart')
            .readAsStringSync(),
        'tarot': File('lib/features/tarot/presentation/tarot_tool_page.dart')
            .readAsStringSync(),
      };

      for (final entry in pageSources.entries) {
        final source = entry.value;
        final saveIndex = source.indexOf('.save(session)');
        expect(saveIndex, isNot(-1), reason: entry.key);

        final timerIndex =
            <int>[
              source.indexOf('Future<void>.delayed', saveIndex),
              source.indexOf('Timer(', saveIndex),
            ].where((index) => index != -1).fold<int>(-1, (first, index) {
              if (first == -1 || index < first) return index;
              return first;
            });
        expect(timerIndex, greaterThan(saveIndex), reason: entry.key);

        final feedbackIndex = source.indexOf('_emitFeedback', saveIndex);
        if (feedbackIndex != -1) {
          expect(feedbackIndex, greaterThan(saveIndex), reason: entry.key);
        } else {
          final platformFeedbackIndex = source.indexOf(
            'FeedbackIntensity.',
            saveIndex,
          );
          expect(
            platformFeedbackIndex,
            greaterThan(saveIndex),
            reason: entry.key,
          );
        }
      }
    },
  );

  test('tarot deck, card faces, orientations and content are complete', () {
    final deck = TarotDeck.standard;
    expect(TarotDeck.validate(deck), isEmpty);
    expect(deck, hasLength(78));
    expect(deck.map((card) => card.id).toSet(), hasLength(78));
    expect(
      deck.where((card) => card.arcana == TarotArcana.major),
      hasLength(22),
    );
    for (final suit in TarotSuit.values) {
      final suitedCards = deck.where((card) => card.suit == suit).toList();
      expect(suitedCards, hasLength(14), reason: suit.name);
      expect(suitedCards.map((card) => card.rank).toSet(), hasLength(14));
    }

    expect(TarotContentCatalog.validate(), isEmpty);
    expect(TarotContentCatalog.entries, hasLength(78));

    for (final card in deck) {
      final content = TarotContentCatalog.entryFor(card.id);
      expect(content.cardId, card.id);
      expect(content.uprightKeywords, isNotEmpty, reason: card.id);
      expect(content.reversedKeywords, isNotEmpty, reason: card.id);
      expect(content.traditionalSymbols, isNotEmpty, reason: card.id);
      expect(content.uprightMeaning.trim(), isNotEmpty, reason: card.id);
      expect(content.reversedMeaning.trim(), isNotEmpty, reason: card.id);
      expect(content.reflectionQuestions, isNotEmpty, reason: card.id);
    }
  });

  test('missing tarot content is a blocking resource error, never a silent fallback', () {
    final catalogSource = File(
      'lib/features/tarot/content/tarot_content_catalog.dart',
    ).readAsStringSync();
    expect(catalogSource, contains('if (entry == null)'));
    expect(
      () => TarotContentCatalog.entryFor('missing-card-resource'),
      throwsStateError,
    );
    expect(TarotContentCatalog.validate(), isEmpty);
  });

  test('classic tarot runtime assets are shipped', () {
    final back = RuntimeAssetManifest.tarotBack();
    final references = <RuntimeAssetReference>[
      back,
      for (final card in TarotDeck.standard)
        for (final orientation in RuntimeAssetOrientation.values)
          RuntimeAssetManifest.tarotFace(
            cardId: card.id,
            orientation: orientation,
            semanticLabel: '${card.name}${orientation.name}',
          ),
    ];
    final missing = references
        .where((reference) => !File(reference.path).existsSync())
        .map((reference) => reference.path)
        .toList(growable: false);
    expect(
      missing.length,
      0,
      reason: 'runtime tarot resources missing: ${missing.take(5).join(', ')}',
    );
  });

  test('runtime asset directory is registered in the Flutter bundle', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      contains(RegExp(r'^\s*-\s+assets/runtime/', multiLine: true)),
    );
  });

  test('classic tarot asset manifest carries license metadata', () {
    final manifest = File('lib/assets/runtime/runtime_asset_manifest.dart')
        .readAsStringSync();
    for (final requiredMetadata in <String>[
      'author',
      'source',
      'license',
      'licenseStatus',
    ]) {
      expect(manifest, contains(requiredMetadata), reason: requiredMetadata);
    }

    final assetMetadata = File('assets/runtime/tarot/manifest.json');
    expect(assetMetadata.existsSync(), isTrue);
    final metadata = assetMetadata.readAsStringSync();
    for (final requiredMetadata in <String>[
      'schemaVersion',
      'source',
      'artist',
      'cardLicense',
      'attribution',
    ]) {
      expect(metadata, contains(requiredMetadata), reason: requiredMetadata);
    }
  });

  test('runtime manifest covers every shipped physical-art asset', () {
    final manifestFile = File('assets/runtime/asset-manifest.json');
    expect(manifestFile.existsSync(), isTrue);
    final manifest = jsonDecode(manifestFile.readAsStringSync());
    expect(manifest, isA<Map<String, dynamic>>());
    final entries = (manifest as Map<String, dynamic>)['assets'];
    expect(entries, isA<List<dynamic>>());
    expect(entries as List<dynamic>, hasLength(84));

    for (final entry in entries) {
      final asset = entry as Map<String, dynamic>;
      final path = asset['path'] as String;
      expect(path, startsWith('assets/runtime/'));
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(asset['runtimeSha256'], isNotEmpty, reason: path);
      expect(asset['licenseStatus'], isNotEmpty, reason: path);
    }
  });

  test('runtime asset fallback contract remains local and deterministic', () {
    final runtimeAsset = File(
      'lib/design_system/components/app_runtime_asset.dart',
    ).readAsStringSync();
    expect(runtimeAsset, contains('errorBuilder'));
    expect(runtimeAsset, contains('fallback'));

    final manifest = File('lib/assets/runtime/runtime_asset_manifest.dart')
        .readAsStringSync();
    expect(manifest, isNot(contains('http://')));
    expect(manifest, isNot(contains('https://')));
  });
}
