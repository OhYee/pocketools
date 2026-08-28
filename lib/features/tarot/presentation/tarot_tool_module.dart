import 'package:flutter/material.dart';

import '../../../core/session/session.dart';
import '../../../core/presets/preset.dart';
import '../../../core/presets/preset_capabilities.dart';
import '../../../core/tools/tool_module.dart';
import '../../../core/tools/tool_capabilities.dart';
import '../../../core/tools/tool_session_adapter.dart';
import '../content/tarot_content_catalog.dart';
import '../domain/tarot_models.dart';
import '../domain/tarot_reader.dart';
import 'tarot_labels.dart';
import 'tarot_session_codec.dart';
import 'tarot_session_id_source.dart';
import 'tarot_tool_page.dart';

final class TarotToolModule
    with ToolPrivacyCapabilities
    implements ToolModule, ToolSessionAdapterProvider, ToolPresetProvider {
  factory TarotToolModule({
    SessionRepository? sessionRepository,
    TarotSessionIdSource? sessionIdSource,
  }) => TarotToolModule._(sessionRepository, sessionIdSource);

  TarotToolModule._(this._sessionRepository, this._sessionIdSource)
    : toolSessionAdapter = ToolSessionAdapter(
        descriptor: _descriptor,
        codec: const TarotSessionCodec(),
        shareRenderer: _renderSharePayload,
      );

  TarotToolModule configured({
    required SessionRepository? sessionRepository,
    required TarotSessionIdSource? sessionIdSource,
  }) => TarotToolModule(
    sessionRepository: sessionRepository,
    sessionIdSource: sessionIdSource,
  );

  static const _descriptor = ToolDescriptor(
    id: 'tarot',
    name: '塔罗',
    description: '今日一牌、单牌问答与过去／现在／未来',
    route: '/tools/tarot',
    icon: Icons.auto_awesome_outlined,
    accent: ToolAccent.tarot,
  );

  final SessionRepository? _sessionRepository;
  final TarotSessionIdSource? _sessionIdSource;

  SessionRepository get sessionRepository =>
      _sessionRepository ??
      (throw StateError('TarotToolModule requires an app session repository.'));

  TarotSessionIdSource get sessionIdSource =>
      _sessionIdSource ??
      (throw StateError('TarotToolModule requires an app session ID source.'));

  @override
  final ToolSessionAdapter toolSessionAdapter;

  @override
  ToolDescriptor get descriptor => _descriptor;

  @override
  ToolSessionCodec get sessionCodec => toolSessionAdapter.codec;

  @override
  String get toolId => descriptor.id;

  static final List<ToolPreset> _systemPresets = List<ToolPreset>.unmodifiable(
    <ToolPreset>[
      ToolPreset(
        id: 'tarot.daily-card',
        toolId: _descriptor.id,
        displayName: '今日一牌',
        ruleVersion: TarotReader.ruleVersion,
        type: PresetType.system,
        source: PresetSource.bundled,
        configuration: const <String, Object?>{
          'spread': 'dailyCard',
          'includeMinorArcana': true,
          'useReversals': true,
          'revealMode': 'sequential',
        },
      ),
      ToolPreset(
        id: 'tarot.single-question',
        toolId: _descriptor.id,
        displayName: '单牌问答',
        ruleVersion: TarotReader.ruleVersion,
        type: PresetType.system,
        source: PresetSource.bundled,
        configuration: const <String, Object?>{
          'spread': 'singleQuestion',
          'includeMinorArcana': true,
          'useReversals': true,
          'revealMode': 'sequential',
        },
      ),
      ToolPreset(
        id: 'tarot.past-present-future',
        toolId: _descriptor.id,
        displayName: '过去／现在／未来',
        ruleVersion: TarotReader.ruleVersion,
        type: PresetType.system,
        source: PresetSource.bundled,
        configuration: const <String, Object?>{
          'spread': 'pastPresentFuture',
          'includeMinorArcana': true,
          'useReversals': true,
          'revealMode': 'sequential',
        },
      ),
    ],
  );

  @override
  List<ToolPreset> get systemPresets => _systemPresets;

  @override
  Object decodePresetConfiguration(Map<String, Object?> configuration) {
    final payload = <String, Object?>{...configuration};
    if (!payload.containsKey('includeMinorArcana')) {
      payload['includeMinorArcana'] = true;
    }
    const expectedKeys = <String>{
      'spread',
      'includeMinorArcana',
      'useReversals',
      'revealMode',
    };
    if (payload.keys.toSet().difference(expectedKeys).isNotEmpty ||
        payload.length != expectedKeys.length) {
      throw const PresetConfigurationException('塔罗预设字段不完整或包含未知字段。');
    }
    final spreadName = payload['spread'];
    final revealModeName = payload['revealMode'];
    final spreads = TarotSpreadPreset.values.where(
      (value) => value.name == spreadName,
    );
    final revealModes = TarotRevealMode.values.where(
      (value) => value.name == revealModeName,
    );
    if (payload['includeMinorArcana'] is! bool ||
        payload['useReversals'] is! bool ||
        spreads.length != 1 ||
        revealModes.length != 1) {
      throw const PresetConfigurationException('塔罗预设规则配置无效。');
    }
    return TarotReadingConfig(
      spread: spreads.single,
      includeMinorArcana: payload['includeMinorArcana']! as bool,
      useReversals: payload['useReversals']! as bool,
      revealMode: revealModes.single,
      intention: null,
    );
  }

  @override
  Map<String, Object?> encodePresetConfiguration(Object configuration) {
    if (configuration is! TarotReadingConfig) {
      throw const PresetConfigurationException('不是有效的塔罗输入模型。');
    }
    final normalized = configuration.normalized(includeIntention: false);
    return <String, Object?>{
      'spread': normalized.spread.name,
      'includeMinorArcana': normalized.includeMinorArcana,
      'useReversals': normalized.useReversals,
      'revealMode': normalized.revealMode.name,
    };
  }

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) {
    final launch = moduleContext.launchRequest;
    return TarotToolPage(
      moduleContext: moduleContext,
      sessionRepository: sessionRepository,
      sessionAdapter: toolSessionAdapter,
      sessionIdSource: sessionIdSource,
      initialConfig: launch?.toolId == descriptor.id
          ? launch?.initialConfig as TarotReadingConfig?
          : null,
      initialParentSessionId: launch?.toolId == descriptor.id
          ? launch?.parentSessionId
          : null,
    );
  }

  @override
  Object replayInput(SessionRecord session, DecodedToolSession decoded) =>
      (decoded.input as TarotReadingConfig).normalized(includeIntention: false);

  @override
  List<ToolOptionalShareField> optionalShareFields(
    SessionRecord session,
    DecodedToolSession decoded,
  ) {
    final intention = (decoded.input as TarotReadingConfig).normalizedIntention;
    if (intention == null) return const <ToolOptionalShareField>[];
    return <ToolOptionalShareField>[
      ToolOptionalShareField(id: 'intention', label: '问题或意图', value: intention),
    ];
  }

  static ToolSharePayload _renderSharePayload(
    ToolDescriptor descriptor,
    SessionRecord session,
    String summary,
  ) {
    const codec = TarotSessionCodec();
    final config = codec.decodeInput(session.input);
    final result = codec.decodeOutcome(session.outcome, config);
    const composer = TarotInterpretationComposer();
    final interpretations = composer.resolveReading(result);
    final lines = <String>[
      'Pocketools · ${descriptor.name}',
      tarotReadingSummary(config),
      for (final interpretation in interpretations)
        '${tarotPositionLabel(interpretation.drawnCard.position)}：'
            '${interpretation.drawnCard.card.name}'
            '（${tarotOrientationLabel(interpretation.drawnCard.orientation)}）'
            ' · ${interpretation.keywords.take(3).join('、')}\n'
            '简短解读：${interpretation.currentDirectionMeaning}',
      ?composer.combinationHint(result),
      '规则版本：${session.ruleVersion}',
      '算法版本：${session.algorithmVersion}',
    ];
    return ToolSharePayload(
      title: descriptor.name,
      summary: summary,
      plainText: lines.join('\n'),
    );
  }
}
