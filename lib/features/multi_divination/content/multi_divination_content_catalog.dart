import '../domain/multi_divination_models.dart';

/// Content catalog for the multi-divination combination layer.
abstract final class MultiDivinationContentCatalog {
  static const contentVersion = '1.0.0';

  static const List<MultiDivinationCardSlot> interpretedSlots =
      <MultiDivinationCardSlot>[MultiDivinationCardSlot.a];

  static List<String> validate() {
    final errors = <String>[];
    if (interpretedSlots.length != 1 ||
        interpretedSlots.single != MultiDivinationCardSlot.a) {
      errors.add(
        'Standard multi-divination content must interpret slot A only.',
      );
    }
    return List<String>.unmodifiable(errors);
  }
}
