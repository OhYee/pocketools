/// Stable local paths for runtime artwork.
///
/// Artwork is intentionally optional at this layer. Feature widgets can use
/// the references with [RuntimeAssetSlot] and keep their deterministic vector
/// fallback until the corresponding local files are shipped.
enum RuntimeAssetKind {
  coinFace,
  coinEdge,
  d20Face,
  playingCardBack,
  tarotBack,
  tarotFace,
}

enum RuntimeAssetOrientation { upright, reversed }

final class RuntimeAssetReference {
  const RuntimeAssetReference({
    required this.kind,
    required this.path,
    required this.semanticLabel,
    this.orientation,
  });

  final RuntimeAssetKind kind;
  final String path;
  final String semanticLabel;
  final RuntimeAssetOrientation? orientation;
}

abstract final class RuntimeAssetManifest {
  static const version = 'runtime-assets/1.0.0';
  static const root = 'assets/runtime';
  static const author = 'Pamela Colman Smith';
  static const source = 'Rider & Company / Wikimedia Commons';
  static const license = 'Public Domain candidate';
  static const licenseStatus =
      'verify jurisdiction and per-file source before distribution';

  static RuntimeAssetReference coinFace({
    required String side,
    required String semanticLabel,
  }) {
    _requireSegment(side, field: 'coin side');
    if (side != 'heads' && side != 'tails') {
      throw ArgumentError.value(side, 'side', 'must be heads or tails');
    }
    return RuntimeAssetReference(
      kind: RuntimeAssetKind.coinFace,
      path: '$root/coin_$side.png',
      semanticLabel: semanticLabel,
    );
  }

  static RuntimeAssetReference d20Face({
    required int value,
    required String semanticLabel,
  }) {
    if (value < 1 || value > 20) {
      throw ArgumentError.value(value, 'value', 'must be between 1 and 20');
    }
    return RuntimeAssetReference(
      kind: RuntimeAssetKind.d20Face,
      // The die artwork is deliberately unnumbered. The frozen outcome is
      // painted as the face label so every d20 value remains truthful.
      path: '$root/d20_blank.png',
      semanticLabel: semanticLabel,
    );
  }

  static RuntimeAssetReference coinEdge({String semanticLabel = '硬币边缘'}) =>
      RuntimeAssetReference(
        kind: RuntimeAssetKind.coinEdge,
        path: '$root/coin_edge.png',
        semanticLabel: semanticLabel,
      );

  static RuntimeAssetReference playingCardBack({
    String semanticLabel = '扑克牌牌背',
  }) => RuntimeAssetReference(
    kind: RuntimeAssetKind.playingCardBack,
    path: '$root/playing_card_back.png',
    semanticLabel: semanticLabel,
  );

  static RuntimeAssetReference tarotBack({String semanticLabel = '塔罗牌背'}) =>
      RuntimeAssetReference(
        kind: RuntimeAssetKind.tarotBack,
        path: '$root/tarot_back.png',
        semanticLabel: semanticLabel,
      );

  static RuntimeAssetReference tarotFace({
    required String cardId,
    required RuntimeAssetOrientation orientation,
    required String semanticLabel,
  }) {
    _requireSegment(cardId, field: 'tarot card id');
    return RuntimeAssetReference(
      kind: RuntimeAssetKind.tarotFace,
      path: '$root/tarot/rider_waite/${_tarotFileName(cardId)}',
      semanticLabel: semanticLabel,
      orientation: orientation,
    );
  }

  static String _tarotFileName(String cardId) {
    final major = RegExp(r'^major-(\d{2})-').firstMatch(cardId);
    if (major != null) {
      final index = int.parse(major.group(1)!);
      if (index < _majorFiles.length) return _majorFiles[index];
    }

    final minor = RegExp(r'^minor-(wands|cups|swords|pentacles)-(.+)$')
        .firstMatch(cardId);
    if (minor != null) {
      final suitPrefix = switch (minor.group(1)) {
        'wands' => 'Wands',
        'cups' => 'Cups',
        'swords' => 'Swords',
        'pentacles' => 'Pents',
        _ => null,
      };
      final rankNumber = _rankNumbers[minor.group(2)];
      if (suitPrefix != null && rankNumber != null) {
        return '$suitPrefix${rankNumber.toString().padLeft(2, '0')}.jpg';
      }
    }

    // Unknown IDs remain deterministic and resolve to the fallback renderer.
    return '$cardId.jpg';
  }

  static const _rankNumbers = <String, int>{
    'ace': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'page': 11,
    'knight': 12,
    'queen': 13,
    'king': 14,
  };

  static const _majorFiles = <String>[
    '00_Fool.jpg',
    '01_Magician.jpg',
    '02_High_Priestess.jpg',
    '03_Empress.jpg',
    '04_Emperor.jpg',
    '05_Hierophant.jpg',
    '06_Lovers.jpg',
    '07_Chariot.jpg',
    '08_Strength.jpg',
    '09_Hermit.jpg',
    '10_Wheel_of_Fortune.jpg',
    '11_Justice.jpg',
    '12_Hanged_Man.jpg',
    '13_Death.jpg',
    '14_Temperance.jpg',
    '15_Devil.jpg',
    '16_Tower.jpg',
    '17_Star.jpg',
    '18_Moon.jpg',
    '19_Sun.jpg',
    '20_Judgement.jpg',
    '21_World.jpg',
  ];

  static void _requireSegment(String value, {required String field}) {
    if (value.isEmpty || value == '.' || value == '..' || value.contains('/')) {
      throw ArgumentError.value(value, field, 'must be one local path segment');
    }
  }
}
