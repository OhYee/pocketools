import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../session/local_string_store.dart';
import 'preset.dart';
import 'preset_capabilities.dart';
import 'preset_configuration_policy.dart';

enum PresetLoadIssueCode {
  corruptJson,
  invalidShape,
  unknownVersion,
  invalidDocument,
  duplicateId,
  pendingSnapshotIgnored,
}

final class PresetLoadIssue {
  const PresetLoadIssue({required this.code, required this.message});

  final PresetLoadIssueCode code;
  final String message;
}

final class PresetLoadResult {
  const PresetLoadResult({required this.presets, this.issue});

  final List<ToolPreset> presets;
  final PresetLoadIssue? issue;
}

final class PresetStorageException implements Exception {
  const PresetStorageException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'PresetStorageException($code): $message';
}

/// User-preset storage boundary. System definitions are supplied by modules,
/// never written into this repository.
abstract interface class PresetRepository {
  Future<PresetLoadResult> load();

  Future<void> saveAll(Iterable<ToolPreset> presets);
}

/// In-memory implementation used by tests and the storage fallback path.
final class InMemoryPresetRepository implements PresetRepository {
  InMemoryPresetRepository([Iterable<ToolPreset> initialPresets = const []])
    : _presets = List<ToolPreset>.of(initialPresets),
      _quarantined = _unsafePresets(initialPresets);

  final List<ToolPreset> _presets;
  final List<ToolPreset> _quarantined;

  List<ToolPreset> get values => List<ToolPreset>.unmodifiable(_presets);

  @override
  Future<PresetLoadResult> load() async =>
      PresetLoadResult(presets: List<ToolPreset>.unmodifiable(_presets));

  @override
  Future<void> saveAll(Iterable<ToolPreset> presets) async {
    final candidate = _validatedUserPresets(presets, preserved: _quarantined);
    _presets
      ..clear()
      ..addAll(candidate);
  }
}

/// Versioned, atomic local snapshot for user presets.
final class PersistentPresetRepository implements PresetRepository {
  PersistentPresetRepository({required LocalStringStore store})
    : _store = AllowlistedLocalStringStore(
        delegate: store,
        allowedKeys: ownedKeys,
      );

  static const int currentStorageSchemaVersion = 1;
  static const int maximumEntries = 100;
  static const int maximumSnapshotBytes = 256 * 1024;
  static const String activeStorageKey =
      'pocketools.presets.snapshot.active.v1';
  static const String pendingStorageKey =
      'pocketools.presets.snapshot.pending.v1';
  static const String quarantineStorageKey =
      'pocketools.presets.snapshot.quarantine.v1';
  static const Set<String> ownedKeys = <String>{
    activeStorageKey,
    pendingStorageKey,
    quarantineStorageKey,
  };

  final LocalStringStore _store;
  final _PresetSnapshotJsonCodec _codec = const _PresetSnapshotJsonCodec();
  final List<ToolPreset> _presets = <ToolPreset>[];
  final List<ToolPreset> _quarantined = <ToolPreset>[];
  String? _quarantineRawText;
  String? _storedQuarantineRawText;
  Future<void> _operationTail = Future<void>.value();
  bool _loaded = false;
  PresetLoadIssue? _issue;

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _operationTail = _operationTail.then((_) async {
      try {
        completer.complete(await operation());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  @override
  Future<PresetLoadResult> load() => _serialized(() async {
    await _ensureLoaded();
    return PresetLoadResult(
      presets: List<ToolPreset>.unmodifiable(_presets),
      issue: _issue,
    );
  });

  @override
  Future<void> saveAll(Iterable<ToolPreset> presets) => _serialized(() async {
    await _ensureLoaded();
    final candidate = _validatedUserPresets(presets, preserved: _quarantined);
    final encoded = _codec.encode(candidate);
    try {
      if (_quarantineRawText != null &&
          _quarantineRawText != _storedQuarantineRawText) {
        await _store.writeString(quarantineStorageKey, _quarantineRawText!);
      }
      await _store.writeString(pendingStorageKey, encoded);
      await _store.writeString(activeStorageKey, encoded);
    } on Object {
      throw const PresetStorageException(
        'write_failed',
        'The local preset snapshot could not be saved.',
      );
    }
    _storedQuarantineRawText = _quarantineRawText;
    _presets
      ..clear()
      ..addAll(candidate);
    _issue = null;
    try {
      await _store.clearOwned(const <String>{pendingStorageKey});
    } on Object {
      // The active snapshot is authoritative; a pending value is ignored on
      // the next load and surfaced as a diagnostic.
    }
  });

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    String? activeText;
    String? pendingText;
    String? quarantineText;
    try {
      activeText = await _store.readString(activeStorageKey);
      pendingText = await _store.readString(pendingStorageKey);
      quarantineText = await _store.readString(quarantineStorageKey);
    } on Object {
      throw const PresetStorageException(
        'read_failed',
        'The local preset snapshot could not be read.',
      );
    }
    _storedQuarantineRawText = quarantineText;
    _quarantineRawText = quarantineText;
    if (activeText != null) {
      final result = _codec.decode(activeText);
      _presets
        ..clear()
        ..addAll(result.presets);
      _quarantined
        ..clear()
        ..addAll(_unsafePresets(result.presets));
      _issue = result.issue;
      if (result.issue != null) _quarantineRawText = activeText;
    }
    if (pendingText != null) {
      _issue = const PresetLoadIssue(
        code: PresetLoadIssueCode.pendingSnapshotIgnored,
        message:
            'An incomplete preset write was ignored; active presets were used.',
      );
    }
    _loaded = true;
  }
}

/// Keeps preset management available when local storage is unavailable.
final class ResilientPresetRepository implements PresetRepository {
  factory ResilientPresetRepository({
    required PresetRepository persistentRepository,
    required void Function(String message) onWarning,
    PresetRepository? transientRepository,
  }) => ResilientPresetRepository._(
    persistentRepository,
    transientRepository ?? InMemoryPresetRepository(),
    onWarning,
  );

  ResilientPresetRepository._(
    this._persistentRepository,
    this._transientRepository,
    this._onWarning,
  );

  final PresetRepository _persistentRepository;
  final PresetRepository _transientRepository;
  final void Function(String message) _onWarning;
  var _persistentAvailable = true;

  @override
  Future<PresetLoadResult> load() async {
    if (!_persistentAvailable) return _transientRepository.load();
    try {
      final result = await _persistentRepository.load();
      if (result.issue != null) {
        _onWarning('部分本地预设无法读取，已隔离损坏或不兼容记录。');
      }
      return result;
    } on Object {
      _persistentAvailable = false;
      _onWarning('本地预设暂时无法读取；系统预设仍可使用，本次修改保留在当前会话。');
      return _transientRepository.load();
    }
  }

  @override
  Future<void> saveAll(Iterable<ToolPreset> presets) async {
    final candidate = List<ToolPreset>.of(presets);
    if (!_persistentAvailable) {
      await _transientRepository.saveAll(candidate);
      return;
    }
    try {
      await _persistentRepository.saveAll(candidate);
    } on Object {
      _persistentAvailable = false;
      await _transientRepository.saveAll(candidate);
      _onWarning('本地预设暂时无法保存；本次修改保留在当前会话。');
    }
  }
}

List<ToolPreset> _validatedUserPresets(
  Iterable<ToolPreset> presets, {
  Iterable<ToolPreset> preserved = const <ToolPreset>[],
}) {
  final requested = List<ToolPreset>.of(presets);
  final protected = List<ToolPreset>.of(preserved);
  final protectedById = <String, ToolPreset>{
    for (final preset in protected) preset.id: preset,
  };
  final values = <ToolPreset>[];
  final ids = <String>{};
  for (final preset in requested) {
    final original = protectedById[preset.id];
    if (original != null) {
      if (!identical(original, preset)) {
        throw const PresetStorageException(
          'duplicate_id',
          'User preset IDs must be unique.',
        );
      }
      continue;
    }
    _validateUserPreset(preset);
    if (!ids.add(preset.id)) {
      throw const PresetStorageException(
        'duplicate_id',
        'User preset IDs must be unique.',
      );
    }
    values.add(preset);
  }
  for (final preset in protected) {
    if (!ids.add(preset.id)) {
      throw const PresetStorageException(
        'duplicate_id',
        'User preset IDs must be unique.',
      );
    }
    values.add(preset);
  }
  if (values.length > PersistentPresetRepository.maximumEntries) {
    throw const PresetStorageException(
      'entry_limit',
      'The local preset entry limit was reached.',
    );
  }
  return List<ToolPreset>.unmodifiable(values);
}

void _validateUserPreset(ToolPreset preset) {
  if (preset.type != PresetType.user || preset.source != PresetSource.local) {
    throw const PresetStorageException(
      'system_preset_write',
      'System presets cannot be written to the user snapshot.',
    );
  }
  final errors = preset.validate();
  if (errors.isNotEmpty) {
    throw PresetStorageException('invalid_preset', errors.join(' '));
  }
  try {
    ToolPresetConfigurationPolicy.validateAndCopy(preset.configuration);
  } on PresetConfigurationException catch (error) {
    throw PresetStorageException('unsafe_configuration', error.message);
  }
}

List<ToolPreset> _unsafePresets(Iterable<ToolPreset> presets) {
  final result = <ToolPreset>[];
  for (final preset in presets) {
    try {
      ToolPresetConfigurationPolicy.validateAndCopy(preset.configuration);
    } on PresetConfigurationException {
      result.add(preset);
    }
  }
  return result;
}

final class _PresetSnapshotJsonCodec {
  const _PresetSnapshotJsonCodec();

  String encode(Iterable<ToolPreset> presets) {
    final values = List<ToolPreset>.of(presets);
    final root = <String, Object?>{
      'storageSchemaVersion':
          PersistentPresetRepository.currentStorageSchemaVersion,
      'documents': values.map(_encodePreset).toList(growable: false),
    };
    late final String encoded;
    try {
      encoded = jsonEncode(root);
    } on Object {
      throw const PresetStorageException(
        'non_json_value',
        'Preset configuration contains a value that JSON cannot encode.',
      );
    }
    if (Uint8List.fromList(utf8.encode(encoded)).length >
        PersistentPresetRepository.maximumSnapshotBytes) {
      throw const PresetStorageException(
        'snapshot_limit',
        'The local preset snapshot exceeds its byte limit.',
      );
    }
    return encoded;
  }

  PresetLoadResult decode(String rawText) {
    if (utf8.encode(rawText).length >
        PersistentPresetRepository.maximumSnapshotBytes) {
      return _issue(
        PresetLoadIssueCode.invalidShape,
        'Stored preset snapshot exceeds its byte limit.',
      );
    }
    Object? decoded;
    try {
      decoded = jsonDecode(rawText);
    } on FormatException {
      return _issue(
        PresetLoadIssueCode.corruptJson,
        'Stored preset snapshot is not valid JSON.',
      );
    }
    final root = _stringMap(decoded);
    if (root == null ||
        root.length != 2 ||
        root.keys.toSet().difference(<String>{
          'storageSchemaVersion',
          'documents',
        }).isNotEmpty) {
      return _issue(
        PresetLoadIssueCode.invalidShape,
        'Stored preset snapshot has invalid top-level fields.',
      );
    }
    final version = root['storageSchemaVersion'];
    if (version is! int) {
      return _issue(
        PresetLoadIssueCode.invalidShape,
        'Preset storage schema version must be an integer.',
      );
    }
    if (version != PersistentPresetRepository.currentStorageSchemaVersion) {
      return _issue(
        PresetLoadIssueCode.unknownVersion,
        'Preset storage schema version is not supported.',
      );
    }
    final documents = root['documents'];
    if (documents is! List ||
        documents.length > PersistentPresetRepository.maximumEntries) {
      return _issue(
        PresetLoadIssueCode.invalidShape,
        'Stored preset documents are missing or exceed the entry limit.',
      );
    }

    final presets = <ToolPreset>[];
    final ids = <String>{};
    PresetLoadIssue? issue;
    for (final document in documents) {
      try {
        final preset = _decodePreset(document);
        if (!ids.add(preset.id)) {
          issue ??= const PresetLoadIssue(
            code: PresetLoadIssueCode.duplicateId,
            message: 'A duplicate user preset ID was isolated.',
          );
          continue;
        }
        presets.add(preset);
      } on Object {
        issue ??= const PresetLoadIssue(
          code: PresetLoadIssueCode.invalidDocument,
          message: 'An invalid user preset was isolated.',
        );
      }
    }
    return PresetLoadResult(
      presets: List<ToolPreset>.unmodifiable(presets),
      issue: issue,
    );
  }

  Map<String, Object?> _encodePreset(ToolPreset preset) => <String, Object?>{
    'presetSchemaVersion': preset.schemaVersion,
    'id': preset.id,
    'toolId': preset.toolId,
    'displayName': preset.displayName,
    'ruleVersion': preset.ruleVersion,
    'type': preset.type.name,
    'source': preset.source.name,
    'configuration': preset.configuration,
  };

  ToolPreset _decodePreset(Object? value) {
    final map = _stringMap(value);
    const keys = <String>{
      'presetSchemaVersion',
      'id',
      'toolId',
      'displayName',
      'ruleVersion',
      'type',
      'source',
      'configuration',
    };
    if (map == null ||
        map.keys.toSet().difference(keys).isNotEmpty ||
        map.length != keys.length) {
      throw const FormatException('invalid preset document fields');
    }
    final typeName = map['type'];
    final sourceName = map['source'];
    final type = PresetType.values.where((item) => item.name == typeName);
    final source = PresetSource.values.where((item) => item.name == sourceName);
    final configuration = _stringMap(map['configuration']);
    if (map['presetSchemaVersion'] is! int ||
        map['id'] is! String ||
        map['toolId'] is! String ||
        map['displayName'] is! String ||
        map['ruleVersion'] is! String ||
        type.length != 1 ||
        source.length != 1 ||
        configuration == null) {
      throw const FormatException('invalid preset document values');
    }
    final preset = ToolPreset(
      schemaVersion: map['presetSchemaVersion']! as int,
      id: map['id']! as String,
      toolId: map['toolId']! as String,
      displayName: map['displayName']! as String,
      ruleVersion: map['ruleVersion']! as String,
      type: type.single,
      source: source.single,
      configuration: configuration,
    );
    final errors = preset.validate();
    if (errors.isNotEmpty) throw FormatException(errors.join(' '));
    if (preset.type != PresetType.user || preset.source != PresetSource.local) {
      throw const FormatException('system preset in user snapshot');
    }
    return preset;
  }

  PresetLoadResult _issue(PresetLoadIssueCode code, String message) =>
      PresetLoadResult(
        presets: const <ToolPreset>[],
        issue: PresetLoadIssue(code: code, message: message),
      );

  Map<String, Object?>? _stringMap(Object? value) {
    if (value is! Map) return null;
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) return null;
      result[entry.key as String] = entry.value;
    }
    return result;
  }
}
