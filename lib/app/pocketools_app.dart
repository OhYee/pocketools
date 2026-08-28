import 'dart:async';

import 'package:flutter/material.dart';

import '../core/feedback/feedback_service.dart';
import '../core/random/random_source.dart';
import '../core/presets/preset_controller.dart';
import '../core/presets/preset_id_source.dart';
import '../core/presets/preset_repository.dart';
import '../core/session/local_string_store.dart';
import '../core/session/persistent_session_repository.dart';
import '../core/session/resilient_session_repository.dart';
import '../core/session/session.dart';
import '../core/session/session_history.dart';
import '../core/session/session_id_source.dart';
import '../core/tools/session_actions.dart';
import '../core/tools/tool_registry.dart';
import '../design_system/app_theme.dart';
import 'app_composition.dart';
import 'platform/local_app_settings.dart';
import 'presentation/app_settings_controller.dart';
import 'presentation/app_shell.dart';
import 'presentation/app_warning_controller.dart';
import 'registry/default_tool_registry.dart';

final class PocketoolsApp extends StatefulWidget {
  factory PocketoolsApp({
    ToolRegistry? registry,
    RandomSource? randomSource,
    FeedbackService? feedbackService,
    AppSettingsController? settings,
    SessionRepository? sessionRepository,
    SessionHistoryRepository? historyRepository,
    SessionIdSource? sessionIdSource,
    SessionTextGateway? textGateway,
    PresetController? presets,
    PresetRepository? presetRepository,
    PresetIdSource? presetIdSource,
    AppWarningController? warnings,
    Key? key,
  }) {
    final resolvedWarnings = warnings ?? AppWarningController();
    final resolvedSettings = settings ?? AppSettingsController();
    final memoryPersistent = PersistentSessionRepository(
      store: MemoryLocalStringStore(),
    );
    final SessionHistoryRepository resolvedHistory =
        historyRepository ??
        (sessionRepository is SessionHistoryRepository
            ? sessionRepository as SessionHistoryRepository
            : memoryPersistent);
    final SessionRepository resolvedRepository =
        sessionRepository ??
        ResilientSessionRepository(
          persistentRepository: memoryPersistent,
          persistentHistory: memoryPersistent,
          historyEnabled: () => resolvedSettings.historyEnabled,
          onWarning: resolvedWarnings.show,
        );
    final resolvedIdSource = sessionIdSource ?? SecureSessionIdSource();
    final resolvedRegistry =
        registry ??
        buildDefaultToolRegistry(
          sessionRepository: resolvedRepository,
          sessionIdSource: resolvedIdSource,
        );
    final actions = SessionActionsController(
      registry: resolvedRegistry,
      historyRepository: resolvedHistory,
      textGateway: textGateway ?? const NoopSessionTextGateway(),
    );
    final resolvedPresets =
        presets ??
        PresetController(
          registry: resolvedRegistry,
          repository: presetRepository ?? InMemoryPresetRepository(),
          idSource: presetIdSource ?? SecurePresetIdSource(),
          onWarning: resolvedWarnings.show,
        );
    unawaited(resolvedPresets.load());
    return PocketoolsApp._(
      registry: resolvedRegistry,
      randomSource: randomSource ?? SecureRandomSource(),
      feedbackService: feedbackService ?? const NoopFeedbackService(),
      settings: resolvedSettings,
      sessionRepository: resolvedRepository,
      historyRepository: resolvedHistory,
      sessionIdSource: resolvedIdSource,
      sessionActions: actions,
      presets: resolvedPresets,
      warnings: resolvedWarnings,
      key: key,
    );
  }

  factory PocketoolsApp.production({
    required PocketoolsComposition composition,
    Key? key,
  }) => PocketoolsApp._(
    registry: composition.registry,
    randomSource: composition.randomSource,
    feedbackService: composition.feedbackService,
    settings: composition.settings,
    sessionRepository: composition.sessionRepository,
    historyRepository: composition.historyRepository,
    sessionIdSource: composition.sessionIdSource,
    sessionActions: composition.sessionActions,
    presets: composition.presets,
    warnings: composition.warnings,
    key: key,
  );

  const PocketoolsApp._({
    required this.registry,
    required this.randomSource,
    required this.feedbackService,
    required this.settings,
    required this.sessionRepository,
    required this.historyRepository,
    required this.sessionIdSource,
    required this.sessionActions,
    required this.presets,
    required this.warnings,
    super.key,
  });

  final ToolRegistry registry;
  final RandomSource randomSource;
  final FeedbackService feedbackService;
  final AppSettingsController settings;
  final SessionRepository sessionRepository;
  final SessionHistoryRepository historyRepository;
  final SessionIdSource sessionIdSource;
  final SessionActionsController sessionActions;
  final PresetController presets;
  final AppWarningController warnings;

  @override
  State<PocketoolsApp> createState() => _PocketoolsAppState();
}

final class _PocketoolsAppState extends State<PocketoolsApp> {
  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(PocketoolsApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      oldWidget.settings.removeListener(_rebuild);
      widget.settings.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.settings.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  ThemeMode get _themeMode => switch (widget.settings.themeMode) {
    LocalThemeMode.system => ThemeMode.system,
    LocalThemeMode.light => ThemeMode.light,
    LocalThemeMode.dark => ThemeMode.dark,
  };

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pocketools',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: _themeMode,
    home: PocketoolsShell(
      registry: widget.registry,
      randomSource: widget.randomSource,
      feedbackService: widget.feedbackService,
      settings: widget.settings,
      sessionRepository: widget.sessionRepository,
      historyRepository: widget.historyRepository,
      sessionIdSource: widget.sessionIdSource,
      sessionActions: widget.sessionActions,
      presets: widget.presets,
      warnings: widget.warnings,
    ),
  );
}
