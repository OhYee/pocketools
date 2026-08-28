import 'dart:async';
import 'dart:convert';

import '../../core/session/local_string_store.dart';
import 'local_app_settings.dart';

enum SettingsLoadIssueCode {
  corruptJson,
  unknownVersion,
  invalidShape,
  legacyMigrated,
  pendingSnapshotIgnored,
}

final class SettingsLoadIssue {
  const SettingsLoadIssue({required this.code, required this.message});

  final SettingsLoadIssueCode code;
  final String message;
}

final class SettingsLoadResult {
  const SettingsLoadResult({required this.settings, this.issue});

  final LocalAppSettings settings;
  final SettingsLoadIssue? issue;
}

final class SettingsStorageException implements Exception {
  const SettingsStorageException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'SettingsStorageException($code): $message';
}

/// Strict, versioned local settings store with pending/active writes.
final class LocalSettingsStore {
  LocalSettingsStore({required LocalStringStore store})
    : _store = AllowlistedLocalStringStore(
        delegate: store,
        allowedKeys: ownedKeys,
      );

  static const int currentSchemaVersion = 1;
  static const String activeStorageKey =
      'pocketools.settings.snapshot.active.v1';
  static const String pendingStorageKey =
      'pocketools.settings.snapshot.pending.v1';
  static const Set<String> ownedKeys = <String>{
    activeStorageKey,
    pendingStorageKey,
  };

  final LocalStringStore _store;
  Future<void> _operationTail = Future<void>.value();
  bool _loaded = false;
  LocalAppSettings _settings = const LocalAppSettings();
  SettingsLoadIssue? _issue;

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

  Future<SettingsLoadResult> load() => _serialized(() async {
    await _ensureLoaded();
    return SettingsLoadResult(settings: _settings, issue: _issue);
  });

  Future<void> save(LocalAppSettings settings) => _serialized(() async {
    await _ensureLoaded();
    final encoded = _encode(settings);
    try {
      await _store.writeString(pendingStorageKey, encoded);
      await _store.writeString(activeStorageKey, encoded);
    } on Object {
      throw const SettingsStorageException(
        'write_failed',
        'Local settings could not be saved.',
      );
    }
    _settings = settings;
    _issue = null;
    try {
      await _store.clearOwned(const <String>{pendingStorageKey});
    } on Object {
      // The active value is authoritative. A leftover pending value is safely
      // ignored and surfaced on the next load.
    }
  });

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    String? activeText;
    String? pendingText;
    try {
      activeText = await _store.readString(activeStorageKey);
      pendingText = await _store.readString(pendingStorageKey);
    } on Object {
      throw const SettingsStorageException(
        'read_failed',
        'Local settings could not be read.',
      );
    }
    if (activeText != null) {
      final result = _decode(activeText);
      _settings = result.settings;
      _issue = result.issue;
    }
    if (pendingText != null) {
      _issue = const SettingsLoadIssue(
        code: SettingsLoadIssueCode.pendingSnapshotIgnored,
        message: 'An incomplete settings write was ignored; active settings were used.',
      );
    }
    _loaded = true;
  }

  String _encode(LocalAppSettings value) => jsonEncode(<String, Object?>{
    'settingsSchemaVersion': currentSchemaVersion,
    'themeMode': value.themeMode.name,
    'animationsEnabled': value.animationsEnabled,
    'reduceMotion': value.reduceMotion,
    'soundEnabled': value.soundEnabled,
    'feedbackEnabled': value.feedbackEnabled,
    'historyEnabled': value.historyEnabled,
  });

  SettingsLoadResult _decode(String rawText) {
    Object? decoded;
    try {
      decoded = jsonDecode(rawText);
    } on FormatException {
      return _fallback(
        SettingsLoadIssueCode.corruptJson,
        'Stored settings are not valid JSON.',
      );
    }
    if (decoded is! Map) {
      return _fallback(
        SettingsLoadIssueCode.invalidShape,
        'Stored settings must be a JSON object.',
      );
    }
    final value = <String, Object?>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String) {
        return _fallback(
          SettingsLoadIssueCode.invalidShape,
          'Stored settings keys must be strings.',
        );
      }
      value[entry.key as String] = entry.value;
    }
    final version = value['settingsSchemaVersion'];
    if (version is! int) {
      return _fallback(
        SettingsLoadIssueCode.invalidShape,
        'Settings schema version must be an integer.',
      );
    }
    if (version != 0 && version != currentSchemaVersion) {
      return _fallback(
        SettingsLoadIssueCode.unknownVersion,
        'Settings schema version is not supported.',
      );
    }
    const keys = <String>{
      'settingsSchemaVersion',
      'themeMode',
      'animationsEnabled',
      'reduceMotion',
      'soundEnabled',
      'feedbackEnabled',
      'historyEnabled',
    };
    if (value.keys.length != keys.length ||
        !value.keys.toSet().containsAll(keys)) {
      return _fallback(
        SettingsLoadIssueCode.invalidShape,
        'Stored settings fields are missing or unexpected.',
      );
    }
    try {
      final defaults = const LocalAppSettings();
      final modeName = _legacyValue<String>(
        value['themeMode'],
        defaults.themeMode.name,
        legacy: version == 0,
      );
      final modes = LocalThemeMode.values.where(
        (mode) => mode.name == modeName,
      );
      if (modes.length != 1) throw const FormatException();
      final settings = LocalAppSettings(
        themeMode: modes.single,
        animationsEnabled: _legacyValue<bool>(
          value['animationsEnabled'],
          defaults.animationsEnabled,
          legacy: version == 0,
        ),
        reduceMotion: _legacyValue<bool>(
          value['reduceMotion'],
          defaults.reduceMotion,
          legacy: version == 0,
        ),
        soundEnabled: _legacyValue<bool>(
          value['soundEnabled'],
          defaults.soundEnabled,
          legacy: version == 0,
        ),
        feedbackEnabled: _legacyValue<bool>(
          value['feedbackEnabled'],
          defaults.feedbackEnabled,
          legacy: version == 0,
        ),
        historyEnabled: _legacyValue<bool>(
          value['historyEnabled'],
          defaults.historyEnabled,
          legacy: version == 0,
        ),
      );
      return SettingsLoadResult(
        settings: settings,
        issue: version == 0
            ? const SettingsLoadIssue(
                code: SettingsLoadIssueCode.legacyMigrated,
                message: 'Legacy nullable settings were loaded with defaults.',
              )
            : null,
      );
    } on FormatException {
      return _fallback(
        SettingsLoadIssueCode.invalidShape,
        'Stored settings values have invalid types.',
      );
    }
  }

  T _legacyValue<T>(Object? value, T fallback, {required bool legacy}) {
    if (legacy && value == null) return fallback;
    if (value is! T) throw const FormatException();
    return value;
  }

  SettingsLoadResult _fallback(SettingsLoadIssueCode code, String message) =>
      SettingsLoadResult(
        settings: const LocalAppSettings(),
        issue: SettingsLoadIssue(code: code, message: message),
      );
}
