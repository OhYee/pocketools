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
import '../../../design_system/components/app_physical_deck.dart';
import '../../../design_system/components/app_segmented_control.dart';
import '../../../design_system/components/app_session_actions.dart';
import '../../../design_system/components/app_surfaces.dart';
import '../../../design_system/components/app_tool_flow_layout.dart';
import '../../../design_system/components/app_tool_scaffold.dart';
import '../../../design_system/components/app_tool_theme.dart';
import '../content/tarot_content_catalog.dart';
import '../domain/tarot_models.dart';
import '../domain/tarot_reader.dart';
import 'tarot_labels.dart';
import 'tarot_session_id_source.dart';
import 'widgets/tarot_card_primitive.dart';
import 'widgets/tarot_result_view.dart';

final class TarotToolPage extends StatefulWidget {
  const TarotToolPage({
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
  final TarotSessionIdSource sessionIdSource;
  final TarotReadingConfig? initialConfig;
  final String? initialParentSessionId;

  @override
  State<TarotToolPage> createState() => _TarotToolPageState();
}

final class _TarotToolPageState extends State<TarotToolPage>
    with WidgetsBindingObserver {
  late TarotSpreadPreset _spread;
  late bool _includeMinorArcana;
  late bool _useReversals;
  late TarotRevealMode _revealMode;
  late String _intention;
  late final TextEditingController _intentionController;
  late final FocusNode _deckFocusNode;
  var _phase = GenerationPhase.ready;
  var _restoring = true;
  var _interactionStarted = false;
  var _busy = false;
  var _settleResult = false;
  var _revealedCount = 0;
  var _timeline = 0;
  var _pageVisible = true;
  Timer? _motionTimer;
  Completer<bool>? _motionWait;
  SessionRecord? _frozenSession;
  TarotReadingResult? _frozenResult;
  final List<TarotDrawnCard> _drawnCards = <TarotDrawnCard>[];
  String? _generationError;
  String? _nextParentSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyConfig(
      widget.initialConfig ?? const TarotReadingConfig(),
      syncController: false,
    );
    _intentionController = TextEditingController(text: _intention);
    _deckFocusNode = FocusNode(debugLabel: 'tarot-deck');
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
    if (state != AppLifecycleState.resumed && _busy && _frozenSession != null) {
      _completeImmediately();
    }
  }

  void _applyConfig(TarotReadingConfig config, {bool syncController = true}) {
    _spread = config.spread;
    _includeMinorArcana = config.includeMinorArcana;
    _useReversals = config.useReversals;
    _revealMode = config.revealMode;
    _intention = config.normalizedIntention ?? '';
    if (syncController) _intentionController.text = _intention;
  }

  TarotReadingConfig get _config => TarotReadingConfig(
    spread: _spread,
    includeMinorArcana: _includeMinorArcana,
    useReversals: _useReversals,
    revealMode: _revealMode,
    intention: _intention,
  );

  String? get _intentionError {
    final errors = _config.validate();
    return errors.isEmpty ? null : errors.first;
  }

  bool get _configurationLocked => _restoring;

  TarotReadingResult? get _displayResult {
    final result = _frozenResult;
    if (result == null || _drawnCards.length == result.cards.length) {
      return result;
    }
    return TarotReadingResult(
      config: result.config,
      cards: _drawnCards,
      contentVersion: result.contentVersion,
    );
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
      if (decoded.input is! TarotReadingConfig ||
          decoded.outcome is! TarotReadingResult) {
        throw const FormatException('Stored tarot session has invalid types.');
      }
      final result = decoded.outcome as TarotReadingResult;
      final restoredCards = _cardsInSessionOrder(latest, sessions);
      setState(() {
        _frozenSession = latest;
        _frozenResult = result;
        _drawnCards
          ..clear()
          ..addAll(restoredCards);
        _applyConfig(decoded.input as TarotReadingConfig);
        _revealedCount = result.cards.length;
        _phase = GenerationPhase.completed;
        _settleResult = false;
        _restoring = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _restoring = false;
        _generationError = '已保存的塔罗会话无法恢复，请检查本地数据。';
      });
    }
  }

  List<TarotDrawnCard> _cardsInSessionOrder(
    SessionRecord latest,
    List<SessionRecord> sessions,
  ) {
    final byId = <String, SessionRecord>{
      for (final session in sessions) session.id: session,
    };
    final chain = <SessionRecord>[];
    final visited = <String>{};
    SessionRecord? cursor = latest;
    while (cursor != null && visited.add(cursor.id)) {
      chain.add(cursor);
      final parentId = cursor.parentSessionId;
      cursor = parentId == null ? null : byId[parentId];
    }
    final cards = <TarotDrawnCard>[];
    final seen = <String>{};
    for (final session in chain.reversed) {
      final decoded = widget.sessionAdapter.decode(session);
      final result = decoded.outcome as TarotReadingResult;
      for (final card in result.cards) {
        final key = '${card.card.id}:${card.position.name}';
        if (seen.add(key)) cards.add(card);
      }
    }
    return cards;
  }

  Future<void> _generate({
    String? parentSessionId,
    TarotReadingConfig? configOverride,
  }) async {
    if (_busy) return;
    final contentErrors = TarotContentCatalog.validate();
    if (contentErrors.isNotEmpty) {
      setState(() => _generationError = '塔罗原创内容未通过完整性校验，未消耗随机值。');
      return;
    }
    final requestedConfig = configOverride ?? _config;
    final baseConfig = parentSessionId != null
        ? requestedConfig.normalized(includeIntention: false)
        : requestedConfig.normalized();
    final config = _drawnCards.length >= baseConfig.drawCount
        ? TarotReadingConfig(
            spread: TarotSpreadPreset.dailyCard,
            includeMinorArcana: baseConfig.includeMinorArcana,
            useReversals: baseConfig.useReversals,
            revealMode: baseConfig.revealMode,
          )
        : baseConfig;
    final configErrors = config.validate();
    if (configErrors.isNotEmpty) {
      setState(() => _generationError = configErrors.first);
      return;
    }
    final motion = context.appMotion;
    final hadFrozenResult = _frozenResult != null;
    late final String sessionId;
    try {
      sessionId = widget.sessionIdSource.next();
    } on Object {
      setState(() {
        _generationError = '安全会话标识不可用，未创建或揭示塔罗结果。';
        _phase = hadFrozenResult
            ? GenerationPhase.completed
            : GenerationPhase.ready;
        _revealedCount = hadFrozenResult ? _frozenResult!.cards.length : 0;
      });
      return;
    }
    final timeline = ++_timeline;
    setState(() {
      _busy = true;
      _settleResult = false;
      _revealedCount = _drawnCards.length;
      _phase = GenerationPhase.pressed;
      _generationError = null;
    });

    late final TarotReadingResult result;
    try {
      final reader = TarotReader(
        widget.moduleContext.randomSource,
        contentVersion: TarotContentCatalog.contentVersion,
      );
      result = TarotReadingResult(
        config: config,
        cards: <TarotDrawnCard>[
          reader.drawOne(
            config,
            position: _nextPosition(config),
            excludedCardIds: _drawnCards.map((drawn) => drawn.card.id),
          ),
        ],
        contentVersion: TarotContentCatalog.contentVersion,
      );
    } on Object {
      if (!_isCurrent(timeline)) return;
      setState(() {
        _busy = false;
        _phase = hadFrozenResult
            ? GenerationPhase.completed
            : GenerationPhase.ready;
        _revealedCount = hadFrozenResult ? _frozenResult!.cards.length : 0;
        _generationError = '当前环境无法提供安全随机源，未生成塔罗结果。';
      });
      return;
    }

    late final SessionRecord session;
    try {
      session = widget.sessionAdapter.createSession(
        id: sessionId,
        schemaVersion: 1,
        ruleVersion: TarotReader.ruleVersion,
        algorithmVersion: TarotReader.algorithmVersion,
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
        _revealedCount = hadFrozenResult ? _frozenResult!.cards.length : 0;
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
        _revealedCount = hadFrozenResult ? _frozenResult!.cards.length : 0;
        _generationError = '无法保存已冻结结果，本次未进入揭示阶段。';
      });
      return;
    }
    if (!_isCurrent(timeline)) return;
    final allCards = <TarotDrawnCard>[..._drawnCards, ...result.cards];
    setState(() {
      _frozenSession = session;
      _frozenResult = result;
      _drawnCards
        ..clear()
        ..addAll(allCards);
      _nextParentSessionId = null;
    });
    if (!_pageVisible) {
      _completeImmediately();
      return;
    }
    _emitFeedback(FeedbackIntensity.medium);

    if (widget.moduleContext.reduceMotion) {
      setState(() {
        _revealedCount = _drawnCards.length;
        _phase = GenerationPhase.reduced;
      });
      if (!await _waitForMotion(motion.reduced, timeline)) return;
      _finish(timeline, settle: false);
      return;
    }

    if (!await _waitForMotion(motion.press, timeline)) return;
    setState(() => _phase = GenerationPhase.generating);
    if (!await _waitForMotion(motion.generate, timeline)) return;
    setState(() => _phase = GenerationPhase.revealing);

    setState(() => _revealedCount = _drawnCards.length);
    _emitFeedback(FeedbackIntensity.light);
    if (!await _waitForMotion(_allAtOnceRevealDuration(result), timeline)) {
      return;
    }
    _finish(timeline, settle: true);
  }

  Duration _allAtOnceRevealDuration(TarotReadingResult result) =>
      context.appMotion.tarotCard;

  TarotPosition _nextPosition(TarotReadingConfig config) {
    final positions = config.positions;
    if (_drawnCards.length < positions.length) {
      return positions[_drawnCards.length];
    }
    // Once a configured spread is complete, further deck taps remain useful:
    // they append independent guidance cards without mutating the completed
    // positions already on the table.
    return TarotPosition.dailyGuidance;
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
      _settleResult = settle;
    });
    _emitFeedback(FeedbackIntensity.light);
  }

  bool _isCurrent(int timeline) => mounted && timeline == _timeline;

  void _emitFeedback(FeedbackIntensity intensity) {
    if (!widget.moduleContext.feedbackEnabled || !_pageVisible) return;
    unawaited(widget.moduleContext.feedbackService.emit(intensity));
  }

  void _completeImmediately() {
    final result = _frozenResult;
    if (_frozenSession == null || result == null) return;
    _timeline++;
    _cancelMotionWait();
    setState(() {
      _revealedCount = _drawnCards.length;
      _phase = GenerationPhase.completed;
      _busy = false;
      _settleResult = false;
    });
  }

  void _resetReading() {
    if (_restoring || _busy) return;
    final parentSessionId = _frozenSession?.id ?? _nextParentSessionId;
    _timeline++;
    _cancelMotionWait();
    setState(() {
      _nextParentSessionId = parentSessionId;
      _frozenSession = null;
      _frozenResult = null;
      _drawnCards.clear();
      _generationError = null;
      _phase = GenerationPhase.ready;
      _busy = false;
      _settleResult = false;
      _revealedCount = 0;
    });
  }

  Future<void> _performPrimaryAction() async {
    if (_busy || _intentionError != null) return;
    _interactionStarted = true;
    final parentSessionId = _frozenSession?.id;
    await _generate(parentSessionId: parentSessionId);
  }

  Future<void> _performDeckAction() => _performPrimaryAction();

  Future<void> _showInterpretation(int index) async {
    final result = _displayResult;
    if (result == null || index < 0 || index >= result.cards.length) return;
    final drawn = result.cards[index];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => TarotInterpretationSheet(
        interpretationIndex: index,
        interpretation: const TarotInterpretationComposer().resolve(drawn),
        useReversals: result.config.useReversals,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppToolTheme(
    accent: ToolAccent.tarot,
    child: AppToolScaffold(
      title: '塔罗',
      subtitle: '抽取结果会先冻结并保存，再逐张揭示原创结构化解释。',
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
    final displayResult = _displayResult;
    final count = displayResult?.cards.length ?? _config.drawCount;
    final settled =
        result != null &&
        (_phase == GenerationPhase.completed ||
            _phase == GenerationPhase.reduced);
    final label = result == null
        ? '塔罗牌堆，当前牌阵需要 $count 张牌'
        : settled
        ? '塔罗牌面，$count 张牌的结果已冻结并保存'
        : '塔罗牌堆，$count 张牌的结果已冻结，牌面尚未全部揭示';
    final showResult = displayResult != null;
    return AppEntityStateView(
      key: const Key('tarot-core-entity'),
      phase: _phase,
      phaseLabel: _phaseLabel,
      semanticLabel: label,
      error: _generationError,
      onActivate: null,
      affordanceHint: _busy
          ? '正在揭示已冻结结果，请等待完成或跳过动画'
          : result == null
          ? '点击牌堆抽牌'
          : '点击牌堆再抽一张；点击牌面查看释义',
      child: Center(
        child: showResult
            ? TarotResultView(
                key: ValueKey<String>('core-${_frozenSession?.id ?? 'draft'}'),
                result: displayResult,
                revealedCount: _revealedCount,
                animateAll:
                    _phase == GenerationPhase.revealing &&
                    result!.config.revealMode == TarotRevealMode.allAtOnce,
                reducedMotion:
                    widget.moduleContext.reduceMotion ||
                    _phase == GenerationPhase.reduced,
                settle: _phase == GenerationPhase.completed && _settleResult,
                showSupplementalContent: settled,
                onRevealNext: null,
                onCardTap: _showInterpretation,
                animateIndex:
                    _phase == GenerationPhase.revealing && _revealedCount > 0
                    ? _revealedCount - 1
                    : null,
                deckFocusNode: _deckFocusNode,
                onDeckTap: _busy ? null : _performDeckAction,
              )
            : AppPhysicalDeck(
                key: const Key('tarot-deck'),
                label: _busy ? '塔罗牌堆，当前不可操作' : '塔罗牌堆，点击抽一张牌',
                hint: '点击抽一张牌',
                onTap: _busy ? null : _performDeckAction,
                focusNode: _deckFocusNode,
                child: const TarotDeckStack(),
              ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Align(
      alignment: Alignment.centerRight,
      child: AppButton(
        key: const Key('reset-tarot-button'),
        label: '重置',
        variant: AppButtonVariant.quiet,
        semanticLabel: '重置塔罗牌局，保留当前设置',
        onPressed: _restoring || _busy ? null : _resetReading,
        leading: Icons.refresh,
      ),
    );
  }

  Widget _buildAdvancedOptions(BuildContext context) {
    final config = _config;
    return AppSectionCard(
      key: const Key('tarot-advanced-options-card'),
      child: ExpansionTile(
        key: const Key('tarot-advanced-options'),
        initiallyExpanded: false,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
        title: const Text('高级选项'),
        subtitle: Text(tarotReadingSummary(config)),
        children: <Widget>[
          AppChoiceGroup<TarotSpreadPreset>(
            key: const Key('tarot-spread-choice'),
            label: '牌阵',
            choices: const <AppChoice<TarotSpreadPreset>>[
              AppChoice(value: TarotSpreadPreset.dailyCard, label: '今日一牌'),
              AppChoice(value: TarotSpreadPreset.singleQuestion, label: '单牌问答'),
              AppChoice(
                value: TarotSpreadPreset.pastPresentFuture,
                label: '过去／现在／未来',
              ),
            ],
            selected: _spread,
            enabled: !_configurationLocked,
            onSelected: (value) => setState(() => _spread = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '固定位置：${config.positions.map(tarotPositionLabel).join(' → ')}',
            key: const Key('tarot-position-summary'),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            key: const Key('tarot-intention-field'),
            controller: _intentionController,
            enabled: !_configurationLocked,
            maxLength: TarotReadingConfig.maximumIntentionLength,
            maxLines: AppSizes.intentionFieldMaxLines,
            decoration: InputDecoration(
              labelText: '问题或备注（可选）',
              helperText: '仅保存在本机，请避免填写个人敏感信息',
              errorText: _intentionError,
            ),
            onChanged: (value) => setState(() => _intention = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile(
            key: const Key('tarot-reversals-switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('使用逆位'),
            subtitle: const Text('默认开启；每张牌独立决定方向'),
            value: _useReversals,
            onChanged: _configurationLocked
                ? null
                : (value) => setState(() => _useReversals = value),
          ),
          SwitchListTile(
            key: const Key('tarot-minor-arcana-switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('使用小阿卡纳'),
            subtitle: const Text('默认开启；关闭后仅从 22 张大阿卡那中抽牌'),
            value: _includeMinorArcana,
            onChanged: _configurationLocked
                ? null
                : (value) => setState(() => _includeMinorArcana = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSegmentedControl<TarotRevealMode>(
            key: const Key('tarot-reveal-mode'),
            label: '揭示方式',
            segments: const <AppSegment<TarotRevealMode>>[
              AppSegment(value: TarotRevealMode.sequential, label: '逐张揭示'),
              AppSegment(value: TarotRevealMode.allAtOnce, label: '一次揭示'),
            ],
            selected: _revealMode,
            enabled: !_configurationLocked,
            onSelected: (value) => setState(() => _revealMode = value),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            tarotReadingSummary(config),
            key: const Key('tarot-config-summary'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildOutcome(BuildContext context) {
    final result = _frozenResult;
    final showResult =
        result != null &&
        (_phase == GenerationPhase.revealing ||
            _phase == GenerationPhase.completed ||
            _phase == GenerationPhase.reduced);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!showResult && _phase != GenerationPhase.generating) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          AppSectionCard(
            child: Text(
              _restoring
                  ? '正在恢复本机保存的塔罗会话。'
                  : result == null
                  ? '选择牌阵后即可抽牌；动画不会访问随机源。'
                  : '结果已冻结保存，等待揭示。',
            ),
          ),
        ],
        if (_busy && result != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          const AppSectionCard(child: Text('跳过、隐藏或重新进入都会恢复同一已冻结结果')),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const Key('skip-tarot-animation-button'),
            label: '跳过动画',
            variant: AppButtonVariant.quiet,
            onPressed: _completeImmediately,
            expand: true,
          ),
        ],
        if (result != null &&
            (_phase == GenerationPhase.completed ||
                _phase == GenerationPhase.reduced)) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          const AppSectionCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.info_outline),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('再次抽牌会创建关联的新会话，不修改当前结果')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSessionActions(
            session: _frozenSession,
            controller: widget.moduleContext.sessionActions,
            regenerateKey: const Key('redraw-tarot-button'),
            regenerateLabel: '再次抽牌',
            regenerateEnabled: !_busy,
            onRegenerate: () => _generate(parentSessionId: _frozenSession!.id),
          ),
        ],
      ],
    );
  }

  String get _phaseLabel => switch (_phase) {
    GenerationPhase.ready => '准备就绪',
    GenerationPhase.pressed => '牌阵设置已冻结',
    GenerationPhase.generating => '结果已冻结保存，正在准备牌背',
    GenerationPhase.revealing => '新牌正在翻面并落位',
    GenerationPhase.completed => '牌阵与原创解释已完成',
    GenerationPhase.reduced => '减少动态：新牌已直接落位',
  };
}
