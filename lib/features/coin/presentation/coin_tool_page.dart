import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/feedback/feedback_service.dart';
import '../../../core/platform/motion_sensor.dart';
import '../../../core/session/session.dart';
import '../../../core/tools/tool_module.dart';
import '../../../core/tools/tool_session_adapter.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/components/app_button.dart';
import '../../../design_system/components/app_choice_group.dart';
import '../../../design_system/components/app_generation_state_view.dart';
import '../../../design_system/components/app_physical_action.dart';
import '../../../design_system/components/app_segmented_control.dart';
import '../../../design_system/components/app_session_actions.dart';
import '../../../design_system/components/app_stepper.dart';
import '../../../design_system/components/app_surfaces.dart';
import '../../../design_system/components/app_tool_flow_layout.dart';
import '../../../design_system/components/app_tool_scaffold.dart';
import '../../../design_system/components/app_tool_theme.dart';
import '../domain/coin_models.dart';
import '../domain/coin_tosser.dart';
import 'coin_session_id_source.dart';
import 'widgets/coin_primitive.dart';
import 'widgets/coin_result_view.dart';

final class CoinToolPage extends StatefulWidget {
  const CoinToolPage({
    required this.moduleContext,
    required this.sessionRepository,
    required this.sessionAdapter,
    required this.sessionIdSource,
    this.initialConfig,
    this.initialParentSessionId,
    this.motionSensor,
    super.key,
  });

  final ToolModuleContext moduleContext;
  final SessionRepository sessionRepository;
  final ToolSessionAdapter sessionAdapter;
  final CoinSessionIdSource sessionIdSource;
  final CoinTossConfig? initialConfig;
  final String? initialParentSessionId;
  final MotionSensor? motionSensor;

  @override
  State<CoinToolPage> createState() => _CoinToolPageState();
}

final class _CoinToolPageState extends State<CoinToolPage>
    with WidgetsBindingObserver {
  late CoinTossMode _mode;
  late String _batchCount;
  late String _headsLabel;
  late String _tailsLabel;
  late final TextEditingController _headsLabelController;
  late final TextEditingController _tailsLabelController;
  late bool _customLabels;
  late bool _raceEnabled;
  late String _raceTarget;
  var _phase = GenerationPhase.ready;
  var _restoring = true;
  var _interactionStarted = false;
  var _busy = false;
  var _settleResult = false;
  var _timeline = 0;
  var _pageVisible = true;
  SessionRecord? _frozenSession;
  CoinTossResult? _frozenResult;
  String? _generationError;
  String? _nextParentSessionId;
  late final MotionSensor _motionSensor;
  final ShakeMotionTrigger _shakeTrigger = ShakeMotionTrigger();
  StreamSubscription<MotionSample>? _motionSubscription;
  var _motionStatus = MotionSensorStatus.unknown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyConfig(
      widget.initialConfig ?? const CoinTossConfig(),
      syncControllers: false,
    );
    _headsLabelController = TextEditingController(text: _headsLabel);
    _tailsLabelController = TextEditingController(text: _tailsLabel);
    _nextParentSessionId = widget.initialParentSessionId;
    _motionSensor = widget.motionSensor ?? MotionSensor.system();
    if (widget.initialConfig == null && widget.initialParentSessionId == null) {
      unawaited(_restoreLatestSession());
    } else {
      _restoring = false;
    }
    unawaited(_startMotionInput());
  }

  @override
  void dispose() {
    _timeline++;
    unawaited(_motionSubscription?.cancel());
    unawaited(_motionSensor.stop());
    _headsLabelController.dispose();
    _tailsLabelController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _startMotionInput() async {
    if (widget.moduleContext.reduceMotion) {
      if (mounted) {
        setState(() => _motionStatus = MotionSensorStatus.unsupported);
      }
      return;
    }
    final status = await _motionSensor.start();
    if (!mounted) return;
    setState(() => _motionStatus = status);
    if (status != MotionSensorStatus.available) return;
    _motionSubscription = _motionSensor.samples.listen(
      (sample) {
        if (_shakeTrigger.accept(sample, DateTime.now())) {
          unawaited(_performPrimaryAction());
        }
      },
      onError: (Object _) {
        if (mounted) {
          setState(() => _motionStatus = MotionSensorStatus.unavailable);
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _pageVisible = state == AppLifecycleState.resumed;
    if (state != AppLifecycleState.resumed && _busy && _frozenSession != null) {
      _completeImmediately();
    }
  }

  void _applyConfig(CoinTossConfig config, {bool syncControllers = true}) {
    final normalized = config.normalized();
    _mode = normalized.mode;
    _batchCount = '${normalized.batchCount}';
    _headsLabel = normalized.headsLabel;
    _tailsLabel = normalized.tailsLabel;
    _customLabels =
        normalized.headsLabel != '正面' || normalized.tailsLabel != '反面';
    _raceEnabled = normalized.isRace;
    _raceTarget = '${normalized.raceTarget ?? 2}';
    if (syncControllers) {
      _headsLabelController.text = _headsLabel;
      _tailsLabelController.text = _tailsLabel;
    }
  }

  Future<void> _restoreLatestSession() async {
    try {
      final sessions = await widget.sessionRepository.findAll();
      SessionRecord? latest;
      for (final session in sessions) {
        if (session.toolId == widget.sessionAdapter.descriptor.id &&
            session.status == SessionStatus.completed) {
          latest = session;
          break;
        }
      }
      if (!mounted) return;
      if (_interactionStarted) {
        setState(() => _restoring = false);
        return;
      }
      if (latest == null) {
        setState(() => _restoring = false);
        return;
      }
      final decoded = widget.sessionAdapter.decode(latest);
      if (decoded.input is! CoinTossConfig ||
          decoded.outcome is! CoinTossResult) {
        throw const FormatException('Stored coin session has invalid types.');
      }
      setState(() {
        _frozenSession = latest;
        _frozenResult = decoded.outcome as CoinTossResult;
        _applyConfig(decoded.input as CoinTossConfig);
        _phase = GenerationPhase.completed;
        _settleResult = false;
        _restoring = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _restoring = false;
        _generationError = '已保存的硬币会话无法恢复，请检查本地数据。';
      });
    }
  }

  bool get _configurationLocked => _restoring;

  String? get _batchCountError {
    if (_mode != CoinTossMode.batch || _raceEnabled) return null;
    final value = int.tryParse(_batchCount);
    if (value == null ||
        value < CoinTossConfig.minimumCount ||
        value > CoinTossConfig.maximumCount) {
      return '请输入 1～100 的整数。';
    }
    return null;
  }

  String? get _headsLabelError {
    if (!_customLabels) return null;
    if (_headsLabel.trim().isEmpty) return '正面标签不能为空。';
    if (_headsLabel.trim() == _tailsLabel.trim() &&
        _tailsLabel.trim().isNotEmpty) {
      return '两个标签不能相同。';
    }
    return null;
  }

  String? get _tailsLabelError {
    if (!_customLabels) return null;
    if (_tailsLabel.trim().isEmpty) return '反面标签不能为空。';
    if (_headsLabel.trim() == _tailsLabel.trim() &&
        _headsLabel.trim().isNotEmpty) {
      return '两个标签不能相同。';
    }
    return null;
  }

  String? get _raceTargetError {
    if (_mode != CoinTossMode.batch || !_raceEnabled) return null;
    final value = int.tryParse(_raceTarget);
    if (value == null ||
        value < CoinTossConfig.minimumCount ||
        value > CoinTossConfig.maximumCount) {
      return '请输入 1～100 的整数。';
    }
    return null;
  }

  CoinTossConfig? get _config {
    if (_batchCountError != null ||
        _headsLabelError != null ||
        _tailsLabelError != null ||
        _raceTargetError != null) {
      return null;
    }
    final config = CoinTossConfig(
      mode: _mode,
      batchCount: _mode == CoinTossMode.single
          ? int.tryParse(_batchCount) ?? 3
          : _raceEnabled
          ? int.tryParse(_batchCount) ?? 3
          : int.parse(_batchCount),
      headsLabel: _customLabels ? _headsLabel : '正面',
      tailsLabel: _customLabels ? _tailsLabel : '反面',
      raceTarget: _mode == CoinTossMode.batch && _raceEnabled
          ? int.parse(_raceTarget)
          : null,
    );
    return config.validate().isEmpty ? config.normalized() : null;
  }

  void _setMode(CoinTossMode mode) {
    if (_configurationLocked) return;
    setState(() {
      _mode = mode;
      if (mode == CoinTossMode.single) _raceEnabled = false;
    });
  }

  Future<void> _generate({String? parentSessionId}) async {
    final config = _config;
    if (_busy || config == null) return;
    final motion = context.appMotion;
    final hadFrozenResult = _frozenResult != null;
    late final String sessionId;
    try {
      sessionId = widget.sessionIdSource.next();
    } on Object {
      setState(() {
        _generationError = '安全会话标识不可用，未创建或揭示硬币结果。';
        _phase = hadFrozenResult
            ? GenerationPhase.completed
            : GenerationPhase.ready;
      });
      return;
    }
    final timeline = ++_timeline;
    setState(() {
      _busy = true;
      _settleResult = false;
      _phase = GenerationPhase.pressed;
      _generationError = null;
    });

    late final CoinTossResult result;
    try {
      result = CoinTosser(widget.moduleContext.randomSource).toss(config);
    } on Object {
      if (!_isCurrent(timeline)) return;
      setState(() {
        _busy = false;
        _phase = hadFrozenResult
            ? GenerationPhase.completed
            : GenerationPhase.ready;
        _generationError = '当前环境无法提供安全随机源，未生成硬币结果。';
      });
      return;
    }

    late final SessionRecord session;
    try {
      session = widget.sessionAdapter.createSession(
        id: sessionId,
        schemaVersion: 1,
        ruleVersion: CoinTosser.ruleVersion,
        algorithmVersion: CoinTosser.algorithmVersion,
        status: SessionStatus.completed,
        input: result.config,
        outcome: result,
        parentSessionId: parentSessionId ?? _nextParentSessionId,
      );
    } on Object {
      if (!_isCurrent(timeline)) return;
      setState(() {
        _busy = false;
        _phase = hadFrozenResult
            ? GenerationPhase.completed
            : GenerationPhase.ready;
        _generationError = '无法创建冻结会话，本次未进入揭示阶段。';
      });
      return;
    }
    try {
      await widget.sessionRepository.save(session);
    } on Object {
      if (!_isCurrent(timeline)) return;
      setState(() {
        _busy = false;
        _phase = hadFrozenResult
            ? GenerationPhase.completed
            : GenerationPhase.ready;
        _generationError = '无法保存已冻结结果，本次未进入揭示阶段。';
      });
      return;
    }
    if (!_isCurrent(timeline)) return;
    setState(() {
      _frozenSession = session;
      _frozenResult = result;
      _nextParentSessionId = null;
      _applyConfig(result.config);
    });
    if (!_pageVisible) {
      setState(() {
        _phase = GenerationPhase.completed;
        _busy = false;
        _settleResult = false;
      });
      return;
    }
    _emitFeedback(FeedbackIntensity.medium);

    if (widget.moduleContext.reduceMotion) {
      setState(() => _phase = GenerationPhase.reduced);
      await Future<void>.delayed(motion.reduced);
    } else {
      await Future<void>.delayed(motion.press);
      if (!_isCurrent(timeline)) return;
      setState(() => _phase = GenerationPhase.generating);
      await Future<void>.delayed(motion.coinGenerate);
      if (!_isCurrent(timeline)) return;
      setState(() => _phase = GenerationPhase.revealing);
      _emitFeedback(FeedbackIntensity.light);
      await Future<void>.delayed(_revealDuration(result));
    }
    if (!_isCurrent(timeline)) return;
    setState(() {
      _phase = GenerationPhase.completed;
      _busy = false;
      _settleResult = !widget.moduleContext.reduceMotion;
    });
    _emitFeedback(FeedbackIntensity.light);
  }

  Duration _revealDuration(CoinTossResult result) {
    if (result.config.mode == CoinTossMode.single) {
      return context.appMotion.coinReveal;
    }
    return result.tossCount > AppSizes.coinDetailedRevealLimit
        ? context.appMotion.coinLargeBatchReveal
        : context.appMotion.reveal;
  }

  bool _isCurrent(int timeline) => mounted && timeline == _timeline;

  void _emitFeedback(FeedbackIntensity intensity) {
    if (!widget.moduleContext.feedbackEnabled) return;
    unawaited(widget.moduleContext.feedbackService.emit(intensity));
  }

  void _completeImmediately() {
    if (_frozenSession == null || _frozenResult == null) return;
    _timeline++;
    setState(() {
      _phase = GenerationPhase.completed;
      _busy = false;
      _settleResult = false;
    });
  }

  void _resetToss() {
    if (_restoring || _busy) return;
    final parentSessionId = _frozenSession?.id ?? _nextParentSessionId;
    _timeline++;
    setState(() {
      _nextParentSessionId = parentSessionId;
      _frozenSession = null;
      _frozenResult = null;
      _generationError = null;
      _phase = GenerationPhase.ready;
      _busy = false;
      _settleResult = false;
    });
  }

  Future<void> _performPrimaryAction() async {
    if (_busy || _config == null) return;
    _interactionStarted = true;
    final parentSessionId = _frozenSession?.id;
    if (_frozenResult != null) _resetToss();
    await _generate(parentSessionId: parentSessionId);
  }

  @override
  Widget build(BuildContext context) => AppToolTheme(
    accent: ToolAccent.coin,
    child: AppToolScaffold(
      title: '抛硬币',
      subtitle: '先冻结并保存原始 heads/tails 序列，再播放抛起、翻转与落定。',
      onBack: widget.moduleContext.onBack,
      primary: _buildPage(context),
    ),
  );

  Widget _buildPage(BuildContext context) => AppToolFlowLayout(
    coreEntity: _buildCoreEntity(context),
    actionBar: _buildActionBar(),
    advancedOptions: _buildAdvancedOptions(context),
    outcome: _buildOutcome(context),
  );

  Widget _buildCoreEntity(BuildContext context) {
    final result = _frozenResult;
    final showResult =
        result != null &&
        (_phase == GenerationPhase.revealing ||
            _phase == GenerationPhase.completed ||
            _phase == GenerationPhase.reduced);
    final label = result == null
        ? '当前硬币，等待抛掷'
        : '当前硬币，${result.tossCount} 次结果已冻结并保存';
    return AppEntityStateView(
      key: const Key('coin-core-entity'),
      phase: _phase,
      phaseLabel: _phaseLabel,
      semanticLabel: label,
      error: _generationError,
      // Keep the card as presentation chrome; only the physical coin action
      // is allowed to start a toss and consume randomness.
      onActivate: null,
      affordanceHint: _busy
          ? '正在揭示已冻结结果，请等待完成或跳过动画'
          : result == null
          ? '点击硬币或下方按钮抛掷'
          : '点击硬币或下方按钮再抛一次',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_phase == GenerationPhase.generating && result != null)
            Center(
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: List<Widget>.generate(
                  _placeholderCount(result.config),
                  (index) => CoinPlaceholder(
                    compact: result.config.mode == CoinTossMode.batch,
                  ),
                  growable: false,
                ),
              ),
            )
          else if (showResult)
            CoinResultView(
              key: ValueKey<String>(_frozenSession!.id),
              result: result,
              reveal: _phase == GenerationPhase.revealing,
              reducedMotion: _phase == GenerationPhase.reduced,
              settle: _phase == GenerationPhase.completed && _settleResult,
              onTap: _busy ? null : _performPrimaryAction,
            )
          else
            AppPhysicalAction(
              key: const Key('coin-ready-physical-entity'),
              label: '待抛实体硬币，点击抛掷',
              hint: '点击抛掷',
              onTap: _busy || _config == null ? null : _performPrimaryAction,
              child: const Center(child: CoinPlaceholder()),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    final config = _config;
    return AppButton(
      key: const Key('toss-coin-button'),
      label: config == null
          ? '抛硬币'
          : _frozenResult == null
          ? _actionLabel(config)
          : '再抛一次',
      semanticLabel: _busy ? '正在生成硬币结果' : '抛硬币并冻结结果',
      onPressed: config == null || _busy ? null : _performPrimaryAction,
      loading: _busy,
      leading: Icons.circle_outlined,
      expand: true,
    );
  }

  Widget _buildAdvancedOptions(BuildContext context) {
    final config = _config;
    return AppSectionCard(
      key: const Key('coin-advanced-options-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ExpansionTile(
            key: const Key('coin-advanced-options'),
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
            title: const Text('高级选项'),
            subtitle: Text(
              config == null ? '请修正硬币设置' : _configSummary(config),
              key: const Key('coin-config-summary'),
            ),
            children: <Widget>[
              AppSegmentedControl<CoinTossMode>(
                key: const Key('coin-mode-control'),
                label: '模式',
                segments: const <AppSegment<CoinTossMode>>[
                  AppSegment(value: CoinTossMode.single, label: '单次'),
                  AppSegment(value: CoinTossMode.batch, label: '批量'),
                ],
                selected: _mode,
                enabled: !_configurationLocked,
                onSelected: _setMode,
              ),
              if (_mode == CoinTossMode.batch) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                AppChoiceGroup<int>(
                  key: const Key('coin-batch-shortcuts'),
                  label: '常用次数',
                  choices: const <AppChoice<int>>[
                    AppChoice(value: 3, label: '3'),
                    AppChoice(value: 5, label: '5'),
                    AppChoice(value: 10, label: '10'),
                  ],
                  selected: int.tryParse(_batchCount) ?? 3,
                  enabled: !_configurationLocked && !_raceEnabled,
                  onSelected: (value) => setState(() => _batchCount = '$value'),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppStepper(
                  key: const Key('coin-batch-count-stepper'),
                  label: '抛掷次数',
                  value: _batchCount,
                  minimum: CoinTossConfig.minimumCount,
                  maximum: CoinTossConfig.maximumCount,
                  errorText: _batchCountError,
                  enabled: !_configurationLocked && !_raceEnabled,
                  onChanged: (value) => setState(() => _batchCount = value),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SwitchListTile(
                key: const Key('custom-coin-labels-switch'),
                contentPadding: EdgeInsets.zero,
                title: const Text('自定义两面'),
                subtitle: const Text('只改变展示标签，原始值仍保存为 heads / tails'),
                value: _customLabels,
                onChanged: _configurationLocked
                    ? null
                    : (value) => setState(() => _customLabels = value),
              ),
              if (_customLabels) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('coin-heads-label-field'),
                  enabled: !_configurationLocked,
                  controller: _headsLabelController,
                  decoration: InputDecoration(
                    labelText: '正面标签',
                    errorText: _headsLabelError,
                  ),
                  onChanged: (value) => setState(() => _headsLabel = value),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('coin-tails-label-field'),
                  enabled: !_configurationLocked,
                  controller: _tailsLabelController,
                  decoration: InputDecoration(
                    labelText: '反面标签',
                    errorText: _tailsLabelError,
                  ),
                  onChanged: (value) => setState(() => _tailsLabel = value),
                ),
              ],
              if (_mode == CoinTossMode.batch) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                SwitchListTile(
                  key: const Key('coin-race-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('率先达到'),
                  subtitle: const Text('任一面先达到目标次数即停止'),
                  value: _raceEnabled,
                  onChanged: _configurationLocked
                      ? null
                      : (value) => setState(() => _raceEnabled = value),
                ),
                if (_raceEnabled) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  AppStepper(
                    key: const Key('coin-race-target-stepper'),
                    label: '目标次数',
                    value: _raceTarget,
                    minimum: CoinTossConfig.minimumCount,
                    maximum: CoinTossConfig.maximumCount,
                    errorText: _raceTargetError,
                    enabled: !_configurationLocked,
                    onChanged: (value) => setState(() => _raceTarget = value),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _configSummary(CoinTossConfig config) {
    final labels =
        '${config.headsLabel} / ${config.tailsLabel}；'
        '原始值 heads / tails';
    if (config.mode == CoinTossMode.single) return '单次 · $labels';
    if (config.isRace) {
      return '率先达到 ${config.raceTarget} 次 · 任一面达到目标即停止 · $labels';
    }
    return '批量 ${config.batchCount} 次 · 完整生成指定次数 · $labels';
  }

  String _actionLabel(CoinTossConfig config) {
    if (config.mode == CoinTossMode.single) return '抛一次';
    if (config.isRace) return '开始，率先达到 ${config.raceTarget} 次';
    return '抛 ${config.batchCount} 次';
  }

  Widget _buildOutcome(BuildContext context) {
    final result = _frozenResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (result == null) ...<Widget>[
          AppSectionCard(
            child: Text(
              _restoring
                  ? '正在恢复本机保存的硬币会话。'
                  : '配置通过后即可抛掷；动画不会访问随机源。\n$_motionHint',
            ),
          ),
        ],
        if (_busy && result != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          const AppSectionCard(child: Text('中断或恢复继续同一已冻结结果，不重新抛掷')),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const Key('skip-coin-animation-button'),
            label: '跳过动画',
            variant: AppButtonVariant.quiet,
            onPressed: _completeImmediately,
            expand: true,
          ),
        ],
        if (result != null &&
            (_phase == GenerationPhase.completed ||
                _phase == GenerationPhase.reduced)) ...<Widget>[
          AppSessionActions(
            session: _frozenSession,
            controller: widget.moduleContext.sessionActions,
          ),
        ],
      ],
    );
  }

  String get _motionHint {
    if (widget.moduleContext.reduceMotion) {
      return '已开启减少动态；请点击硬币或下方按钮手动抛掷。';
    }
    return switch (_motionStatus) {
      MotionSensorStatus.available => '可摇动 Android 设备，也可点击硬币手动抛掷。',
      MotionSensorStatus.unknown => '正在检查体感抛掷；手动入口始终可用。',
      MotionSensorStatus.unsupported ||
      MotionSensorStatus.unavailable => '此设备不支持体感抛掷；请点击硬币或下方按钮。',
    };
  }

  int _placeholderCount(CoinTossConfig config) =>
      config.maximumTosses.clamp(1, AppSizes.coinDetailedRevealLimit);

  String get _phaseLabel => switch (_phase) {
    GenerationPhase.ready => '准备就绪',
    GenerationPhase.pressed => '设置已冻结',
    GenerationPhase.generating => '结果已冻结，准备抛起',
    GenerationPhase.revealing => '结果已生成，正在抛起、翻转并落定',
    GenerationPhase.completed => '结果已完成',
    GenerationPhase.reduced => '减少动态：同一结果已生成',
  };
}
