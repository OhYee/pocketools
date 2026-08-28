import 'dart:collection';

import '../../../features/liuyao/domain/liuyao_hexagrams.dart';
import '../../../features/liuyao/domain/liuyao_models.dart';
import '../../../features/tarot/domain/tarot_deck.dart';
import '../../../features/tarot/domain/tarot_models.dart';
import 'multi_divination_rules.dart';

enum MultiDivinationMode { standard }

/// Compatibility name for callers that describe the setting as an
/// interpretation mode.
typedef MultiDivinationInterpretationMode = MultiDivinationMode;

enum MultiDivinationCardSlot { a, b, c }

extension MultiDivinationCardSlotLabels on MultiDivinationCardSlot {
  String get code => switch (this) {
    MultiDivinationCardSlot.a => 'A',
    MultiDivinationCardSlot.b => 'B',
    MultiDivinationCardSlot.c => 'C',
  };

  static MultiDivinationCardSlot fromCode(String code) {
    for (final slot in MultiDivinationCardSlot.values) {
      if (slot.code == code) return slot;
    }
    throw ArgumentError.value(code, 'code', 'Unknown multi-divination slot.');
  }
}

final class MultiDivinationConfig {
  const MultiDivinationConfig({
    this.mode = MultiDivinationMode.standard,
    this.intention,
  });

  static const maximumIntentionLength = 500;
  static final RegExp _unsupportedControlCharacters = RegExp(
    r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]',
  );

  final MultiDivinationMode mode;
  final String? intention;

  MultiDivinationMode get interpretationMode => mode;

  String? get normalizedIntention {
    final value = intention?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  MultiDivinationConfig normalized({bool includeIntention = true}) =>
      MultiDivinationConfig(
        mode: mode,
        intention: includeIntention ? normalizedIntention : null,
      );

  List<String> validate() {
    final errors = <String>[];
    final value = normalizedIntention;
    if (value != null) {
      if (value.length > maximumIntentionLength) {
        errors.add('问题或备注不能超过 $maximumIntentionLength 个字符。');
      }
      if (_unsupportedControlCharacters.hasMatch(value)) {
        errors.add('问题或备注包含不支持的控制字符。');
      }
    }
    return List<String>.unmodifiable(errors);
  }
}

/// One physical three-card group. A/B/C are retained as named random inputs;
/// no card carries coin-side data.
final class MultiDivinationCard {
  const MultiDivinationCard({
    required this.slot,
    required this.card,
    required this.orientation,
  });

  final MultiDivinationCardSlot slot;
  final TarotCard card;
  final TarotOrientation orientation;

  bool get isUpright => orientation == TarotOrientation.upright;

  int get orientationBit => MultiDivinationRules.orientationBit(orientation);
}

final class MultiDivinationGroup {
  MultiDivinationGroup({
    required this.index,
    required Iterable<MultiDivinationCard> cards,
  }) : cards = UnmodifiableListView<MultiDivinationCard>(
         List<MultiDivinationCard>.of(cards),
       ) {
    if (index < 0 || index >= MultiDivinationReading.groupCapacity) {
      throw RangeError.range(
        index,
        0,
        MultiDivinationReading.groupCapacity - 1,
        'index',
      );
    }
    if (this.cards.length != MultiDivinationRules.cardsPerGroup) {
      throw ArgumentError(
        'A multi-divination group must contain exactly three cards.',
      );
    }
    for (var cardIndex = 0; cardIndex < this.cards.length; cardIndex++) {
      final card = this.cards[cardIndex];
      final expectedSlot = MultiDivinationCardSlot.values[cardIndex];
      if (card.slot != expectedSlot) {
        throw ArgumentError('Multi-divination cards must be ordered A, B, C.');
      }
      if (TarotDeck.byId[card.card.id] == null) {
        throw ArgumentError('Unknown tarot card: ${card.card.id}.');
      }
    }
    if (this.cards.map((card) => card.card.id).toSet().length !=
        this.cards.length) {
      throw ArgumentError(
        'Cards in one multi-divination group must be unique.',
      );
    }
  }

  final int index;
  final List<MultiDivinationCard> cards;

  int get lineNumber => index + 1;

  MultiDivinationCard get primaryCard => cardFor(MultiDivinationCardSlot.a);

  MultiDivinationCard cardFor(MultiDivinationCardSlot slot) =>
      cards.firstWhere((card) => card.slot == slot);

  int get uprightCount =>
      MultiDivinationRules.uprightCount(cards.map((card) => card.orientation));

  LiuyaoLineKind get lineKind =>
      MultiDivinationRules.lineKindForUprightCount(uprightCount);

  int get lineValue => lineKind.value;

  bool get isMoving => lineKind.moving;

  List<int> get orientationBits =>
      List<int>.unmodifiable(cards.map((card) => card.orientationBit));
}

final class MultiDivinationReading {
  MultiDivinationReading({
    required MultiDivinationConfig config,
    Iterable<MultiDivinationGroup> groups = const <MultiDivinationGroup>[],
    Iterable<String>? deckOrder,
  }) : config = config.normalized(),
       groups = UnmodifiableListView<MultiDivinationGroup>(
         List<MultiDivinationGroup>.of(groups),
       ),
       deckOrder = deckOrder == null
           ? null
           : UnmodifiableListView<String>(List<String>.of(deckOrder)) {
    final order = this.deckOrder;
    if (order != null) {
      if (order.length != TarotDeck.standard.length) {
        throw ArgumentError(
          'A multi-divination deck order must contain all 78 tarot cards.',
        );
      }
      final ids = order.toSet();
      final standardIds = TarotDeck.standard.map((card) => card.id).toSet();
      if (ids.length != order.length ||
          ids.length != standardIds.length ||
          !ids.containsAll(standardIds)) {
        throw ArgumentError(
          'A multi-divination deck order must be a permutation of the '
          'standard tarot deck.',
        );
      }
    }

    final errors = this.config.validate();
    if (errors.isNotEmpty) throw ArgumentError(errors.join(' '));
    if (this.groups.length > groupCapacity) {
      throw ArgumentError(
        'A multi-divination reading can contain at most six groups.',
      );
    }
    final cardIds = <String>{};
    for (var groupIndex = 0; groupIndex < this.groups.length; groupIndex++) {
      final group = this.groups[groupIndex];
      if (group.index != groupIndex) {
        throw ArgumentError('Group indexes must be contiguous from zero.');
      }
      for (final card in group.cards) {
        if (!cardIds.add(card.card.id)) {
          throw ArgumentError(
            'A tarot card cannot be reused in one multi-divination reading: '
            '${card.card.id}.',
          );
        }
      }
    }
  }

  static const int groupCapacity = 6;
  static const int cardsPerGroup = MultiDivinationRules.cardsPerGroup;
  static const String ruleVersion = 'multi-divination/1.0.0';
  static const String algorithmVersion =
      'tarot-fisher-yates-once-orientation-bit/1.0.0';

  final MultiDivinationConfig config;
  final List<MultiDivinationGroup> groups;
  final List<String>? deckOrder;

  bool get isComplete => groups.length == groupCapacity;

  int get nextGroupIndex => groups.length;

  List<int> get lineValues =>
      List<int>.unmodifiable(groups.map((group) => group.lineValue));

  List<int> get movingLineIndexes => List<int>.unmodifiable(
    groups.where((group) => group.isMoving).map((group) => group.index),
  );

  /// The only Liuyao adapter is a line-value adapter with manualValue source;
  /// the originating A/B/C cards and orientations remain in [groups].
  List<LiuyaoLine> get liuyaoLines => List<LiuyaoLine>.unmodifiable(
    groups.map(
      (group) => LiuyaoLine(
        index: group.index,
        value: group.lineValue,
        source: LiuyaoLineSource.manualValue,
      ),
    ),
  );

  LiuyaoHexagram? get primaryHexagram =>
      isComplete ? LiuyaoHexagrams.resolve(liuyaoLines) : null;

  LiuyaoHexagram? get changedHexagram {
    if (!isComplete || movingLineIndexes.isEmpty) return null;
    return LiuyaoHexagrams.resolve(liuyaoLines, changed: true);
  }

  MultiDivinationReading append(MultiDivinationGroup group) {
    if (isComplete) {
      throw StateError('A completed multi-divination reading is immutable.');
    }
    if (group.index != nextGroupIndex) {
      throw ArgumentError('The next group index must be $nextGroupIndex.');
    }
    final usedCardIds = groups
        .expand((existing) => existing.cards)
        .map((card) => card.card.id)
        .toSet();
    if (group.cards.any((card) => usedCardIds.contains(card.card.id))) {
      throw ArgumentError(
        'A tarot card cannot be reused in one multi-divination reading.',
      );
    }
    return MultiDivinationReading(
      config: config,
      groups: <MultiDivinationGroup>[...groups, group],
      deckOrder: deckOrder,
    );
  }

  /// Attaches the single shuffled order used by an interactive draft.
  ///
  /// Manually assembled readings may omit this value, but generated readings
  /// keep it so restoring a partial session never triggers a second shuffle.
  MultiDivinationReading withDeckOrder(Iterable<String> order) {
    if (deckOrder != null) {
      if (!_sameSequence(deckOrder!, order)) {
        throw ArgumentError('A reading cannot replace its deck order.');
      }
      return this;
    }
    return MultiDivinationReading(
      config: config,
      groups: groups,
      deckOrder: order,
    );
  }

  MultiDivinationReading undoLastGroup() {
    if (isComplete) {
      throw StateError(
        'A completed multi-divination reading cannot be edited.',
      );
    }
    if (groups.isEmpty) {
      throw StateError('There is no group to undo.');
    }
    return MultiDivinationReading(
      config: config,
      groups: groups.sublist(0, groups.length - 1),
      deckOrder: deckOrder,
    );
  }

  static bool _sameSequence(Iterable<String> first, Iterable<String> second) {
    final left = List<String>.of(first);
    final right = List<String>.of(second);
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
