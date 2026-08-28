import 'preset.dart';

/// Optional capability for a tool that contributes reusable rule presets.
///
/// The app registry aggregates this interface. A new provider adds its own
/// typed codec and definitions without changing the preset management page.
abstract interface class ToolPresetProvider {
  String get toolId;

  List<ToolPreset> get systemPresets;

  /// Converts a persisted rule map into the tool's existing input model.
  Object decodePresetConfiguration(Map<String, Object?> configuration);

  /// Converts the tool's existing input model into a private-free rule map.
  Map<String, Object?> encodePresetConfiguration(Object configuration);
}

final class PresetConfigurationException implements Exception {
  const PresetConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'PresetConfigurationException: $message';
}
