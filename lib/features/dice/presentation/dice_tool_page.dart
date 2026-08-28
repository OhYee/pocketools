import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/feedback/feedback_service.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_id_source.dart';
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
import '../../../design_system/components/app_tool_theme.dart';
import '../../../design_system/components/app_tool_flow_layout.dart';
import '../../../design_system/components/app_tool_scaffold.dart';
import '../domain/dice_models.dart';
import '../domain/dice_roller.dart';
import 'widgets/dice_roll_tile.dart';

final class DiceToolPage extends StatefulWidget {
  const DiceToolPage({
    required this.moduleContext,
    this.sessionRepository,
    this.sessionAdapter,
    this.sessionIdSource,
    this.initialConfig,
    this.initialParentSessionId,
    super.key,
  });

  final ToolModuleContext moduleContext;
  final SessionRepository? sessionRepository;
  final ToolSessionAdapter? sessionAdapter;
  final SessionIdSource? sessionIdSource;
  final DicePoolConfig? initialConfig;
  final String? initialParentSessionId;

  @override
  State<DiceToolPage> createState() => _DiceToolPageState();
}

final class _DiceToolPageState extends State<DiceToolPage>
    with WidgetsBindingObserver {
  static const _quickSides = <int>[4, 6, 8, 10, 12, 20, 100];

  late String _diceCount;
  late String _diceSides;
  late String _keepCount;
  late String _modifier;
  late String _dc;
  late bool _dcEnabled;
  late DiceAggregation _aggregation;
  var _phase = GenerationPhase.ready;
  var _restoring = false;
  var _interactionStarted = false;
  DicePoolResult? _frozenResult;
  SessionRecord? _frozenSession;
  String? _nextParentSessionId;
  String? _generationError;
  var _busy = false;
  var _timeline = 0;
  Timer? _motionTimer;
  Completer<bool>? _motionWait;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initial = widget.initialConfig ?? DicePoolConfig.normal();
    _applyConfig(initial);
    _nextParentSessionId = widget.initialParentSessionId;
    if (_hasSessionPipeline &&
        widget.initialConfig == null &&
        widget.initialParentSessionId == null) {
      _restoring = true;
      unawaited(_restoreLatestSession());
    }
  }

  @override
  void dispose() {
    _timeline++;
    _cancelMotionWait();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _busy && _frozenResult != null) {
      _completeImmediately();
    }
  }

  bool get _hasSessionPipeline =>
      widget.sessionRepository != null &&
      widget.sessionAdapter != null &&
      widget.sessionIdSource != null;

  bool get _configurationLocked => _restoring;

  Future<void> _restoreLatestSession() async {
    try {
      final sessions = await widget.sessionRepository!.findAll();
      SessionRecord? latest;
      for (final session in sessions) {
        if (session.toolId == widget.sessionAdapter!.descriptor.id &&
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
      final decoded = widget.sessionAdapter!.decode(latest);
      if (decoded.input is! DicePoolConfig ||
          decoded.outcome is! DicePoolResult) {
        throw const FormatException('Stored dice session has invalid types.');
      }
      setState(() {
        _frozenSession = latest;
        _frozenResult = decoded.outcome as DicePoolResult;
        _applyConfig(decoded.input as DicePoolConfig);
        _phase = GenerationPhase.completed;
        _restoring = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _restoring = false;
        _generationError = '已保存的 D20 会话无法恢复，请检查本地数据。';
      });
    }
  }

  void _applyConfig(DicePoolConfig config) {
    _diceCount = '${config.diceCount}';
    _diceSides = '${config.diceSides}';
    _aggregation = config.aggregation;
    _keepCount = '${config.keepCount ?? 1}';
    _modifier = '${config.modifier}';
    _dcEnabled = config.dc != null;
    _dc = '${config.dc ?? 10}';
  }

  void _updateDraft(VoidCallback update) {
    final previousDiceCount = _diceCount;
    final previousDiceSides = _diceSides;
    setState(update);
    if (previousDiceCount != _diceCount || previousDiceSides != _diceSides) {
      _again();
    }
  }

  String? _rangeError(String raw, int minimum, int maximum, String message) {
    final value = int.tryParse(raw);
    return value == null || value < minimum || value > maximum ? message : null;
  }

  String? get _diceCountError =>
      _rangeError(_diceCount, 1, 20, '请输入 1～20 的整数。');

  String? get _diceSidesError =>
      _rangeError(_diceSides, 2, 1000, '请输入 2～1000 的整数。');

  String? get _keepCountError {
    if (_aggregation == DiceAggregation.sum) return null;
    final count = int.tryParse(_diceCount);
    final keep = int.tryParse(_keepCount);
    if (count == null || keep == null || keep < 1 || keep > count) {
      return '请输入 1～当前骰子数量的整数。';
    }
    return null;
  }

  String? get _modifierError {
    final value = int.tryParse(_modifier);
    if (value == null) return '请输入整数修正值。';
    if (value < DicePoolConfig.minimumModifier ||
        value > DicePoolConfig.maximumModifier) {
      return '修正值必须在 -9999～9999 范围内。';
    }
    return null;
  }

  String? get _dcError =>
      _dcEnabled && int.tryParse(_dc) == null ? '请输入整数 DC。' : null;

  DicePoolConfig? get _config {
    if (_diceCountError != null ||
        _diceSidesError != null ||
        _keepCountError != null ||
        _modifierError != null ||
        _dcError != null) {
      return null;
    }
    return DicePoolConfig(
      diceCount: int.parse(_diceCount),
      diceSides: int.parse(_diceSides),
      aggregation: _aggregation,
      keepCount: _aggregation == DiceAggregation.sum
          ? null
          : int.parse(_keepCount),
      modifier: int.parse(_modifier),
      dc: _dcEnabled ? int.parse(_dc) : null,
    );
  }

  DiceMode get _mode => _config?.mode ?? DiceMode.custom;

  void _selectMode(DiceMode mode) {
    final modifier = int.tryParse(_modifier) ?? 0;
    final dc = _dcEnabled ? int.tryParse(_dc) : null;
    final config = switch (mode) {
      DiceMode.normal => DicePoolConfig.normal(modifier: modifier, dc: dc),
      DiceMode.advantage => DicePoolConfig.advantage(
        modifier: modifier,
        dc: dc,
      ),
      DiceMode.disadvantage => DicePoolConfig.disadvantage(
        modifier: modifier,
        dc: dc,
      ),
      DiceMode.custom => null,
    };
    if (config != null) {
      setState(() => _applyConfig(config));
    }
  }

  Future<void> _roll({String? parentSessionId}) async {
    final config = _config;
    if (_busy || config == null) return;
    final motion = context.appMotion;
    String? sessionId;
    if (_hasSessionPipeline) {
      try {
        sessionId = widget.sessionIdSource!.next();
      } on Object {
        setState(() {
          _phase = _frozenResult == null
              ? GenerationPhase.ready
              : GenerationPhase.completed;
          _generationError = '安全会话标识不可用，未创建或揭示骰子结果。';
        });
        return;
      }
    }
    final timeline = ++_timeline;
    setState(() {
      _busy = true;
      _phase = GenerationPhase.pressed;
      _generationError = null;
    });

    // Freeze the complete domain result exactly once before any timed display.
    late final DicePoolResult result;
    try {
      result = DiceRoller(widget.moduleContext.randomSource).roll(config);
    } on Object {
      if (!_isCurrent(timeline)) return;
      setState(() {
        _phase = GenerationPhase.ready;
        _busy = false;
        _generationError = '当前环境无法提供安全随机源，未生成结果。';
      });
      return;
    }

    SessionRecord? session;
    if (_hasSessionPipeline) {
      try {
        session = widget.sessionAdapter!.createSession(
          id: sessionId!,
          schemaVersion: 1,
          ruleVersion: DiceRoller.ruleVersion,
          algorithmVersion: DiceRoller.algorithmVersion,
          status: SessionStatus.completed,
          input: config,
          outcome: result,
          parentSessionId: parentSessionId ?? _nextParentSessionId,
        );
      } on Object {
        if (!_isCurrent(timeline)) return;
        setState(() {
          _phase = _frozenResult == null
              ? GenerationPhase.ready
              : GenerationPhase.completed;
          _busy = false;
          _generationError = '无法创建冻结会话，本次未进入揭示阶段。';
        });
        return;
      }
      try {
        await widget.sessionRepository!.save(session);
      } on Object {
        if (!_isCurrent(timeline)) return;
        setState(() {
          _phase = GenerationPhase.ready;
          _busy = false;
          _generationError = '无法保存已冻结结果，本次未进入揭示阶段。';
        });
        return;
      }
    }
    if (!_isCurrent(timeline)) return;
    setState(() {
      _frozenResult = result;
      _frozenSession = session;
      _nextParentSessionId = null;
    });
    if (widget.moduleContext.feedbackEnabled) {
      unawaited(
        widget.moduleContext.feedbackService.emit(FeedbackIntensity.light),
      );
    }

    if (widget.moduleContext.reduceMotion) {
      setState(() => _phase = GenerationPhase.reduced);
      if (!await _waitForMotion(motion.reduced, timeline)) return;
    } else {
      if (!await _waitForMotion(motion.press, timeline)) return;
      setState(() => _phase = GenerationPhase.generating);
      if (!await _waitForMotion(motion.generate, timeline)) return;
      setState(() => _phase = GenerationPhase.revealing);
      if (widget.moduleContext.feedbackEnabled) {
        unawaited(
          widget.moduleContext.feedbackService.emit(FeedbackIntensity.medium),
        );
      }
      if (!await _waitForMotion(motion.reveal, timeline)) return;
    }
    if (!_isCurrent(timeline)) return;
    setState(() {
      _phase = GenerationPhase.completed;
      _busy = false;
    });
  }

  void _again() {
    final parentSessionId = _frozenSession?.id ?? _nextParentSessionId;
    _timeline++;
    _cancelMotionWait();
    setState(() {
      _nextParentSessionId = parentSessionId;
      _frozenSession = null;
      _frozenResult = null;
      _generationError = null;
      _phase = GenerationPhase.ready;
      _busy = false;
    });
  }

  Future<void> _performPrimaryAction() async {
    if (_busy || _config == null) return;
    _interactionStarted = true;
    final parentSessionId = _frozenSession?.id ?? _nextParentSessionId;
    if (_frozenResult != null) _again();
    await _roll(parentSessionId: parentSessionId);
  }

  bool _isCurrent(int timeline) => mounted && timeline == _timeline;

  Future<bool> _waitForMotion(Duration duration, int timeline) {
    _cancelMotionWait();
    final wait = Completer<bool>();
    _motionWait = wait;
    _motionTimer = Timer(duration, () {
      if (identical(_motionWait, wait)) {
        _motionTimer = null;
        _motionWait = null;
      }
      if (!wait.isCompleted) wait.complete(_isCurrent(timeline));
    });
    return wait.future;
  }

  void _cancelMotionWait() {
    _motionTimer?.cancel();
    _motionTimer = null;
    final wait = _motionWait;
    _motionWait = null;
    if (wait != null && !wait.isCompleted) wait.complete(false);
  }

  void _completeImmediately() {
    if (_frozenResult == null) return;
    _timeline++;
    _cancelMotionWait();
    setState(() {
      _phase = GenerationPhase.completed;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) => AppToolTheme(
    accent: ToolAccent.d20,
    child: AppToolScaffold(
      title: 'D20 检定',
      subtitle: '安全随机、稳定聚合；自然 1 或 20 不自动决定成败。',
      onBack: widget.moduleContext.onBack,
      primary: _buildPage(context),
    ),
  );

  Widget _buildPage(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _buildQuickExpression(),
      const SizedBox(height: AppSpacing.lg),
      AppToolFlowLayout(
        coreEntity: _buildCoreEntity(context),
        actionBar: _buildActionBar(),
        advancedOptions: _buildAdvancedOptions(context),
        outcome: _buildOutcome(context),
      ),
    ],
  );

  Widget _buildQuickExpression() => AppSectionCard(
    key: const Key('dice-quick-expression-card'),
    title: '快速配置 · aDb',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final count = _buildQuickStepper(
          key: const Key('dice-quick-count-stepper'),
          label: '骰子数 a',
          value: _diceCount,
          minimum: 1,
          maximum: 20,
          onChanged: (value) => _updateDraft(() => _diceCount = value),
        );
        final sides = _buildQuickStepper(
          key: const Key('dice-quick-sides-stepper'),
          label: '骰面 b',
          value: _diceSides,
          minimum: 2,
          maximum: 1000,
          onChanged: (value) => _updateDraft(() => _diceSides = value),
        );
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              count,
              const SizedBox(height: AppSpacing.lg),
              sides,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: count),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: sides),
          ],
        );
      },
    ),
  );

  Widget _buildQuickStepper({
    required Key key,
    required String label,
    required String value,
    required int minimum,
    required int maximum,
    required ValueChanged<String> onChanged,
  }) => AppStepper(
    key: key,
    label: label,
    value: value,
    minimum: minimum,
    maximum: maximum,
    // Validation remains visible in the expanded advanced form, avoiding
    // duplicate error messages when the same draft is shown in both places.
    enabled: !_configurationLocked,
    editable: false,
    onChanged: onChanged,
  );

  Widget _buildCoreEntity(BuildContext context) {
    final result = _frozenResult;
    final draftConfig = _config ?? DicePoolConfig.normal();
    final config = result?.config ?? draftConfig;
    final stageRolls =
        result?.rolls ??
        List<DiceRoll>.generate(
          config.diceCount,
          (index) =>
              DiceRoll(index: index + 1, value: config.diceSides, isKept: true),
          growable: false,
        );
    final label = result == null
        ? '当前 ${config.diceCount} 枚实体 D${config.diceSides} 骰子，等待掷骰'
        : '当前骰子结果已冻结并保存';
    final size = _stageDieSize(context, config.diceCount);
    final showResult =
        result != null &&
        (_phase == GenerationPhase.completed ||
            _phase == GenerationPhase.reduced);
    final resultVisible = showResult;
    return AppEntityStateView(
      key: const Key('dice-core-entity'),
      semanticLabel: label,
      phase: _phase,
      phaseLabel: _phaseLabel,
      error: _generationError,
      // Only the rendered die hit targets roll. The surrounding stage is
      // presentation chrome, so an empty tap must not consume entropy.
      onActivate: null,
      affordanceHint: _busy
          ? '正在揭示已冻结结果，请等待完成或跳过动画'
          : result == null
          ? '点击骰子或下方按钮掷骰'
          : '点击骰子或下方按钮重置并再掷',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            container: true,
            label: '${config.diceCount} 枚实体 D${config.diceSides} 骰子',
            child: AppPhysicalStageSlot(
              key: const Key('dice-physical-stage-slot'),
              height: AppSizes.dicePhysicalStageSlotHeight,
              child: SingleChildScrollView(
                child: Center(
                  child: Wrap(
                    key: const Key('dice-physical-stage'),
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: stageRolls
                        .map(
                          (roll) => AppPhysicalAction(
                            key: ValueKey<String>(
                              'dice-stage-die-${roll.index}',
                            ),
                            label:
                                '第 ${roll.index} 枚实体 D${config.diceSides} 骰子，'
                                '${result == null ? '点击掷骰' : '点击重置并再掷'}',
                            hint: result == null ? '点击掷骰' : '点击重置并再掷',
                            onTap: _busy || _config == null
                                ? null
                                : _performPrimaryAction,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (resultVisible) ...<Widget>[
                                  Text('#${roll.index}'),
                                  const SizedBox(height: AppSpacing.xs),
                                ],
                                D20RollPrimitive(
                                  value: roll.value,
                                  diceSides: config.diceSides,
                                  size: size,
                                  showValue: resultVisible,
                                  animate:
                                      result != null &&
                                      (_phase == GenerationPhase.generating ||
                                          _phase ==
                                              GenerationPhase.revealing) &&
                                      !widget.moduleContext.reduceMotion,
                                ),
                                if (resultVisible) ...<Widget>[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(roll.isKept ? '保留' : '舍弃'),
                                ],
                              ],
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ),
          ),
          if (showResult) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            AppResultCard(
              title: '总值',
              value: '${result.total}',
              details: _formula(result),
              status: _dcStatus(context, result),
            ),
          ],
        ],
      ),
    );
  }

  double _stageDieSize(BuildContext context, int diceCount) {
    final base = MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop
        ? AppSizes.d20CoreDesktop
        : AppSizes.d20CoreMobile;
    if (diceCount <= 2) return base;
    if (diceCount <= 4) return base * 0.68;
    if (diceCount <= 9) return base * 0.48;
    return base * 0.34;
  }

  Widget _buildActionBar() {
    final config = _config;
    return AppButton(
      key: const Key('roll-button'),
      label: _frozenResult == null ? '掷骰' : '重置并再掷',
      semanticLabel: _busy ? '正在生成骰子结果' : '掷骰并冻结结果',
      onPressed: config == null || _busy ? null : _performPrimaryAction,
      loading: _busy,
      leading: Icons.casino_outlined,
      expand: true,
    );
  }

  Widget _buildAdvancedOptions(BuildContext context) {
    final config = _config;
    return AppSectionCard(
      key: const Key('dice-advanced-options-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ExpansionTile(
            key: const Key('dice-advanced-options'),
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
            title: const Text('高级选项'),
            subtitle: Text(config == null ? '请修正骰池设置' : _configSummary(config)),
            children: <Widget>[
              AppSegmentedControl<DiceMode>(
                label: '检定模式',
                selected: _mode,
                enabled: !_configurationLocked,
                onSelected: _selectMode,
                segments: const <AppSegment<DiceMode>>[
                  AppSegment(value: DiceMode.normal, label: '普通'),
                  AppSegment(value: DiceMode.advantage, label: '优势'),
                  AppSegment(value: DiceMode.disadvantage, label: '劣势'),
                  AppSegment(value: DiceMode.custom, label: '自定义'),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppStepper(
                key: const Key('dice-count-stepper'),
                label: '骰子数量',
                value: _diceCount,
                minimum: 1,
                maximum: 20,
                errorText: _diceCountError,
                enabled: !_configurationLocked,
                onChanged: (value) => _updateDraft(() => _diceCount = value),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppChoiceGroup<int>(
                label: '快捷骰面',
                selected: int.tryParse(_diceSides) ?? -1,
                enabled: !_configurationLocked,
                onSelected: (value) =>
                    _updateDraft(() => _diceSides = '$value'),
                choices: _quickSides
                    .map(
                      (value) => AppChoice<int>(value: value, label: 'D$value'),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppStepper(
                key: const Key('dice-sides-stepper'),
                label: '自定义面数',
                value: _diceSides,
                minimum: 2,
                maximum: 1000,
                errorText: _diceSidesError,
                enabled: !_configurationLocked,
                onChanged: (value) => _updateDraft(() => _diceSides = value),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppSegmentedControl<DiceAggregation>(
                label: '聚合方式',
                selected: _aggregation,
                enabled: !_configurationLocked,
                onSelected: (value) => _updateDraft(() => _aggregation = value),
                segments: const <AppSegment<DiceAggregation>>[
                  AppSegment(value: DiceAggregation.sum, label: '全部求和'),
                  AppSegment(value: DiceAggregation.keepHighest, label: '保留最高'),
                  AppSegment(value: DiceAggregation.keepLowest, label: '保留最低'),
                ],
              ),
              if (_aggregation != DiceAggregation.sum) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                AppStepper(
                  key: const Key('keep-count-stepper'),
                  label: '保留数量 K',
                  value: _keepCount,
                  minimum: 1,
                  maximum: int.tryParse(_diceCount) ?? 1,
                  errorText: _keepCountError,
                  enabled: !_configurationLocked,
                  onChanged: (value) => _updateDraft(() => _keepCount = value),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppStepper(
                key: const Key('modifier-stepper'),
                label: '修正值',
                value: _modifier,
                errorText: _modifierError,
                enabled: !_configurationLocked,
                onChanged: (value) => _updateDraft(() => _modifier = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('设置目标值 DC'),
                subtitle: const Text('开启后比较总值与 DC，不改变骰点。'),
                value: _dcEnabled,
                onChanged: _configurationLocked
                    ? null
                    : (value) => _updateDraft(() => _dcEnabled = value),
              ),
              if (_dcEnabled) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                AppStepper(
                  key: const Key('dc-stepper'),
                  label: '目标值 DC',
                  value: _dc,
                  errorText: _dcError,
                  enabled: !_configurationLocked,
                  onChanged: (value) => _updateDraft(() => _dc = value),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutcome(BuildContext context) {
    final result = _frozenResult;
    final canReveal =
        result != null &&
        (_phase == GenerationPhase.revealing ||
            _phase == GenerationPhase.completed ||
            _phase == GenerationPhase.reduced);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!canReveal) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          AppSectionCard(
            child: Text(
              result == null
                  ? '配置通过后即可掷骰。结果会在动画开始前一次性冻结。'
                  : '结果已经冻结，揭示动画不会再次请求随机值。',
            ),
          ),
        ],
        if (_busy && result != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          const AppSectionCard(child: Text('跳过、隐藏或重新进入都会恢复同一已冻结结果')),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const Key('skip-dice-animation-button'),
            label: '跳过动画',
            variant: AppButtonVariant.quiet,
            onPressed: _completeImmediately,
            expand: true,
          ),
        ],
        if (canReveal) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          AppSessionActions(
            session: _frozenSession,
            controller: widget.moduleContext.sessionActions,
            regenerateLabel: '再来一次',
            regenerateEnabled: !_busy,
            onRegenerate: _again,
          ),
        ],
      ],
    );
  }

  Widget? _dcStatus(BuildContext context, DicePoolResult result) {
    final dc = result.config.dc;
    if (dc == null) {
      return const Text('未设置 DC，仅显示检定总值。');
    }
    final reached = result.dcOutcome == DcOutcome.reached;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          reached ? Icons.check_circle_outline : Icons.remove_circle_outline,
          color: reached
              ? context.appColors.success
              : Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            '${result.total} ${reached ? '≥' : '<'} $dc，'
            '${reached ? '达到' : '未达到'} DC $dc',
          ),
        ),
      ],
    );
  }

  String _configSummary(DicePoolConfig config) {
    final aggregation = switch (config.aggregation) {
      DiceAggregation.sum => '全部求和',
      DiceAggregation.keepHighest => '保留最高 ${config.keepCount}',
      DiceAggregation.keepLowest => '保留最低 ${config.keepCount}',
    };
    final modifier = config.modifier >= 0
        ? '+${config.modifier}'
        : '${config.modifier}';
    final dc = config.dc == null ? '' : ' · DC ${config.dc}';
    return '${_modeLabel(config.mode)} · ${config.diceCount}D${config.diceSides}'
        ' · $aggregation · $modifier$dc';
  }

  String _formula(DicePoolResult result) {
    final values = result.keptInAggregationOrder.map((roll) => roll.value);
    final modifier = result.config.modifier;
    final modifierText = modifier >= 0 ? '+ $modifier' : '- ${modifier.abs()}';
    return '${values.join(' + ')} $modifierText = ${result.total}';
  }

  String get _phaseLabel => switch (_phase) {
    GenerationPhase.ready => '准备就绪',
    GenerationPhase.pressed => '设置已冻结',
    GenerationPhase.generating => '正在生成结果',
    GenerationPhase.revealing => '结果已生成，正在揭示',
    GenerationPhase.completed => '结果已完成',
    GenerationPhase.reduced => '减少动态：结果已生成',
  };

  String _modeLabel(DiceMode mode) => switch (mode) {
    DiceMode.normal => '普通',
    DiceMode.advantage => '优势',
    DiceMode.disadvantage => '劣势',
    DiceMode.custom => '自定义',
  };
}
