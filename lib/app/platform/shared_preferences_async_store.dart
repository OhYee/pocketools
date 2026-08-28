import 'dart:collection';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/session/local_string_store.dart';
import '../../core/session/persistent_session_repository.dart';
import '../../core/presets/preset_repository.dart';
import 'local_settings_store.dart';

/// Primitive string-only production backend for Pocketools-owned local keys.
final class SharedPreferencesAsyncStringStore implements LocalStringStore {
  SharedPreferencesAsyncStringStore({
    required this.preferences,
    required Set<String> allowedKeys,
  }) : allowedKeys = UnmodifiableSetView<String>(Set<String>.of(allowedKeys));

  factory SharedPreferencesAsyncStringStore.pocketools({
    SharedPreferencesAsync? preferences,
  }) => SharedPreferencesAsyncStringStore(
    preferences: preferences ?? SharedPreferencesAsync(),
    allowedKeys: pocketoolsPreferenceKeys,
  );

  static const Set<String> pocketoolsPreferenceKeys = <String>{
    ...PersistentSessionRepository.ownedKeys,
    ...PersistentPresetRepository.ownedKeys,
    ...LocalSettingsStore.ownedKeys,
  };

  final SharedPreferencesAsync preferences;
  final Set<String> allowedKeys;

  void _validateKey(String key) {
    if (!allowedKeys.contains(key)) {
      throw ArgumentError.value(key, 'key', 'Key is not owned by Pocketools.');
    }
  }

  @override
  Future<String?> readString(String key) {
    _validateKey(key);
    return preferences.getString(key);
  }

  @override
  Future<void> writeString(String key, String value) {
    _validateKey(key);
    return preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) {
    _validateKey(key);
    return preferences.remove(key);
  }

  @override
  Future<void> clearOwned(Set<String> allowList) {
    for (final key in allowList) {
      _validateKey(key);
    }
    return preferences.clear(allowList: Set<String>.of(allowList));
  }
}
