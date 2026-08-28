import '../../../features/liuyao/domain/liuyao_models.dart';
import '../../../features/tarot/domain/tarot_models.dart';

/// Pure rules for converting the orientation of three tarot cards into one
/// Liuyao line. The cards remain cards; this class only exposes the explicit
/// binary and line-value mapping used by the multi-divination method.
abstract final class MultiDivinationRules {
  static const int cardsPerGroup = 3;

  static int orientationBit(TarotOrientation orientation) =>
      orientation == TarotOrientation.upright ? 1 : 0;

  static int uprightCount(Iterable<TarotOrientation> orientations) {
    final values = List<TarotOrientation>.of(orientations);
    if (values.length != cardsPerGroup) {
      throw ArgumentError(
        'A multi-divination group must contain exactly three orientations.',
      );
    }
    return values.fold<int>(
      0,
      (count, orientation) => count + orientationBit(orientation),
    );
  }

  static LiuyaoLineKind lineKindForUprightCount(int count) => switch (count) {
    0 => LiuyaoLineKind.oldYin,
    1 => LiuyaoLineKind.youngYang,
    2 => LiuyaoLineKind.youngYin,
    3 => LiuyaoLineKind.oldYang,
    _ => throw RangeError.range(count, 0, cardsPerGroup, 'uprightCount'),
  };

  static int lineValueForUprightCount(int count) =>
      lineKindForUprightCount(count).value;

  static LiuyaoLineKind lineKindForOrientations(
    Iterable<TarotOrientation> orientations,
  ) => lineKindForUprightCount(uprightCount(orientations));

  static int lineValueForOrientations(
    Iterable<TarotOrientation> orientations,
  ) => lineKindForOrientations(orientations).value;
}
