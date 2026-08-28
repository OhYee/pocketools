import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/feedback/feedback_service.dart';
import '../../../core/session/session.dart';
import '../../../core/tools/tool_module.dart';
import '../../../core/tools/tool_session_adapter.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/components/app_button.dart';
import '../../../design_system/components/app_generation_state_view.dart';
import '../../../design_system/components/app_physical_deck.dart';
import '../../../design_system/components/app_session_actions.dart';
import '../../../design_system/components/app_stepper.dart';
import '../../../design_system/components/app_surfaces.dart';
import '../../../design_system/components/app_tool_flow_layout.dart';
import '../../../design_system/components/app_tool_scaffold.dart';
import '../../../design_system/components/app_tool_theme.dart';
import '../domain/card_drawer.dart';
import '../domain/card_models.dart';
import 'card_labels.dart';
import 'card_session_id_source.dart';
import 'widgets/card_result_list.dart';
import 'widgets/playing_card_view.dart';

final class CardToolPage extends StatefulWidget {
  const CardToolPage({
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
  final CardSessionIdSource sessionIdSource;
  final CardDrawConfig? initialConfig;
  final String? initialParentSessionId;

  @override
  State<CardToolPage> createState() => _CardToolPageState();
}

final class _CardToolPageState extends State<CardToolPage>
    with WidgetsBindingObserver {
  late String _drawCount;
  late String _deckCount;
  late bool _includeJokers;
  var _phase = GenerationPhase.ready;
  var _restoring = true;
  var _interactionStarted = false;
  var _busy = false;
  var _timeline = 0;
  SessionRecord? _frozenSession;
  CardDrawResult? _frozenResult;
  final List<PlayingCard> _drawnCards = <PlayingCard>[];
  String? _generationError;
  String? _nextParentSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyConfig(widget.initialConfig ?? const CardDrawConfig(drawCount: 3));
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _busy && _frozenSession != null) {
      _completeImmediately();
    }
  }

  void _applyConfig(CardDrawConfig config) {
    _drawCount = '${config.drawCount}';
    _deckCount = '${config.deckCount}';
    _includeJokers = config.includeJokers;
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
      if (decoded.input is! CardDrawConfig ||
          decoded.outcome is! CardDrawResult) {
        throw const FormatException('Stored card session has invalid types.');
      }
      final restoredCards = _cardsInSessionOrder(latest, sessions);
      setState(() {
        _frozenSession = latest;
        _frozenResult = decoded.outcome as CardDrawResult;
        _drawnCards
          ..clear()
          ..addAll(restoredCards);
        _applyConfig(decoded.input as CardDrawConfig);
        _phase = GenerationPhase.completed;
        _restoring = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _restoring = false;
        _generationError = '已保存的扑克会话无法恢复，请检查本地数据。';
      });
    }
  }

  List<PlayingCard> _cardsInSessionOrder(
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
    final cards = <PlayingCard>[];
    final seen = <String>{};
    for (final session in chain.reversed) {
      final decoded = widget.sessionAdapter.decode(session);
      final result = decoded.outcome as CardDrawResult;
      for (final card in result.cards) {
        if (seen.add(card.id)) cards.add(card);
      }
    }
    return cards;
  }

  int get _effectiveDeckCount {
    final value = int.tryParse(_deckCount);
    if (value == null || value < CardDrawConfig.minimumDeckCount) {
      return CardDrawConfig.minimumDeckCount;
    }
    return value;
  }

  int get _deckSize => (_includeJokers ? 54 : 52) * _effectiveDeckCount;

  String? get _deckCountError {
    final value = int.tryParse(_deckCount);
    if (value == null ||
        value < CardDrawConfig.minimumDeckCount ||
        value > CardDrawConfig.maximumDeckCount) {
      return '请输入 ${CardDrawConfig.minimumDeckCount}～${CardDrawConfig.maximumDeckCount} 的整数。';
    }
    return null;
  }

  String? get _drawCountError {
    final value = int.tryParse(_drawCount);
    if (value == null || value < 1 || value > _deckSize) {
      return '请输入 1～$_deckSize 的整数。';
    }
    return null;
  }

  CardDrawConfig? get _config {
    if (_drawCountError != null || _deckCountError != null) return null;
    final config = CardDrawConfig(
      drawCount: int.parse(_drawCount),
      deckCount: int.parse(_deckCount),
      includeJokers: _includeJokers,
    );
    return config.validate().isEmpty ? config : null;
  }

  bool get _configurationLocked => _restoring;

  CardDrawResult? get _displayResult {
    final result = _frozenResult;
    if (result == null || _drawnCards.length == result.cards.length) {
      return result;
    }
    return CardDrawResult(config: result.config, cards: _drawnCards);
  }

  void _setIncludeJokers(bool value) {
    setState(() {
      _includeJokers = value;
      final count = int.tryParse(_drawCount);
      if (count != null && count > _deckSize) {
        _drawCount = '$_deckSize';
      }
    });
  }

  void _setDeckCount(String value) {
    setState(() {
      _deckCount = value;
      final count = int.tryParse(_drawCount);
      if (count != null && count > _deckSize) {
        _drawCount = '$_deckSize';
      }
    });
  }

  Future<void> _generate({
    String? parentSessionId,
    CardDrawConfig? configOverride,
  }) async {
    final requestedConfig = configOverride ?? _config;
    if (_busy || requestedConfig == null) return;
    final config = _drawnCards.length >= requestedConfig.drawCount
        ? CardDrawConfig(
            drawCount: 1,
            deckCount: requestedConfig.deckCount,
            includeJokers: requestedConfig.includeJokers,
          )
        : requestedConfig;
    final motion = context.appMotion;
    final hadFrozenResult = _frozenResult != null;
    late final String sessionId;
    try {
      sessionId = widget.sessionIdSource.next();
    } on Object {
      setState(() {
        _generationError = '安全会话标识不可用，未创建或揭示扑克结果。';
        _phase = hadFrozenResult
            ? GenerationPhase.completed
            : GenerationPhase.ready;
      });
      return;
    }
    final timeline = ++_timeline;
    setState(() {
      _busy = true;
      _phase = GenerationPhase.pressed;
      _generationError = null;
    });

    late final CardDrawResult result;
    try {
      result = CardDrawResult(
        config: config,
        cards: <PlayingCard>[
          CardDrawer(widget.moduleContext.randomSource).drawOne(
            deckCount: config.deckCount,
            includeJokers: config.includeJokers,
            excluded: _drawnCards,
          ),
        ],
      );
    } on Object {
      if (!_isCurrent(timeline)) return;
      setState(() {
        _busy = false;
        _phase = hadFrozenResult
            ? GenerationPhase.completed
            : GenerationPhase.ready;
        _generationError = '当前环境无法提供安全随机源，未生成扑克结果。';
      });
      return;
    }

    late final SessionRecord session;
    try {
      session = widget.sessionAdapter.createSession(
        id: sessionId,
        schemaVersion: 1,
        ruleVersion: CardDrawer.ruleVersion,
        algorithmVersion: CardDrawer.algorithmVersion,
        status: SessionStatus.completed,
        input: config,
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
      _drawnCards.addAll(result.cards);
      _nextParentSessionId = null;
    });
    _emitFeedback(FeedbackIntensity.medium);

    if (widget.moduleContext.reduceMotion) {
      setState(() => _phase = GenerationPhase.reduced);
      await Future<void>.delayed(motion.reduced);
    } else {
      await Future<void>.delayed(motion.press);
      if (!_isCurrent(timeline)) return;
      setState(() => _phase = GenerationPhase.generating);
      await Future<void>.delayed(motion.shuffle);
      if (!_isCurrent(timeline)) return;
      setState(() => _phase = GenerationPhase.revealing);
      _emitFeedback(FeedbackIntensity.light);
      await Future<void>.delayed(motion.reveal);
    }
    if (!_isCurrent(timeline)) return;
    setState(() {
      _phase = GenerationPhase.completed;
      _busy = false;
    });
    _emitFeedback(FeedbackIntensity.light);
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
    });
  }

  void _resetReading() {
    if (_restoring || _busy) return;
    final parentSessionId = _frozenSession?.id ?? _nextParentSessionId;
    _timeline++;
    setState(() {
      _nextParentSessionId = parentSessionId;
      _frozenSession = null;
      _frozenResult = null;
      _drawnCards.clear();
      _generationError = null;
      _phase = GenerationPhase.ready;
      _busy = false;
    });
  }

  Future<void> _performPrimaryAction() async {
    if (_busy || _config == null) return;
    _interactionStarted = true;
    final previous = _frozenSession;
    await _generate(parentSessionId: previous?.id, configOverride: _config);
  }

  @override
  Widget build(BuildContext context) => AppToolTheme(
    accent: ToolAccent.cards,
    child: AppToolScaffold(
      title: '抽扑克牌',
      subtitle: '安全洗牌、无放回抽取；牌序在动画开始前冻结保存。',
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
    final showResult =
        result != null &&
        (_phase == GenerationPhase.revealing ||
            _phase == GenerationPhase.completed ||
            _phase == GenerationPhase.reduced);
    final label = result == null
        ? '当前扑克牌堆，等待抽取'
        : '${displayResult!.cards.length} 张扑克牌结果已冻结并保存';
    return AppEntityStateView(
      key: const Key('cards-core-entity'),
      phase: _phase,
      phaseLabel: _phaseLabel,
      semanticLabel: label,
      error: _generationError,
      onActivate: null,
      affordanceHint: result == null ? '点击牌堆抽一张' : '点击牌堆再抽一张',
      child: showResult
          ? CardResultList(
              deck: _buildDeck(),
              cards: displayResult!.cards,
              remainingCount: displayResult.remainingCount,
              reveal: _phase == GenerationPhase.revealing,
              reducedMotion: _phase == GenerationPhase.reduced,
              animateIndex: _phase == GenerationPhase.revealing
                  ? displayResult.cards.length - 1
                  : null,
            )
          : Center(child: _buildDeck()),
    );
  }

  Widget _buildDeck() => AppPhysicalDeck(
    key: const Key('cards-deck'),
    label: _busy ? '扑克牌堆，当前不可操作' : '扑克牌堆，点击抽一张牌',
    hint: '点击抽一张牌',
    onTap: _busy ? null : _performPrimaryAction,
    child: const CardBackStack(),
  );

  Widget _buildActionBar() {
    return Align(
      alignment: Alignment.centerRight,
      child: AppButton(
        key: const Key('reset-cards-button'),
        label: '重置',
        variant: AppButtonVariant.quiet,
        semanticLabel: '重置扑克牌局，保留当前设置',
        onPressed: _restoring || _busy ? null : _resetReading,
        leading: Icons.refresh,
      ),
    );
  }

  Widget _buildAdvancedOptions(BuildContext context) {
    final config = _config;
    final summaryConfig =
        config ??
        CardDrawConfig(
          drawCount: int.tryParse(_drawCount) ?? 1,
          deckCount: int.tryParse(_deckCount) ?? 1,
          includeJokers: _includeJokers,
        );
    return AppSectionCard(
      key: const Key('cards-advanced-options-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ExpansionTile(
            key: const Key('cards-advanced-options'),
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
            title: const Text('高级选项'),
            subtitle: Text(
              config == null ? '请修正抽取数量' : cardDeckSummary(config),
              key: const Key('card-config-summary'),
            ),
            children: <Widget>[
              AppStepper(
                key: const Key('card-deck-count-stepper'),
                label: '牌副数',
                value: _deckCount,
                minimum: CardDrawConfig.minimumDeckCount,
                maximum: CardDrawConfig.maximumDeckCount,
                errorText: _deckCountError,
                enabled: !_configurationLocked,
                onChanged: _setDeckCount,
              ),
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                key: const Key('include-jokers-switch'),
                contentPadding: EdgeInsets.zero,
                title: const Text('包含大小王'),
                subtitle: Text(_includeJokers ? '已加入小王与大王' : '默认关闭'),
                value: _includeJokers,
                onChanged: _configurationLocked ? null : _setIncludeJokers,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSectionCard(
                semanticLabel: '当前牌组摘要',
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.style_outlined),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        '标准牌组 · '
                        '${_effectiveDeckCount == 1 ? '' : '$_effectiveDeckCount 副牌 · '}'
                        '${_includeJokers ? '含大小王' : '不含大小王'} '
                        '· $_deckSize 张',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppStepper(
                key: const Key('card-draw-count-stepper'),
                label: '抽取数量',
                value: _drawCount,
                minimum: 1,
                maximum: _deckSize,
                errorText: _drawCountError,
                enabled: !_configurationLocked,
                onChanged: (value) => setState(() => _drawCount = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.radio_button_unchecked,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(child: Text('无放回，按抽取顺序展示')),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  _CardMetric(
                    label: '总牌数',
                    value: '${summaryConfig.deckSize} 张',
                  ),
                  _CardMetric(label: '本次数量', value: '$_drawCount 张'),
                  _CardMetric(
                    label: '预计剩余',
                    value: config == null
                        ? '—'
                        : '${config.deckSize - config.drawCount} 张',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutcome(BuildContext context) {
    final result = _frozenResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_busy && result != null) ...<Widget>[
          const AppSectionCard(child: Text('中断或恢复继续同一已冻结结果，不重抽')),
        ],
        if (result == null) ...<Widget>[
          AppSectionCard(
            child: Text(
              _restoring ? '正在恢复本机保存的扑克会话。' : '配置通过后即可洗牌抽取，动画不会访问随机源。',
            ),
          ),
        ],
        if (result != null && _phase == GenerationPhase.revealing) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const Key('skip-card-animation-button'),
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
          AppSessionActions(
            session: _frozenSession,
            controller: widget.moduleContext.sessionActions,
          ),
        ],
      ],
    );
  }

  String get _phaseLabel => switch (_phase) {
    GenerationPhase.ready => '准备就绪',
    GenerationPhase.pressed => '设置已冻结',
    GenerationPhase.generating => '结果已冻结，正在洗牌',
    GenerationPhase.revealing => '按冻结顺序抽牌',
    GenerationPhase.completed => '结果已完成',
    GenerationPhase.reduced => '减少动态：结果已生成',
  };
}

final class _CardMetric extends StatelessWidget {
  const _CardMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label $value',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: context.appColors.textSecondary),
        ),
      ],
    ),
  );
}
