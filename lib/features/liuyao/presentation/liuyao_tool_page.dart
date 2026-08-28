import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/feedback/feedback_service.dart';
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
import '../../../design_system/components/app_surfaces.dart';
import '../../../design_system/components/app_tool_flow_layout.dart';
import '../../../design_system/components/app_tool_scaffold.dart';
import '../../../design_system/components/app_tool_theme.dart';
import '../content/liuyao_content_catalog.dart';
import '../domain/liuyao_caster.dart';
import '../domain/liuyao_models.dart';
import 'liuyao_labels.dart';
import 'liuyao_session_id_source.dart';
import 'liuyao_tool_module.dart';
import 'widgets/liuyao_line_primitive.dart';
import 'widgets/liuyao_reading_view.dart';

final class LiuyaoToolPage extends StatefulWidget {
  const LiuyaoToolPage({
    required this.moduleContext,
    required this.sessionRepository,
    required this.sessionAdapter,
    required this.sessionIdSource,
    this.initialConfig,
    this.initialParentSessionId,
    super.key,
  });

  final ToolModuleContext moduleContext;
  final SessionRepository sessionRepository;
  final ToolSessionAdapter sessionAdapter;
  final LiuyaoSessionIdSource sessionIdSource;
  final LiuyaoConfig? initialConfig;
  final String? initialParentSessionId;

  @override
  State<LiuyaoToolPage> createState() => _LiuyaoToolPageState();
}

final class _LiuyaoToolPageState extends State<LiuyaoToolPage>
    with WidgetsBindingObserver {
  late LiuyaoMode _mode;
  late String _intention;
  late final TextEditingController _intentionController;
  late final FocusNode _nextLineFocusNode;
  var _manualValue = 6;
  var _phase = GenerationPhase.ready;
  var _restoring = true;
  var _interactionStarted = false;
  var _busy = false;
  var _pageVisible = true;
  var _timeline = 0;
  var _animateLatest = false;
  var _draftMeaningVisible = false;
  Timer? _motionTimer;
  Completer<bool>? _motionWait;
  SessionRecord? _session;
  LiuyaoReading? _reading;
  String? _generationError;
  String? _nextParentSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyConfig(widget.initialConfig ?? const LiuyaoConfig(), sync: false);
    _intentionController = TextEditingController(text: _intention);
    _nextLineFocusNode = FocusNode(debugLabel: 'liuyao-next-line');
    _nextParentSessionId = widget.initialParentSessionId;
    if (widget.initialConfig == null && widget.initialParentSessionId == null) {
      unawaited(_restoreLatestSession());
    } else {
      _restoring = false;
    }
  }

  @override
  void dispose() {
    _timeline++;
    _cancelMotionWait();
    _nextLineFocusNode.dispose();
    _intentionController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _pageVisible = state == AppLifecycleState.resumed;
    if (!_pageVisible && _busy && _session != null) {
      _completeImmediately();
    }
  }

  LiuyaoConfig get _config =>
      LiuyaoConfig(mode: _mode, intention: _intention).normalized();

  LiuyaoReading get _visibleReading =>
      _reading ?? LiuyaoReading(config: _config);

  bool get _revealInProgress =>
      _busy &&
      (_phase == GenerationPhase.pressed ||
          _phase == GenerationPhase.generating ||
          _phase == GenerationPhase.revealing);

  LiuyaoReading get _displayReading {
    final reading = _visibleReading;
    if (!_revealInProgress || reading.lines.isEmpty) return reading;
    return LiuyaoReading(
      config: reading.config,
      lines: reading.lines.sublist(0, reading.lines.length - 1),
    );
  }

  String? get _intentionError {
    final errors = _config.validate();
    return errors.isEmpty ? null : errors.first;
  }

  bool get _configurationLocked => _restoring;

  void _applyConfig(LiuyaoConfig config, {bool sync = true}) {
    final normalized = config.normalized();
    _mode = normalized.mode;
    _intention = normalized.normalizedIntention ?? '';
    if (sync) _intentionController.text = _intention;
  }

  void _setMode(LiuyaoMode mode) {
    if (_configurationLocked || _busy || mode == _mode) return;
    final parentSessionId = _session?.id ?? _nextParentSessionId;
    final config = LiuyaoConfig(mode: mode, intention: _intention).normalized();
    setState(() {
      _mode = config.mode;
      _intention = config.normalizedIntention ?? '';
      _intentionController.text = _intention;
      _nextParentSessionId = parentSessionId;
      _session = null;
      _reading = LiuyaoReading(config: config);
      _phase = GenerationPhase.ready;
      _manualValue = 6;
      _animateLatest = false;
      _draftMeaningVisible = false;
      _generationError = null;
    });
  }

  Future<void> _restoreLatestSession() async {
    try {
      final sessions = await widget.sessionRepository.findAll();
      SessionRecord? latest;
      for (final session in sessions) {
        if (session.toolId == widget.sessionAdapter.descriptor.id) {
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
      if (decoded.input is! LiuyaoConfig || decoded.outcome is! LiuyaoReading) {
        throw const FormatException('Stored Liuyao session has invalid types.');
      }
      final reading = decoded.outcome as LiuyaoReading;
      _validateStoredStatus(latest.status, reading);
      setState(() {
        _session = latest;
        _reading = reading;
        _applyConfig(decoded.input as LiuyaoConfig);
        _phase = reading.isComplete
            ? GenerationPhase.completed
            : GenerationPhase.ready;
        _restoring = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _restoring = false;
        _generationError = '已保存的六爻会话无法恢复，请检查本地数据。';
      });
    }
  }

  void _validateStoredStatus(SessionStatus status, LiuyaoReading reading) {
    final expected = _statusFor(reading);
    if (status != expected) {
      throw FormatException(
        'Stored Liuyao status ${status.name} must be ${expected.name}.',
      );
    }
  }

  Future<void> _commitNextLine() async {
    if (_busy || _visibleReading.isComplete) return;
    _interactionStarted = true;
    final contentErrors = LiuyaoContentCatalog.validate();
    if (contentErrors.isNotEmpty) {
      setState(() {
        _generationError = '六爻原创内容未通过完整性校验，未消耗随机值。';
      });
      return;
    }
    final config = _config;
    final configErrors = config.validate();
    if (configErrors.isNotEmpty) {
      setState(() => _generationError = configErrors.first);
      return;
    }
    final base = _reading == null || _reading!.lines.isEmpty
        ? LiuyaoReading(config: config)
        : _reading!;
    if (base.config.mode != config.mode) {
      setState(() => _generationError = '当前草稿的起卦方式已冻结。');
      return;
    }

    final previousSession = _session;
    final parentSessionId =
        previousSession?.parentSessionId ?? _nextParentSessionId;
    late final String sessionId;
    if (previousSession != null) {
      sessionId = previousSession.id;
    } else {
      try {
        sessionId = widget.sessionIdSource.next();
      } on Object {
        setState(() {
          _generationError = '安全会话标识不可用，未创建或揭示六爻结果。';
          _phase = GenerationPhase.ready;
        });
        return;
      }
    }

    late final LiuyaoReading next;
    try {
      final caster = LiuyaoCaster(widget.moduleContext.randomSource);
      next = config.mode == LiuyaoMode.automatic
          ? caster.appendAutomaticLine(base)
          : caster.appendManualLine(base, _manualValue);
    } on Object {
      setState(() => _generationError = '当前输入无法生成下一爻，未改变草稿。');
      return;
    }

    final timeline = ++_timeline;
    setState(() {
      _busy = true;
      _animateLatest = false;
      _generationError = null;
    });
    late final SessionRecord session;
    try {
      session = widget.sessionAdapter.createSession(
        id: sessionId,
        schemaVersion: 1,
        ruleVersion: LiuyaoCaster.ruleVersion,
        algorithmVersion: LiuyaoToolModule.algorithmVersionFor(config.mode),
        status: _statusFor(next),
        input: next.config,
        outcome: next,
        parentSessionId: parentSessionId,
      );
    } on Object {
      if (!_isCurrent(timeline)) return;
      setState(() {
        _busy = false;
        _generationError = '无法创建冻结会话，本爻未进入动画或反馈阶段。';
      });
      return;
    }
    try {
      await widget.sessionRepository.save(session);
    } on Object {
      if (!_isCurrent(timeline)) return;
      setState(() {
        _busy = false;
        _generationError = '无法保存已冻结结果，本爻未进入动画或反馈阶段。';
      });
      return;
    }
    if (!_isCurrent(timeline)) return;
    setState(() {
      _session = session;
      _reading = next;
      _nextParentSessionId = null;
      _applyConfig(next.config);
      _phase = GenerationPhase.pressed;
    });
    if (!_pageVisible) {
      _completeImmediately();
      return;
    }
    _emitFeedback(FeedbackIntensity.medium);
    await _playLineMotion(timeline, next);
  }

  Future<void> _playLineMotion(int timeline, LiuyaoReading reading) async {
    final motion = context.appMotion;
    if (widget.moduleContext.reduceMotion) {
      setState(() {
        _phase = GenerationPhase.reduced;
        _animateLatest = false;
      });
      if (!await _waitForMotion(motion.reduced, timeline)) return;
      _finishLine(timeline, reading, settle: false);
      return;
    }
    if (!await _waitForMotion(motion.press, timeline)) return;
    setState(() => _phase = GenerationPhase.generating);
    if (!await _waitForMotion(motion.generate, timeline)) return;
    setState(() {
      _phase = GenerationPhase.revealing;
      _animateLatest = true;
    });
    _emitFeedback(FeedbackIntensity.light);
    if (!await _waitForMotion(motion.reveal, timeline)) return;
    _finishLine(timeline, reading, settle: true);
  }

  void _finishLine(
    int timeline,
    LiuyaoReading reading, {
    required bool settle,
  }) {
    if (!_isCurrent(timeline)) return;
    setState(() {
      _phase = GenerationPhase.completed;
      _busy = settle && !reading.isComplete;
      _animateLatest = false;
    });
    if (reading.isComplete) {
      _emitFeedback(FeedbackIntensity.light);
      return;
    }
    if (settle) {
      unawaited(_returnToReadyAfterCompletion(timeline));
      return;
    }
    _returnToReady(timeline);
  }

  Future<void> _returnToReadyAfterCompletion(int timeline) async {
    if (!await _waitForMotion(context.appMotion.complete, timeline)) return;
    _returnToReady(timeline);
  }

  void _returnToReady(int timeline) {
    if (!_isCurrent(timeline)) return;
    setState(() {
      _phase = GenerationPhase.ready;
      _busy = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _nextLineFocusNode.requestFocus();
    });
  }

  Future<void> _undoLastLine() async {
    final current = _reading;
    if (_busy ||
        current == null ||
        current.lines.isEmpty ||
        current.isComplete) {
      return;
    }
    final timeline = ++_timeline;
    final previous = current;
    final updated = current.undoLastLine();
    final existing = _session;
    if (existing == null) return;
    late final String sessionId;
    try {
      sessionId = widget.sessionIdSource.next();
    } on Object {
      setState(() {
        _generationError = '安全会话标识不可用，撤销未改变当前草稿。';
      });
      return;
    }
    setState(() {
      _busy = true;
      _generationError = null;
    });
    final session = widget.sessionAdapter.createSession(
      id: sessionId,
      schemaVersion: existing.schemaVersion,
      ruleVersion: existing.ruleVersion,
      algorithmVersion: existing.algorithmVersion,
      status: _statusFor(updated),
      input: updated.config,
      outcome: updated,
      parentSessionId: existing.id,
    );
    try {
      await widget.sessionRepository.save(session);
    } on Object {
      if (!_isCurrent(timeline)) return;
      setState(() {
        _busy = false;
        _reading = previous;
        _generationError = '撤销无法保存，草稿保持不变。';
      });
      return;
    }
    if (!_isCurrent(timeline)) return;
    setState(() {
      _session = session;
      _reading = updated;
      _busy = false;
      _phase = GenerationPhase.ready;
      _animateLatest = false;
    });
  }

  Future<void> _startLinkedDraft() async {
    final completed = _reading;
    final parent = _session;
    if (_busy || completed == null || !completed.isComplete || parent == null) {
      return;
    }
    final timeline = ++_timeline;
    final config = completed.config.normalized(includeIntention: false);
    final draft = LiuyaoReading(config: config);
    late final String sessionId;
    try {
      sessionId = widget.sessionIdSource.next();
    } on Object {
      setState(() {
        _generationError = '安全会话标识不可用，未创建关联的新会话。';
      });
      return;
    }
    late final SessionRecord session;
    try {
      session = widget.sessionAdapter.createSession(
        id: sessionId,
        schemaVersion: 1,
        ruleVersion: LiuyaoCaster.ruleVersion,
        algorithmVersion: LiuyaoToolModule.algorithmVersionFor(config.mode),
        status: SessionStatus.draft,
        input: config,
        outcome: draft,
        parentSessionId: parent.id,
      );
    } on Object {
      setState(() {
        _generationError = '无法创建关联的新会话，当前结果保持不变。';
      });
      return;
    }
    setState(() {
      _busy = true;
      _generationError = null;
    });
    try {
      await widget.sessionRepository.save(session);
    } on Object {
      if (!_isCurrent(timeline)) return;
      setState(() {
        _busy = false;
        _generationError = '无法创建关联的新草稿，当前结果保持不变。';
      });
      return;
    }
    if (!_isCurrent(timeline)) return;
    setState(() {
      _session = session;
      _reading = draft;
      _nextParentSessionId = null;
      _applyConfig(config);
      _phase = GenerationPhase.ready;
      _busy = false;
      _animateLatest = false;
      _manualValue = 6;
    });
  }

  SessionStatus _statusFor(LiuyaoReading reading) {
    if (reading.isComplete) return SessionStatus.completed;
    if (reading.lines.isEmpty) return SessionStatus.draft;
    return SessionStatus.ready;
  }

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

  bool _isCurrent(int timeline) => mounted && timeline == _timeline;

  void _emitFeedback(FeedbackIntensity intensity) {
    if (!widget.moduleContext.feedbackEnabled || !_pageVisible) return;
    unawaited(widget.moduleContext.feedbackService.emit(intensity));
  }

  void _completeImmediately() {
    final reading = _reading;
    if (_session == null || reading == null) return;
    _timeline++;
    _cancelMotionWait();
    setState(() {
      _phase = reading.isComplete
          ? GenerationPhase.completed
          : GenerationPhase.ready;
      _busy = false;
      _animateLatest = false;
    });
  }

  void _resetReading() {
    if (_restoring || _busy) return;
    final parentSessionId = _session?.id ?? _nextParentSessionId;
    final config = _config;
    _timeline++;
    _cancelMotionWait();
    setState(() {
      _nextParentSessionId = parentSessionId;
      _session = null;
      _reading = LiuyaoReading(config: config);
      _generationError = null;
      _phase = GenerationPhase.ready;
      _busy = false;
      _animateLatest = false;
      _manualValue = 6;
    });
  }

  @override
  Widget build(BuildContext context) => AppToolTheme(
    accent: ToolAccent.liuyao,
    child: AppToolScaffold(
      title: '六爻起卦',
      subtitle: '每爻结果先冻结保存，再按初爻到上爻逐步落位。',
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
    final actualReading = _visibleReading;
    final reading = _displayReading;
    final latestLine = actualReading.lines.isEmpty
        ? null
        : actualReading.lines.last;
    final hidingLatestResult =
        _revealInProgress && _phase != GenerationPhase.revealing;
    final label = reading.lines.isEmpty
        ? '当前六爻爻象，等待起卦'
        : '当前六爻爻象，已确认 ${reading.lines.length}/6 爻';
    return AppEntityStateView(
      key: const Key('liuyao-core-entity'),
      phase: _phase,
      phaseLabel: _phaseLabel,
      semanticLabel: label,
      error: _generationError,
      affordanceHint: _busy
          ? '等待当前爻揭示完成，或跳过动画'
          : reading.isComplete
          ? '点击卦象查看含义'
          : _mode == LiuyaoMode.automatic
          ? '点击三枚硬币投下一爻'
          : '使用下方按钮确认下一爻',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_mode == LiuyaoMode.automatic)
            _buildCoinStage(
              coins: hidingLatestResult
                  ? const <LiuyaoCoinSide>[
                      LiuyaoCoinSide.heads,
                      LiuyaoCoinSide.heads,
                      LiuyaoCoinSide.heads,
                    ]
                  : latestLine?.coins ??
                        const <LiuyaoCoinSide>[
                          LiuyaoCoinSide.heads,
                          LiuyaoCoinSide.heads,
                          LiuyaoCoinSide.heads,
                        ],
              preview: latestLine == null || hidingLatestResult,
              active: !actualReading.isComplete,
              animate:
                  _phase == GenerationPhase.revealing &&
                  !widget.moduleContext.reduceMotion,
              line: hidingLatestResult ? null : latestLine,
            ),
          if (reading.isComplete)
            LiuyaoReadingView(
              key: ValueKey<String>(_session?.id ?? 'completed-liuyao'),
              reading: reading,
              animateLatest: _animateLatest,
              reducedMotion: _phase == GenerationPhase.reduced,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Semantics(
                  key: const Key('liuyao-hexagram-visual'),
                  button: true,
                  label: '当前已确认爻象，点击查看目前各爻信息',
                  onTap: () => setState(() => _draftMeaningVisible = true),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _draftMeaningVisible = true),
                    child: ExcludeSemantics(
                      child: LiuyaoDraftLinesView(
                        reading: reading,
                        animateLatest: _animateLatest,
                        compact: true,
                      ),
                    ),
                  ),
                ),
                if (reading.lines.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: Text('尚未确认爻；下一次操作从初爻开始。'),
                  ),
                if (_draftMeaningVisible &&
                    reading.lines.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  AppSectionCard(
                    key: const Key('liuyao-draft-meaning'),
                    title: '目前各爻信息',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: reading.lines.reversed
                          .map(
                            (line) => Text(
                              '${liuyaoLinePositionLabel(line.index)} · '
                              '${line.value} · ${liuyaoLineKindLabel(line.kind)} · '
                              '${line.isMoving ? '动' : '静'}',
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCoinStage({
    required List<LiuyaoCoinSide> coins,
    required bool preview,
    required bool active,
    required bool animate,
    required LiuyaoLine? line,
  }) {
    final canActivate = active && !_busy && _intentionError == null;
    final onTap = canActivate ? _commitNextLine : null;
    final coinKey = preview
        ? const Key('liuyao-ready-coins')
        : const Key('liuyao-current-coins');
    final coinAction = AppPhysicalAction(
      key: coinKey,
      semanticKey: const Key('liuyao-coin-stage'),
      focusNode: _nextLineFocusNode,
      label: preview ? '三枚待抛硬币' : '三枚硬币，当前爻已生成',
      hint: canActivate ? '点击投下一爻' : null,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: LiuyaoCoinTossView(
        coins: coins,
        preview: preview,
        animate: animate,
      ),
    );
    // Keep the compatibility key on the physical coin hit area. There is no
    // separate casting button: labels and the hexagram remain non-activating.
    return Column(
      children: <Widget>[
        const Text('三枚硬币', textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        KeyedSubtree(
          key: const Key('cast-next-liuyao-line-button'),
          child: coinAction,
        ),
        if (line != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(liuyaoLineSemanticLabel(line)),
        ],
      ],
    );
  }

  Widget _buildActionBar() {
    final reading = _visibleReading;
    final enabled = !_busy && _intentionError == null;
    if (_mode == LiuyaoMode.automatic) {
      return Align(
        alignment: Alignment.centerRight,
        child: AppButton(
          key: const Key('reset-liuyao-button'),
          label: '重置',
          variant: AppButtonVariant.quiet,
          semanticLabel: '重置六爻草稿，保留当前设置',
          onPressed: _restoring || _busy ? null : _resetReading,
          leading: Icons.refresh,
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: AppButton(
            key: _mode == LiuyaoMode.automatic
                ? const Key('cast-next-liuyao-line-button')
                : const Key('confirm-liuyao-line-button'),
            label: reading.isComplete
                ? '再起一卦'
                : _mode == LiuyaoMode.automatic
                ? reading.lines.isEmpty
                      ? '开始起卦'
                      : '投下一爻'
                : '确认${liuyaoLinePositionLabel(reading.nextLineIndex)}',
            semanticLabel: reading.isComplete
                ? '再起一卦，创建关联的新草稿'
                : _busy
                ? '正在保存并揭示当前爻'
                : '${liuyaoModeLabel(_mode)}，生成${liuyaoLinePositionLabel(reading.nextLineIndex)}并冻结结果',
            focusNode: _nextLineFocusNode,
            onPressed: enabled
                ? reading.isComplete
                      ? _startLinkedDraft
                      : _commitNextLine
                : null,
            loading: _busy,
            leading: _mode == LiuyaoMode.automatic
                ? Icons.motion_photos_on_outlined
                : Icons.check,
            expand: true,
          ),
        ),
        if (!reading.isComplete) ...<Widget>[
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            key: const Key('reset-liuyao-button'),
            label: '重置',
            variant: AppButtonVariant.quiet,
            semanticLabel: '重置六爻草稿，保留当前设置',
            onPressed: _restoring || _busy ? null : _resetReading,
            leading: Icons.refresh,
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedOptions(BuildContext context) {
    final reading = _visibleReading;
    return AppSectionCard(
      key: const Key('liuyao-advanced-options-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ExpansionTile(
            key: const Key('liuyao-advanced-options'),
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
            title: const Text('高级选项'),
            subtitle: Text(
              '${liuyaoModeLabel(_mode)} · 已确认 ${reading.lines.length}/6 爻',
            ),
            children: <Widget>[
              AppSegmentedControl<LiuyaoMode>(
                key: const Key('liuyao-mode-control'),
                label: '起卦方式',
                segments: const <AppSegment<LiuyaoMode>>[
                  AppSegment(value: LiuyaoMode.automatic, label: '自动投币'),
                  AppSegment(value: LiuyaoMode.manual, label: '手工录入'),
                ],
                selected: _mode,
                enabled: !_configurationLocked && !_busy,
                onSelected: _setMode,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                key: const Key('liuyao-intention-field'),
                controller: _intentionController,
                enabled: !_configurationLocked,
                maxLength: LiuyaoConfig.maximumIntentionLength,
                maxLines: AppSizes.intentionFieldMaxLines,
                decoration: InputDecoration(
                  labelText: '问题或备注（可选）',
                  helperText: '仅保存在本机；分享默认排除，请避免敏感信息',
                  errorText: _intentionError,
                ),
                onChanged: (value) => setState(() => _intention = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _mode == LiuyaoMode.automatic
                    ? '每爻投三枚硬币，共六次，从初爻到上爻；正面 3，反面 2。'
                    : '逐爻选择和值 6／7／8／9；确认后保持原始顺序。',
                key: const Key('liuyao-mode-description'),
              ),
              if (_mode == LiuyaoMode.manual &&
                  !reading.isComplete) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                AppChoiceGroup<int>(
                  key: const Key('liuyao-manual-value-choice'),
                  label: '${liuyaoLinePositionLabel(reading.nextLineIndex)}和值',
                  choices: const <AppChoice<int>>[
                    AppChoice(value: 6, label: '6 · 老阴 · 动'),
                    AppChoice(value: 7, label: '7 · 少阳 · 静'),
                    AppChoice(value: 8, label: '8 · 少阴 · 静'),
                    AppChoice(value: 9, label: '9 · 老阳 · 动'),
                  ],
                  selected: _manualValue,
                  enabled: !_busy && !_restoring,
                  onSelected: (value) => setState(() => _manualValue = value),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                reading.isComplete
                    ? '六爻已完成；结果不可原地改写。'
                    : '已确认 ${reading.lines.length}/6 爻；'
                          '下一爻：${liuyaoLinePositionLabel(reading.nextLineIndex)}',
                key: const Key('liuyao-progress-summary'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (reading.lines.isNotEmpty && !reading.isComplete) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  key: const Key('undo-liuyao-line-button'),
                  label: '撤销上一爻',
                  variant: AppButtonVariant.quiet,
                  onPressed: _busy ? null : _undoLastLine,
                  expand: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutcome(BuildContext context) {
    final reading = _visibleReading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (reading.lines.isEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          AppSectionCard(
            child: Text(_restoring ? '正在恢复本机保存的六爻会话。' : '尚未投掷或录入；非法配置不会消耗随机值。'),
          ),
        ],
        if (_busy && _session != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          const AppSectionCard(child: Text('中断或恢复继续同一已冻结爻，不补投、不重新随机')),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const Key('skip-liuyao-animation-button'),
            label: '跳过动画',
            variant: AppButtonVariant.quiet,
            onPressed: _completeImmediately,
            expand: true,
          ),
        ],
        if (reading.isComplete && !_busy) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          const AppSectionCard(child: Text('再起一卦会创建关联的新草稿，不修改当前结果，也不复制问题或备注。')),
          const SizedBox(height: AppSpacing.lg),
          AppSessionActions(
            session: _session,
            controller: widget.moduleContext.sessionActions,
            regenerateKey: const Key('restart-liuyao-button'),
            regenerateLabel: '再起一卦',
            onRegenerate: _startLinkedDraft,
          ),
        ],
      ],
    );
  }

  String get _phaseLabel => switch (_phase) {
    GenerationPhase.ready =>
      _visibleReading.isComplete
          ? '六爻完成，卦象已锁定'
          : '准备${liuyaoLinePositionLabel(_visibleReading.nextLineIndex)}',
    GenerationPhase.pressed => '当前爻已冻结保存',
    GenerationPhase.generating => '三枚硬币翻转中，结果保持冻结',
    GenerationPhase.revealing => '当前爻正在揭示并从下向上落位',
    GenerationPhase.completed =>
      _visibleReading.isComplete ? '六爻完成，卦象已锁定' : '当前爻已完成',
    GenerationPhase.reduced => '减少动态：同一冻结爻已生成',
  };
}
