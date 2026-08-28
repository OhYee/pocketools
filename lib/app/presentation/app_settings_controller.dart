import 'package:flutter/foundation.dart';

import '../platform/local_app_settings.dart';
import '../platform/local_settings_store.dart';

typedef SettingsWarningSink = void Function(String message);

final class AppSettingsController extends ChangeNotifier {
  factory AppSettingsController({
    LocalThemeMode themeMode = LocalThemeMode.system,
    bool animationsEnabled = true,
    bool reduceMotion = false,
    bool soundEnabled = false,
    bool feedbackEnabled = true,
    bool historyEnabled = true,
    LocalSettingsStore? store,
    SettingsWarningSink? onWarning,
  }) => AppSettingsController._(
    LocalAppSettings(
      themeMode: themeMode,
      animationsEnabled: animationsEnabled,
      reduceMotion: reduceMotion,
      soundEnabled: soundEnabled,
      feedbackEnabled: feedbackEnabled,
      historyEnabled: historyEnabled,
    ),
    store: store,
    onWarning: onWarning,
  );

  AppSettingsController._(this._value, {this._store, this._onWarning});

  static Future<AppSettingsController> load({
    required LocalSettingsStore store,
    SettingsWarningSink? onWarning,
  }) async {
    try {
      final result = await store.load();
      if (result.issue != null) {
        onWarning?.call('本地设置存在兼容或损坏数据，已使用安全值继续。');
      }
      return AppSettingsController._(
        result.settings,
        store: store,
        onWarning: onWarning,
      );
    } on Object {
      onWarning?.call('本地设置暂时无法读取；本次使用默认设置。');
      return AppSettingsController._(
        const LocalAppSettings(),
        store: store,
        onWarning: onWarning,
      );
    }
  }

  final LocalSettingsStore? _store;
  final SettingsWarningSink? _onWarning;
  LocalAppSettings _value;
  Future<void> _pendingSave = Future<void>.value();

  LocalThemeMode get themeMode => _value.themeMode;
  bool get animationsEnabled => _value.animationsEnabled;
  bool get reduceMotion => _value.reduceMotion;
  bool get soundEnabled => _value.soundEnabled;
  bool get feedbackEnabled => _value.feedbackEnabled;
  bool get historyEnabled => _value.historyEnabled;
  LocalAppSettings get value => _value;

  set themeMode(LocalThemeMode value) =>
      _update(_value.copyWith(themeMode: value));
  set animationsEnabled(bool value) =>
      _update(_value.copyWith(animationsEnabled: value));
  set reduceMotion(bool value) => _update(_value.copyWith(reduceMotion: value));
  set soundEnabled(bool value) => _update(_value.copyWith(soundEnabled: value));
  set feedbackEnabled(bool value) =>
      _update(_value.copyWith(feedbackEnabled: value));
  set historyEnabled(bool value) =>
      _update(_value.copyWith(historyEnabled: value));

  Future<void> flush() => _pendingSave;

  void _update(LocalAppSettings value) {
    if (value == _value) return;
    _value = value;
    notifyListeners();
    final store = _store;
    if (store == null) return;
    _pendingSave = store.save(value).catchError((Object _) {
      _onWarning?.call('本地设置暂时无法保存；本次应用仍使用当前选择。');
    });
  }
}
