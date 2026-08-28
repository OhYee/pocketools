import '../session/session.dart';

/// The two preset kinds are intentionally distinct at the type level.
enum PresetType { system, user }

/// Storage provenance for a preset.
enum PresetSource { bundled, local }

/// Immutable, tool-neutral metadata and structured rule configuration.
///
/// The configuration map contains only rule fields. Tool providers are
/// responsible for encoding and decoding those fields; private prompts,
/// notes, results, and session identifiers must never be placed in it.
final class ToolPreset {
  ToolPreset({
    required this.id,
    required this.toolId,
    required this.displayName,
    required this.ruleVersion,
    required this.type,
    required this.source,
    required Map<String, Object?> configuration,
    this.schemaVersion = currentSchemaVersion,
  }) : configuration = deepFreezeMap(configuration);

  static const int currentSchemaVersion = 1;
  static const int maximumIdLength = 128;
  static const int maximumToolIdLength = 64;
  static const int maximumDisplayNameLength = 80;
  static const int maximumRuleVersionLength = 128;

  static final RegExp _controlCharacters = RegExp(
    r'[\u0000-\u001f\u007f-\u009f]',
  );

  final String id;
  final String toolId;
  final String displayName;
  final String ruleVersion;
  final PresetType type;
  final PresetSource source;
  final int schemaVersion;
  final Map<String, Object?> configuration;

  /// Returns validation errors without mutating this preset.
  List<String> validate() {
    final errors = <String>[];
    _validateText(id, maximumIdLength, '预设 ID', errors);
    _validateText(toolId, maximumToolIdLength, '工具 ID', errors);
    _validateText(displayName, maximumDisplayNameLength, '预设名称', errors);
    _validateText(ruleVersion, maximumRuleVersionLength, '规则版本', errors);
    if (schemaVersion != currentSchemaVersion) {
      errors.add('预设 schema 版本不受支持。');
    }
    if (type == PresetType.system && source != PresetSource.bundled) {
      errors.add('系统预设必须来自内置来源。');
    }
    if (type == PresetType.user && source != PresetSource.local) {
      errors.add('用户预设必须来自本地来源。');
    }
    if (configuration.isEmpty) errors.add('预设规则配置不能为空。');
    return List<String>.unmodifiable(errors);
  }

  /// Creates an independent local copy with a new stable identity.
  ToolPreset asUserCopy({required String newId, required String newName}) {
    return ToolPreset(
      id: newId,
      toolId: toolId,
      displayName: newName,
      ruleVersion: ruleVersion,
      type: PresetType.user,
      source: PresetSource.local,
      schemaVersion: schemaVersion,
      configuration: configuration,
    );
  }

  ToolPreset renamed(String newName) => ToolPreset(
    id: id,
    toolId: toolId,
    displayName: newName,
    ruleVersion: ruleVersion,
    type: type,
    source: source,
    schemaVersion: schemaVersion,
    configuration: configuration,
  );

  static String? validateDisplayName(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return '预设名称不能为空。';
    if (normalized.runes.length > maximumDisplayNameLength) {
      return '预设名称不能超过 $maximumDisplayNameLength 个字符。';
    }
    if (_controlCharacters.hasMatch(normalized)) {
      return '预设名称包含不支持的控制字符。';
    }
    return null;
  }

  void _validateText(
    String value,
    int maximumLength,
    String label,
    List<String> errors,
  ) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      errors.add('$label不能为空。');
      return;
    }
    if (value.runes.length > maximumLength) {
      errors.add('$label过长。');
    }
    if (_controlCharacters.hasMatch(value)) {
      errors.add('$label包含不支持的控制字符。');
    }
  }
}
