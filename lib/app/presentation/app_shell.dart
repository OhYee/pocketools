import 'package:flutter/material.dart';

import '../../core/feedback/feedback_service.dart';
import '../../core/random/random_source.dart';
import '../../core/presets/preset_controller.dart';
import '../../core/session/session.dart';
import '../../core/session/session_history.dart';
import '../../core/session/session_id_source.dart';
import '../../core/tools/session_actions.dart';
import '../../core/tools/tool_capabilities.dart';
import '../../core/tools/tool_module.dart';
import '../../core/tools/tool_registry.dart';
import '../../design_system/components/app_nav_shell.dart';
import '../../design_system/components/app_warning_banner.dart';
import 'app_settings_controller.dart';
import 'app_warning_controller.dart';
import 'history_page.dart';
import 'home_page.dart';
import 'preset_management_page.dart';
import 'settings_page.dart';

final class PocketoolsShell extends StatefulWidget {
  const PocketoolsShell({
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
  State<PocketoolsShell> createState() => _PocketoolsShellState();
}

final class _PocketoolsShellState extends State<PocketoolsShell> {
  static const _navigation = <AppNavItem>[
    AppNavItem(
      label: '首页',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    AppNavItem(
      label: '历史',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
    ),
    AppNavItem(
      label: '设置',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  var _selectedIndex = 0;
  ToolModule? _activeTool;
  ToolLaunchRequest? _launchRequest;
  var _toolOriginIndex = 0;
  var _showPresetManagement = false;

  @override
  void initState() {
    super.initState();
    widget.warnings.addListener(_warningChanged);
  }

  @override
  void didUpdateWidget(PocketoolsShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.warnings != widget.warnings) {
      oldWidget.warnings.removeListener(_warningChanged);
      widget.warnings.addListener(_warningChanged);
    }
  }

  @override
  void dispose() {
    widget.warnings.removeListener(_warningChanged);
    super.dispose();
  }

  void _warningChanged() => setState(() {});

  void _openTool(ToolModule module) {
    setState(() {
      _toolOriginIndex = _selectedIndex;
      _activeTool = module;
      _launchRequest = null;
      _selectedIndex = 0;
    });
  }

  void _selectNavigation(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) _activeTool = null;
      if (index == 0) _launchRequest = null;
      if (index != 2) _showPresetManagement = false;
    });
  }

  void _openLaunchRequest(ToolLaunchRequest request) {
    final module = widget.registry.byId(request.toolId);
    if (module == null) return;
    setState(() {
      _toolOriginIndex = _selectedIndex;
      _showPresetManagement = false;
      _activeTool = module;
      _launchRequest = request;
      _selectedIndex = 0;
    });
  }

  void _closeTool() {
    setState(() {
      _activeTool = null;
      _launchRequest = null;
      _showPresetManagement = false;
      _selectedIndex = _toolOriginIndex;
    });
  }

  void _handleSystemBack() {
    if (_activeTool != null) {
      _closeTool();
      return;
    }
    if (_showPresetManagement) {
      setState(() => _showPresetManagement = false);
    }
  }

  ToolModuleContext get _moduleContext => ToolModuleContext(
    randomSource: widget.randomSource,
    feedbackService: widget.feedbackService,
    reduceMotion:
        !widget.settings.animationsEnabled ||
        widget.settings.reduceMotion ||
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false),
    feedbackEnabled: widget.settings.feedbackEnabled,
    launchRequest: _launchRequest,
    sessionActions: widget.sessionActions,
    onBack: _closeTool,
  );

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _activeTool == null
          ? HomePage(registry: widget.registry, onOpenTool: _openTool)
          : _activeTool!.buildConfig(context, _moduleContext),
      HistoryPage(
        registry: widget.registry,
        repository: widget.historyRepository,
        onReplay: _openLaunchRequest,
        active: _selectedIndex == 1,
        sessionActions: widget.sessionActions,
      ),
      SettingsPage(
        settings: widget.settings,
        historyRepository: widget.historyRepository,
        onOpenPresets: () => setState(() => _showPresetManagement = true),
      ),
    ];
    if (_showPresetManagement) {
      pages[2] = PresetManagementPage(
        controller: widget.presets,
        onApply: (preset) {
          _openLaunchRequest(widget.presets.launchRequestFor(preset));
        },
        onBack: () => setState(() => _showPresetManagement = false),
      );
    }
    final warning = widget.warnings.message;
    return PopScope<Object?>(
      canPop: _activeTool == null && !_showPresetManagement,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleSystemBack();
      },
      child: Column(
        children: <Widget>[
          if (warning != null)
            AppWarningBanner(
              message: warning,
              onDismiss: widget.warnings.clear,
            ),
          Expanded(
            child: AppNavShell(
              items: _navigation,
              selectedIndex: _selectedIndex,
              onSelected: _selectNavigation,
              accent: _selectedIndex == 0
                  ? _activeTool?.descriptor.accent
                  : null,
              child: pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
