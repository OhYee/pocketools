import 'dart:collection';

import '../../liuyao/domain/liuyao_hexagrams.dart';
import '../../liuyao/domain/liuyao_models.dart';
import '../../tarot/content/tarot_content_catalog.dart';
import '../../tarot/content/tarot_content_models.dart';
import '../../tarot/domain/tarot_models.dart';
import '../domain/multi_divination_models.dart';
import 'multi_divination_content_catalog.dart';

final class MultiDivinationCardInterpretation {
  const MultiDivinationCardInterpretation({
    required this.slot,
    required this.interpretation,
  });

  final MultiDivinationCardSlot slot;
  final TarotCardInterpretation interpretation;

  TarotCardInterpretation get tarot => interpretation;
}

final class MultiDivinationGroupInterpretation {
  MultiDivinationGroupInterpretation({
    required this.group,
    required Iterable<MultiDivinationCardInterpretation> interpretations,
  }) : interpretations =
           UnmodifiableListView<MultiDivinationCardInterpretation>(
             List<MultiDivinationCardInterpretation>.of(interpretations),
           ) {
    if (this.interpretations.isEmpty) {
      throw ArgumentError(
        'A multi-divination group must have an interpretation.',
      );
    }
    if (this.interpretations.any(
      (item) => item.slot != MultiDivinationCardSlot.a,
    )) {
      throw ArgumentError('Standard mode only interprets the A card.');
    }
  }

  final MultiDivinationGroup group;
  final List<MultiDivinationCardInterpretation> interpretations;

  MultiDivinationCardInterpretation get primaryInterpretation =>
      interpretations.single;

  TarotCardInterpretation get primary => primaryInterpretation.interpretation;

  LiuyaoLineKind get lineKind => group.lineKind;

  int get lineValue => group.lineValue;
}

final class MultiDivinationReadingInterpretation {
  MultiDivinationReadingInterpretation({
    required this.reading,
    required Iterable<MultiDivinationGroupInterpretation> groups,
    required this.primaryHexagram,
    required this.changedHexagram,
    required Iterable<int> movingLineIndexes,
    required this.combinationHint,
  }) : groups = UnmodifiableListView<MultiDivinationGroupInterpretation>(
         List<MultiDivinationGroupInterpretation>.of(groups),
       ),
       movingLineIndexes = UnmodifiableListView<int>(
         List<int>.of(movingLineIndexes),
       ) {
    if (this.groups.length != reading.groups.length) {
      throw ArgumentError(
        'Interpretation groups must match the reading groups.',
      );
    }
  }

  final MultiDivinationReading reading;
  final List<MultiDivinationGroupInterpretation> groups;
  final LiuyaoHexagram? primaryHexagram;
  final LiuyaoHexagram? changedHexagram;
  final List<int> movingLineIndexes;
  final String combinationHint;

  List<MultiDivinationCardSlot> get interpretedSlots =>
      MultiDivinationContentCatalog.interpretedSlots;

  List<TarotCardInterpretation> get primaryInterpretations =>
      List<TarotCardInterpretation>.unmodifiable(
        groups.map((group) => group.primary),
      );

  bool get isComplete => reading.isComplete;
}

/// Combines the existing Tarot interpretation data with the structural
/// Liuyao result. Standard mode deliberately resolves only each group's A
/// card for the structural summary; individual A/B/C cards can still be
/// resolved for their own Tarot meaning.
final class MultiDivinationInterpretationComposer {
  const MultiDivinationInterpretationComposer();

  MultiDivinationReadingInterpretation resolve(MultiDivinationReading reading) {
    final groups = reading.groups
        .map((group) {
          final primary = MultiDivinationCardInterpretation(
            slot: MultiDivinationCardSlot.a,
            interpretation: _resolveCard(group.primaryCard),
          );
          return MultiDivinationGroupInterpretation(
            group: group,
            interpretations: <MultiDivinationCardInterpretation>[primary],
          );
        })
        .toList(growable: false);
    return MultiDivinationReadingInterpretation(
      reading: reading,
      groups: groups,
      primaryHexagram: reading.primaryHexagram,
      changedHexagram: reading.changedHexagram,
      movingLineIndexes: reading.movingLineIndexes,
      combinationHint: _combinationHint(reading, groups),
    );
  }

  TarotCardInterpretation resolveCard(MultiDivinationCard card) =>
      _resolveCard(card);

  TarotCardInterpretation _resolveCard(MultiDivinationCard card) =>
      const TarotInterpretationComposer().resolve(
        TarotDrawnCard(
          card: card.card,
          position: TarotPosition.coreMessage,
          orientation: card.orientation,
        ),
      );

  String _combinationHint(
    MultiDivinationReading reading,
    List<MultiDivinationGroupInterpretation> groups,
  ) {
    if (groups.isEmpty) return '尚未抽取主解释牌；完成六组后再观察整体结构。';
    final themes = groups
        .map((group) => group.primary.keywords.first)
        .join('、');
    final structure = reading.isComplete
        ? '本卦为${reading.primaryHexagram!.name}'
        : '当前已完成 ${reading.groups.length}/6 组';
    final moving = reading.movingLineIndexes.isEmpty
        ? '目前没有动爻'
        : '动爻位于${reading.movingLineIndexes.map((index) => index + 1).join('、')}';
    return 'A1-A6 依次呈现“$themes”；$structure，$moving。';
  }
}

/// Short alias for callers that use “explanation” terminology.
typedef MultiDivinationExplanation = MultiDivinationReadingInterpretation;
