enum LocalThemeMode { system, light, dark }

/// Platform-neutral settings value stored independently from tool sessions.
final class LocalAppSettings {
  const LocalAppSettings({
    this.themeMode = LocalThemeMode.system,
    this.animationsEnabled = true,
    this.reduceMotion = false,
    this.soundEnabled = false,
    this.feedbackEnabled = true,
    this.historyEnabled = true,
  });

  final LocalThemeMode themeMode;
  final bool animationsEnabled;
  final bool reduceMotion;
  final bool soundEnabled;
  final bool feedbackEnabled;
  final bool historyEnabled;

  LocalAppSettings copyWith({
    LocalThemeMode? themeMode,
    bool? animationsEnabled,
    bool? reduceMotion,
    bool? soundEnabled,
    bool? feedbackEnabled,
    bool? historyEnabled,
  }) => LocalAppSettings(
    themeMode: themeMode ?? this.themeMode,
    animationsEnabled: animationsEnabled ?? this.animationsEnabled,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    feedbackEnabled: feedbackEnabled ?? this.feedbackEnabled,
    historyEnabled: historyEnabled ?? this.historyEnabled,
  );

  @override
  bool operator ==(Object other) =>
      other is LocalAppSettings &&
      other.themeMode == themeMode &&
      other.animationsEnabled == animationsEnabled &&
      other.reduceMotion == reduceMotion &&
      other.soundEnabled == soundEnabled &&
      other.feedbackEnabled == feedbackEnabled &&
      other.historyEnabled == historyEnabled;

  @override
  int get hashCode => Object.hash(
    themeMode,
    animationsEnabled,
    reduceMotion,
    soundEnabled,
    feedbackEnabled,
    historyEnabled,
  );
}
