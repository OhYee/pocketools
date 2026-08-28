import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/feedback/feedback_service.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_id_source.dart';
import '../../../core/tools/tool_module.dart';
import '../../../core/tools/tool_session_adapter.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/components/app_button.dart';
import '../../../design_system/components/app_generation_state_view.dart';
import '../../../design_system/components/app_physical_deck.dart';
import '../../../design_system/components/app_session_actions.dart';
import '../../../design_system/components/app_surfaces.dart';
import '../../../design_system/components/app_tool_flow_layout.dart';
import '../../../design_system/components/app_tool_scaffold.dart';
import '../../../design_system/components/app_tool_theme.dart';
import '../../tarot/presentation/widgets/tarot_result_view.dart';
import '../../tarot/presentation/widgets/tarot_card_primitive.dart';
import '../content/multi_divination_content_catalog.dart';
import '../content/multi_divination_interpretation.dart';
import '../domain/multi_divination_models.dart';
import '../domain/multi_divination_reader.dart';
import 'multi_divination_labels.dart';
import 'widgets/multi_divination_group_view.dart';
import 'widgets/multi_divination_result_view.dart';

final class MultiDivinationToolPage extends StatefulWidget {
  const MultiDivinationToolPage({
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
  final SessionIdSource sessionIdSource;
  final MultiDivinationConfig? initialConfig;
  final String? initialParentSessionId;

  @override
  State<MultiDivinationToolPage> createState() =>
      _MultiDivinationToolPageState();
}

final class _MultiDivinationToolPageState extends State<MultiDivinationToolPage>
    with WidgetsBindingObserver {
  late String _intention;
  late final TextEditingController _intentionController;
  late final FocusNode _deckFocusNode;
  var _phase = GenerationPhase.ready;
  var _restoring = true;
  var _interactionStarted = false;
  var _busy = false;
  var _animateLatest = false;
  var _pageVisible = true;
  var _timeline = 0;
  var _skipMotionAfterSave = false;
  Timer? _motionTimer;
  Completer<bool>? _motionWait;
  SessionRecord? _session;
  MultiDivinationReading? _reading;
  String? _generationError;
  String? _nextParentSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyConfig(
      widget.initialConfig ?? const MultiDivinationConfig(),
      syncController: false,
    );
    _intentionController = TextEditingController(text: _intention);
    _deckFocusNode = FocusNode(debugLabel: 'multi-divination-deck');
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
    _intentionController.dispose();
    _deckFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _pageVisible = state == AppLifecycleState.resumed;
    if (_pageVisible || !_busy) return;
    if (_motionWait == null) {
      _skipMotionAfterSave = true;
    } else {
      _completeImmediately();
    }
  }

  void _applyConfig(
    MultiDivinationConfig config, {
    bool syncController = true,
  }) {
    final normalized = config.normalized();
    _intention = normalized.normalizedIntention ?? '';
    if (syncController) _intentionController.text = _intention;
  }

  MultiDivinationConfig get _config => MultiDivinationConfig(
    mode: MultiDivinationMode.standard,
    intention: _intention,
  ).normalized();

  MultiDivinationReading get _visibleReading {
    final reading = _reading;
    if (reading != null) return reading;
    try {
      return MultiDivinationReading(config: _config);
    } on Object {
      // Keep the page renderable while an edited intention is invalid. The
      // validation message remains attached to the field and the invalid
      // config is never handed to the domain reader.
      return MultiDivinationReading(config: const MultiDivinationConfig());
    }
  }

  bool get _revealInProgress =>
      _busy &&
      (_phase == GenerationPhase.pressed ||
          _phase == GenerationPhase.generating ||
          _phase == GenerationPhase.revealing);

  MultiDivinationReading get _displayReading {
    final reading = _visibleReading;
    if (!_revealInProgress || reading.groups.isEmpty) return reading;
    return MultiDivinationReading(
      config: reading.config,
      groups: reading.groups.sublist(0, reading.groups.length - 1),
      deckOrder: reading.deckOrder,
    );
  }

  String? get _intentionError {
    final errors = _config.validate();
    return errors.isEmpty ? null : errors.first;
  }

  bool get _configurationLocked => _restoring;

  bool get _deckEnabled {
    if (_busy || _restoring) return false;
    final reading = _visibleReading;
    final config = reading.groups.isNotEmpty && !reading.isComplete
        ? reading.config
        : _config;
    return config.validate().isEmpty;
  }

  Future<void> _restoreLatestSession() async {
    try {
      final sessions = await widget.sessionRepository.findAll();
      SessionRecord? latest;
      for (final session in sessions) {
        if (session.toolId == widget.sessionAdapter.descriptor.id &&
            <SessionStatus>{
              SessionStatus.draft,
              SessionStatus.ready,
              SessionStatus.completed,
            }.contains(session.status)) {
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
      if (decoded.input is! MultiDivinationConfig ||
          decoded.outcome is! MultiDivinationReading) {
        throw const FormatException(
          'Stored multi-divination session has invalid types.',
        );
      }
      final reading = decoded.outcome as MultiDivinationReading;
      _validateStoredStatus(latest.status, reading);
      setState(() {
        _session = latest;
        _reading = reading;
        _applyConfig(decoded.input as MultiDivinationConfig);
        _phase = reading.isComplete
            ? GenerationPhase.completed
            : GenerationPhase.ready;
        _animateLatest = false;
        _restoring = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _restoring = false;
        _generationError = '已保存的融合占卜会话无法恢复，请检查本地数据。';
      });
    }
  }

  void _validateStoredStatus(
    SessionStatus status,
    MultiDivinationReading reading,
  ) {
    final expected = _statusFor(reading);
    if (status != expected) {
      throw FormatException(
        'Stored multi-divination status ${status.name} must be ${expected.name}.',
      );
    }
  }

  Future<void> _commitNextGroup() async {
    if (_busy || _restoring) return;
    _interactionStarted = true;
    final contentErrors = MultiDivinationContentCatalog.validate();
    if (contentErrors.isNotEmpty) {
      setState(() => _generationError = '融合占卜原创内容未通过完整性校验，未消耗随机值。');
      return;
    }
    final current = _visibleReading;
    final startsNewReading = current.isComplete;
    final config = current.groups.isEmpty || startsNewReading
        ? _config
        : current.config;
    final configErrors = config.validate();
    if (configErrors.isNotEmpty) {
      setState(() => _generationError = configErrors.first);
      return;
    }

    final reuseSession = !startsNewReading && _session != null;
    late final String sessionId;
    late final String? parentSessionId;
    if (reuseSession) {
      sessionId = _session!.id;
      parentSessionId = _session!.parentSessionId;
    } else {
      try {
        sessionId = widget.sessionIdSource.next();
      } on Object {
        setState(() {
          _generationError = '安全会话标识不可用，未创建或揭示融合占卜结果。';
          _phase = current.isComplete
              ? GenerationPhase.completed
              : GenerationPhase.ready;
        });
        return;
      }
      parentSessionId = _session?.id ?? _nextParentSessionId;
    }

    final base = current.groups.isEmpty || startsNewReading
        ? MultiDivinationReading(config: config)
        : current;
    final previousPhase = _phase;
    final timeline = ++_timeline;
    _skipMotionAfterSave = false;
    setState(() {
      _busy = true;
      _animateLatest = false;
      _phase = GenerationPhase.pressed;
      _generationError = null;
    });

    late final MultiDivinationReading next;
    try {
      next = MultiDivinationReader(widget.moduleContext.randomSource)
          .appendGroup(base);
    } on Object {
      if (!_isCurrent(timeline)) return;
      setState(() {
        _busy = false;
        _phase = previousPhase;
        _generationError = '当前环境无法生成下一组，未改变已保存草稿。';
      });
      return;
    }

    late final SessionRecord session;
    try {
      session = widget.sessionAdapter.createSession(
        id: sessionId,
        schemaVersion: 1,
        ruleVersion: MultiDivinationReading.ruleVersion,
        algorithmVersion: MultiDivinationReading.algorithmVersion,
        status: _statusFor(next),
        input: next.config,
        outcome: next,
        parentSessionId: parentSessionId,
      );
    } on Object {
      if (!_isCurrent(timeline)) return;
      setState(() {
        _busy = false;
        _phase = previousPhase;
        _generationError = '无法创建冻结会话，本组未进入揭示阶段。';
      });
      return;
    }

    try {
      await widget.sessionRepository.save(session);
    } on Object {
      if (!_isCurrent(timeline)) return;
      setState(() {
        _busy = false;
        _phase = previousPhase;
        _generationError = '无法保存已冻结结果，本组未进入揭示阶段。';
      });
      return;
    }
    if (!_isCurrent(timeline)) return;
    setState(() {
      _session = session;
      _reading = next;
      _nextParentSessionId = null;
      _phase = GenerationPhase.pressed;
    });

    if (!_pageVisible || _skipMotionAfterSave) {
      _skipMotionAfterSave = false;
      _finish(timeline, settle: false);
      return;
    }
    _emitFeedback(FeedbackIntensity.medium);
    await _playGroupMotion(timeline, next);
  }

  Future<void> _playGroupMotion(
    int timeline,
    MultiDivinationReading reading,
  ) async {
    final motion = context.appMotion;
    if (widget.moduleContext.reduceMotion) {
      setState(() {
        _phase = GenerationPhase.reduced;
        _animateLatest = false;
      });
      if (!await _waitForMotion(motion.reduced, timeline)) return;
      _finish(timeline, settle: false);
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
    if (!await _waitForMotion(motion.tarotCard, timeline)) return;
    _finish(timeline, settle: true);
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

  void _finish(int timeline, {required bool settle}) {
    if (!_isCurrent(timeline)) return;
    setState(() {
      _phase = GenerationPhase.completed;
      _busy = false;
      _animateLatest = false;
    });
    _emitFeedback(FeedbackIntensity.light);
  }

  bool _isCurrent(int timeline) => mounted && timeline == _timeline;

  void _emitFeedback(FeedbackIntensity intensity) {
    if (!widget.moduleContext.feedbackEnabled || !_pageVisible) return;
    unawaited(widget.moduleContext.feedbackService.emit(intensity));
  }

  void _completeImmediately() {
    if (!_busy) return;
    if (_motionWait == null) {
      _skipMotionAfterSave = true;
      return;
    }
    _timeline++;
    _cancelMotionWait();
    setState(() {
      _phase = GenerationPhase.completed;
      _busy = false;
      _animateLatest = false;
    });
  }

  void _resetReading() {
    if (_restoring || _busy) return;
    final parentSessionId = _session?.id ?? _nextParentSessionId;
    _timeline++;
    _cancelMotionWait();
    setState(() {
      _nextParentSessionId = parentSessionId;
      _session = null;
      _reading = null;
      _generationError = null;
      _phase = GenerationPhase.ready;
      _busy = false;
      _animateLatest = false;
    });
  }

  Future<void> _startLinkedDraft() async {
    final current = _reading;
    final parent = _session;
    if (_busy || current == null || !current.isComplete || parent == null) {
      return;
    }
    final timeline = ++_timeline;
    final config = _config;
    final configErrors = config.validate();
    if (configErrors.isNotEmpty) {
      setState(() => _generationError = configErrors.first);
      return;
    }
    final draft = MultiDivinationReading(config: config);
    late final String sessionId;
    try {
      sessionId = widget.sessionIdSource.next();
    } on Object {
      setState(() => _generationError = '安全会话标识不可用，未创建关联的新草稿。');
      return;
    }
    late final SessionRecord draftSession;
    try {
      draftSession = widget.sessionAdapter.createSession(
        id: sessionId,
        schemaVersion: 1,
        ruleVersion: MultiDivinationReading.ruleVersion,
        algorithmVersion: MultiDivinationReading.algorithmVersion,
        status: SessionStatus.draft,
        input: config,
        outcome: draft,
        parentSessionId: parent.id,
      );
    } on Object {
      setState(() => _generationError = '无法创建关联的新草稿，当前结果保持不变。');
      return;
    }
    setState(() {
      _busy = true;
      _generationError = null;
    });
    try {
      await widget.sessionRepository.save(draftSession);
    } on Object {
      if (!_isCurrent(timeline)) return;
      setState(() {
        _busy = false;
        _generationError = '无法保存关联的新草稿，当前结果保持不变。';
      });
      return;
    }
    if (!_isCurrent(timeline)) return;
    setState(() {
      _session = draftSession;
      _reading = draft;
      _nextParentSessionId = null;
      _phase = GenerationPhase.ready;
      _busy = false;
      _animateLatest = false;
    });
  }

  Future<void> _showInterpretation(
    MultiDivinationGroup group,
    MultiDivinationCard card,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => TarotInterpretationSheet(
        interpretationIndex:
            group.index * MultiDivinationReading.cardsPerGroup +
            card.slot.index,
        interpretation: const MultiDivinationInterpretationComposer()
            .resolveCard(card),
        useReversals: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppToolTheme(
    accent: ToolAccent.neutral,
    child: AppToolScaffold(
      title: '多重占卜',
      subtitle: '每组抽取三张塔罗牌，A 牌形成一爻；六组完成后展示本卦与变卦。',
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
    final latest = actualReading.groups.isEmpty
        ? null
        : actualReading.groups.last;
    final semanticLabel = reading.groups.isEmpty
        ? '多重占卜牌堆，等待抽取第一组'
        : reading.isComplete
        ? '多重占卜牌堆，六组已完成，主体显示本卦、动爻、变卦和 A1-A6 摘要；点击开始新的融合占卜'
        : '多重占卜牌堆，已完成 ${reading.groups.length}/6 组，当前显示 ${multiDivinationGroupLabel(latest!.index)}';
    return AppEntityStateView(
      key: const Key('multi-divination-core-entity'),
      phase: _phase,
      phaseLabel: _phaseLabel,
      semanticLabel: semanticLabel,
      error: _generationError,
      affordanceHint: reading.isComplete
          ? '点击牌堆开始新的融合占卜'
          : _deckEnabled
          ? '点击牌堆抽取下一组 A/B/C'
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          reading.isComplete
              ? _buildCompletedEntity(context, reading)
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(flex: 2, child: _buildDeck()),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 3,
                      child: latest == null
                          ? Center(
                              child: Text(
                                '当前组\nA · B · C',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Text(
                                  '${multiDivinationGroupLabel(latest.index)} · 当前组',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                MultiDivinationGroupCardsView(
                                  group: latest,
                                  compact: true,
                                  animate:
                                      _animateLatest &&
                                      _phase == GenerationPhase.revealing &&
                                      !widget.moduleContext.reduceMotion,
                                  onCardTap: (card) =>
                                      _showInterpretation(latest, card),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reading.groups.isEmpty
                ? '六爻进度 · 尚未生成'
                : multiDivinationProgressLabel(reading),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedEntity(
    BuildContext context,
    MultiDivinationReading reading,
  ) {
    final primary = reading.primaryHexagram;
    final changed = reading.changedHexagram;
    final summaries = const MultiDivinationInterpretationComposer()
        .resolve(reading)
        .groups
        .map((group) => group.primary.keywords.join('、'))
        .join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(flex: 2, child: _buildDeck()),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                '本卦：${primary?.name ?? '未生成'}',
                key: const Key('multi-divination-entity-primary-summary'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '动爻位：${reading.movingLineIndexes.isEmpty ? '无' : reading.movingLineIndexes.map((index) => index + 1).join('、')}',
                key: const Key('multi-divination-entity-moving-summary'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '变卦：${changed?.name ?? '本卦不变'}',
                key: const Key('multi-divination-entity-changed-summary'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'A1-A6 摘要：$summaries',
                key: const Key('multi-divination-entity-a-summaries'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeck() => AppPhysicalDeck(
    key: const Key('multi-divination-deck'),
    label: _deckEnabled ? '塔罗牌堆，点击抽取三张 A/B/C' : '塔罗牌堆，当前不可操作',
    hint: '点击抽取三张 A/B/C',
    onTap: _deckEnabled ? _commitNextGroup : null,
    focusNode: _deckFocusNode,
    child: SizedBox(
      height: AppSizes.entityStageSlotHeight * 0.72,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: const TarotDeckStack(depth: 9),
      ),
    ),
  );

  Widget _buildActionBar() => Align(
    alignment: Alignment.centerRight,
    child: AppButton(
      key: const Key('reset-multi-divination-button'),
      label: '重置',
      variant: AppButtonVariant.quiet,
      semanticLabel: '重置融合占卜草稿，保留当前设置',
      onPressed: _restoring || _busy ? null : _resetReading,
      leading: Icons.refresh,
    ),
  );

  Widget _buildAdvancedOptions(BuildContext context) {
    final reading = _visibleReading;
    final pendingConfig =
        reading.groups.isNotEmpty &&
        reading.config.normalizedIntention != _config.normalizedIntention;
    return AppSectionCard(
      key: const Key('multi-divination-advanced-options-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ExpansionTile(
            key: const Key('multi-divination-advanced-options'),
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
            title: const Text('高级选项'),
            subtitle: Text(
              '${multiDivinationModeLabel(MultiDivinationMode.standard)} · '
              '${reading.groups.length}/6 组${pendingConfig ? ' · 修改将在下一次新占卜生效' : ''}',
            ),
            children: <Widget>[
              TextField(
                key: const Key('multi-divination-intention-field'),
                controller: _intentionController,
                enabled: !_configurationLocked,
                maxLength: MultiDivinationConfig.maximumIntentionLength,
                maxLines: AppSizes.intentionFieldMaxLines,
                decoration: InputDecoration(
                  labelText: '问题或意图（可选）',
                  helperText: '仅保存在本机；分享默认排除，请避免敏感信息',
                  errorText: _intentionError,
                ),
                onChanged: (value) => setState(() => _intention = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                '固定规则：每次从同一副 78 张塔罗牌无放回抽取 A/B/C；三张牌的正逆位数量映射为一爻，按初爻到上爻完成六组。',
                key: Key('multi-divination-fixed-rule-description'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                reading.isComplete
                    ? '当前六组结果不可原地改写；修改问题或意图后，点击牌堆会开始新的融合占卜。'
                    : '问题或意图可以随时编辑；当前已抽取组保留原配置，修改在下一次新占卜生效。',
                key: const Key('multi-divination-config-effect-description'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutcome(BuildContext context) {
    final reading = _displayReading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MultiDivinationResultView(
          reading: reading,
          animateLatest: _animateLatest,
          reducedMotion: _phase == GenerationPhase.reduced,
          onCardTap: _showInterpretation,
        ),
        if (_busy && _session != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          const AppSectionCard(
            child: Text('本组结果已冻结保存，动画只在当前实体内播放；中断或恢复不会重新抽取。'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const Key('skip-multi-divination-animation-button'),
            label: '跳过动画',
            variant: AppButtonVariant.quiet,
            onPressed: _completeImmediately,
            expand: true,
          ),
        ],
        if (reading.isComplete && !_busy) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          const AppSectionCard(
            child: Text('再次点击牌堆或使用下方按钮，会创建关联的新融合占卜，不修改当前结果。'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSessionActions(
            session: _session,
            controller: widget.moduleContext.sessionActions,
            regenerateKey: const Key('restart-multi-divination-button'),
            regenerateLabel: '再来一次',
            onRegenerate: _startLinkedDraft,
          ),
        ],
      ],
    );
  }

  SessionStatus _statusFor(MultiDivinationReading reading) {
    if (reading.isComplete) return SessionStatus.completed;
    if (reading.groups.isEmpty) return SessionStatus.draft;
    return SessionStatus.ready;
  }

  String get _phaseLabel {
    final reading = _visibleReading;
    return switch (_phase) {
      GenerationPhase.ready =>
        reading.isComplete
            ? '六组完成，牌堆可开启新的融合占卜'
            : '准备第 ${reading.nextGroupIndex + 1} 组 A/B/C',
      GenerationPhase.pressed => '本组已冻结保存',
      GenerationPhase.generating => '三张牌生成中，结果保持冻结',
      GenerationPhase.revealing => '当前 A/B/C 正在揭示并落位',
      GenerationPhase.completed =>
        reading.isComplete
            ? '六组完成，本卦与变卦已锁定'
            : '第 ${reading.groups.length} 组已完成',
      GenerationPhase.reduced => '减少动态：同一冻结组已生成',
    };
  }
}
