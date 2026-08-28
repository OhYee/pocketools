import 'package:flutter/foundation.dart';

import '../tools/tool_capabilities.dart';
import '../tools/tool_registry.dart';
import 'preset.dart';
import 'preset_configuration_policy.dart';
import 'preset_id_source.dart';
import 'preset_repository.dart';

typedef PresetWarningSink = void Function(String message);

/// Coordinates built-in definitions with immutable local user copies.
final class PresetController extends ChangeNotifier {
  factory PresetController({
    required ToolRegistry registry,
    required PresetRepository repository,
    required PresetIdSource idSource,
    PresetWarningSink? onWarning,
  }) => PresetController._(registry, repository, idSource, onWarning);

  PresetController._(
    this.registry,
    this._repository,
    this._idSource,
    this._onWarning,
  );

  final ToolRegistry registry;
  final PresetRepository _repository;
  final PresetIdSource _idSource;
  final PresetWarningSink? _onWarning;
  final List<ToolPreset> _userPresets = <ToolPreset>[];
  final List<ToolPreset> _isolatedPresets = <ToolPreset>[];
  var _loaded = false;
  var _loading = false;

  bool get isLoaded => _loaded;
  bool get isLoading => _loading;

  List<ToolPreset> get systemPresets => registry.systemPresets;

  List<ToolPreset> get userPresets =>
      List<ToolPreset>.unmodifiable(_userPresets);

  List<ToolPreset> get presets => List<ToolPreset>.unmodifiable(<ToolPreset>[
    ...systemPresets,
    ..._userPresets,
  ]);

  Future<void> load() async {
    if (_loaded || _loading) return;
    _loading = true;
    try {
      final result = await _repository.load();
      final systemPresetIds = systemPresets.map((preset) => preset.id).toSet();
      final validPresets = <ToolPreset>[];
      final isolatedPresets = <ToolPreset>[];
      for (final preset in result.presets) {
        if (_isValidUserPreset(preset, systemPresetIds)) {
          validPresets.add(preset);
        } else {
          isolatedPresets.add(preset);
        }
      }
      _userPresets
        ..clear()
        ..addAll(validPresets);
      _isolatedPresets
        ..clear()
        ..addAll(isolatedPresets);
      if (result.issue != null || isolatedPresets.isNotEmpty) {
        _onWarning?.call('部分本地预设无法读取，已隔离损坏或不兼容记录。');
      }
    } on Object {
      _userPresets.clear();
      _isolatedPresets.clear();
      _onWarning?.call('本地预设暂时无法读取；系统预设仍可使用，本次修改保留在当前会话。');
    } finally {
      _loaded = true;
      _loading = false;
      notifyListeners();
    }
  }

  /// Creates a new local record; the source record is never mutated.
  Future<ToolPreset> copyAsUser(
    ToolPreset source, {
    required String displayName,
  }) async {
    await load();
    _requireSource(source);
    final normalizedName = _normalizeName(displayName);
    final id = _newId();
    final copy = source.asUserCopy(newId: id, newName: normalizedName);
    await _save(<ToolPreset>[..._userPresets, copy]);
    return copy;
  }

  Future<ToolPreset> renameUser(
    String id, {
    required String displayName,
  }) async {
    await load();
    final index = _userPresets.indexWhere((preset) => preset.id == id);
    if (index < 0) {
      throw ArgumentError('Only an existing user preset can be renamed.');
    }
    final renamed = _userPresets[index].renamed(_normalizeName(displayName));
    final candidate = List<ToolPreset>.of(_userPresets)..[index] = renamed;
    await _save(candidate);
    return renamed;
  }

  Future<void> deleteUser(String id) async {
    await load();
    final index = _userPresets.indexWhere((preset) => preset.id == id);
    if (index < 0) {
      throw ArgumentError('Only an existing user preset can be deleted.');
    }
    final candidate = List<ToolPreset>.of(_userPresets)..removeAt(index);
    await _save(candidate);
  }

  ToolLaunchRequest launchRequestFor(ToolPreset preset) =>
      registry.launchRequestForPreset(preset);

  String _normalizeName(String value) {
    final normalized = value.trim();
    final error = ToolPreset.validateDisplayName(normalized);
    if (error != null) throw ArgumentError.value(value, 'displayName', error);
    return normalized;
  }

  String _newId() {
    final existing = <String>{
      ...systemPresets.map((preset) => preset.id),
      ..._userPresets.map((preset) => preset.id),
      ..._isolatedPresets.map((preset) => preset.id),
    };
    final id = _idSource.next();
    if (id.trim().isEmpty || existing.contains(id)) {
      throw ArgumentError('Preset ID source returned a duplicate or empty ID.');
    }
    return id;
  }

  void _requireSource(ToolPreset source) {
    if (source.validate().isNotEmpty) {
      throw ArgumentError('The source preset is invalid.');
    }
    if (registry.presetProviderFor(source.toolId) == null) {
      throw ArgumentError.value(
        source.toolId,
        'toolId',
        'Tool has no preset provider.',
      );
    }
    try {
      final configuration = ToolPresetConfigurationPolicy.validateAndCopy(
        source.configuration,
      );
      registry
          .presetProviderFor(source.toolId)!
          .decodePresetConfiguration(configuration);
    } on Object catch (error) {
      throw ArgumentError.value(
        source.id,
        'source',
        'Source preset configuration cannot be decoded: $error',
      );
    }
  }

  bool _isValidUserPreset(ToolPreset preset, Set<String> systemPresetIds) {
    if (preset.type != PresetType.user ||
        preset.source != PresetSource.local ||
        preset.validate().isNotEmpty ||
        systemPresetIds.contains(preset.id)) {
      return false;
    }
    final provider = registry.presetProviderFor(preset.toolId);
    if (provider == null) return false;
    try {
      final configuration = ToolPresetConfigurationPolicy.validateAndCopy(
        preset.configuration,
      );
      provider.decodePresetConfiguration(configuration);
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _save(List<ToolPreset> candidate) async {
    await _repository.saveAll(<ToolPreset>[...candidate, ..._isolatedPresets]);
    _userPresets
      ..clear()
      ..addAll(candidate);
    notifyListeners();
  }
}
