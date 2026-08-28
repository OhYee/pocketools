import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/platform/local_app_settings.dart';
import 'package:pocketools/app/platform/local_settings_store.dart';
import 'package:pocketools/core/session/local_string_store.dart';

void main() {
  test('missing storage loads documented defaults', () async {
    final result = await LocalSettingsStore(store: MemoryLocalStringStore())
        .load();

    expect(result.settings, const LocalAppSettings());
    expect(result.issue, isNull);
    expect(result.settings.themeMode, LocalThemeMode.system);
    expect(result.settings.animationsEnabled, isTrue);
    expect(result.settings.feedbackEnabled, isTrue);
    expect(result.settings.historyEnabled, isTrue);
  });

  test('all settings round-trip through a recreated store', () async {
    final backend = MemoryLocalStringStore();
    final store = LocalSettingsStore(store: backend);
    const expected = LocalAppSettings(
      themeMode: LocalThemeMode.dark,
      animationsEnabled: false,
      reduceMotion: true,
      soundEnabled: true,
      feedbackEnabled: false,
      historyEnabled: false,
    );

    await store.save(expected);
    final loaded = await LocalSettingsStore(store: backend).load();

    expect(loaded.settings, expected);
    expect(loaded.issue, isNull);
  });

  test(
    'corrupt and unknown versions return defaults with a load issue',
    () async {
      for (final fixture in <String, SettingsLoadIssueCode>{
        '{': SettingsLoadIssueCode.corruptJson,
        '{"settingsSchemaVersion":88}': SettingsLoadIssueCode.unknownVersion,
      }.entries) {
        final store = LocalSettingsStore(
          store: MemoryLocalStringStore(<String, String>{
            LocalSettingsStore.activeStorageKey: fixture.key,
          }),
        );

        final result = await store.load();

        expect(result.settings, const LocalAppSettings());
        expect(result.issue?.code, fixture.value);
      }
    },
  );

  test('legacy nullable fields migrate to safe defaults', () async {
    final raw = jsonEncode(<String, Object?>{
      'settingsSchemaVersion': 0,
      'themeMode': null,
      'animationsEnabled': null,
      'reduceMotion': true,
      'soundEnabled': null,
      'feedbackEnabled': false,
      'historyEnabled': null,
    });
    final store = LocalSettingsStore(
      store: MemoryLocalStringStore(<String, String>{
        LocalSettingsStore.activeStorageKey: raw,
      }),
    );

    final result = await store.load();

    expect(result.settings.themeMode, LocalThemeMode.system);
    expect(result.settings.reduceMotion, isTrue);
    expect(result.settings.feedbackEnabled, isFalse);
    expect(result.settings.historyEnabled, isTrue);
    expect(result.issue?.code, SettingsLoadIssueCode.legacyMigrated);
  });

  test('failed active settings write keeps the prior active value', () async {
    final backend = _FailingSettingsStore();
    final store = LocalSettingsStore(store: backend);
    const oldSettings = LocalAppSettings(themeMode: LocalThemeMode.light);
    await store.save(oldSettings);
    backend.failActiveWrites = true;

    await expectLater(
      store.save(const LocalAppSettings(themeMode: LocalThemeMode.dark)),
      throwsA(isA<SettingsStorageException>()),
    );

    final reloaded = await LocalSettingsStore(store: backend).load();
    expect(reloaded.settings, oldSettings);
  });

  test('pending settings never replace active settings on load', () async {
    final backend = MemoryLocalStringStore(<String, String>{
      LocalSettingsStore.activeStorageKey: _encodedMode('light'),
      LocalSettingsStore.pendingStorageKey: _encodedMode('dark'),
    });

    final result = await LocalSettingsStore(store: backend).load();

    expect(result.settings.themeMode, LocalThemeMode.light);
    expect(result.issue?.code, SettingsLoadIssueCode.pendingSnapshotIgnored);
  });
}

String _encodedMode(String mode) => jsonEncode(<String, Object?>{
  'settingsSchemaVersion': 1,
  'themeMode': mode,
  'animationsEnabled': true,
  'reduceMotion': false,
  'soundEnabled': false,
  'feedbackEnabled': true,
  'historyEnabled': true,
});

final class _FailingSettingsStore implements LocalStringStore {
  final Map<String, String> values = <String, String>{};
  bool failActiveWrites = false;

  @override
  Future<void> clearOwned(Set<String> allowList) async {
    for (final key in allowList) {
      values.remove(key);
    }
  }

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    if (failActiveWrites && key == LocalSettingsStore.activeStorageKey) {
      throw StateError('controlled failure');
    }
    values[key] = value;
  }
}
