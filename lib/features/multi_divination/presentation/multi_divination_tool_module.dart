import 'package:flutter/material.dart';

import '../../../core/session/session.dart';
import '../../../core/session/session_id_source.dart';
import '../../../core/tools/tool_capabilities.dart';
import '../../../core/tools/tool_module.dart';
import '../../../core/tools/tool_session_adapter.dart';
import '../../liuyao/presentation/liuyao_labels.dart';
import '../../tarot/presentation/tarot_labels.dart';
import '../domain/multi_divination_models.dart';
import 'multi_divination_labels.dart';
import 'multi_divination_session_codec.dart';
import 'multi_divination_tool_page.dart';

final class MultiDivinationToolModule
    with ToolPrivacyCapabilities
    implements ToolModule, ToolSessionAdapterProvider {
  factory MultiDivinationToolModule({
    SessionRepository? sessionRepository,
    SessionIdSource? sessionIdSource,
  }) => MultiDivinationToolModule._(sessionRepository, sessionIdSource);

  MultiDivinationToolModule._(this._sessionRepository, this._sessionIdSource)
    : toolSessionAdapter = ToolSessionAdapter(
        descriptor: _descriptor,
        codec: const MultiDivinationSessionCodec(),
        shareRenderer: _renderSharePayload,
      );

  MultiDivinationToolModule configured({
    required SessionRepository? sessionRepository,
    required SessionIdSource? sessionIdSource,
  }) => MultiDivinationToolModule(
    sessionRepository: sessionRepository,
    sessionIdSource: sessionIdSource,
  );

  static const _descriptor = ToolDescriptor(
    id: 'multi_divination',
    name: '多重占卜',
    description: '三张塔罗融合一爻，六组形成卦象与 A1-A6 线索',
    route: '/tools/multi_divination',
    icon: Icons.auto_awesome_outlined,
    accent: ToolAccent.neutral,
  );

  final SessionRepository? _sessionRepository;
  final SessionIdSource? _sessionIdSource;

  SessionRepository get sessionRepository =>
      _sessionRepository ??
      (throw StateError(
        'MultiDivinationToolModule requires an app session repository.',
      ));

  SessionIdSource get sessionIdSource =>
      _sessionIdSource ??
      (throw StateError(
        'MultiDivinationToolModule requires an app session ID source.',
      ));

  @override
  final ToolSessionAdapter toolSessionAdapter;

  @override
  ToolDescriptor get descriptor => _descriptor;

  @override
  ToolSessionCodec get sessionCodec => toolSessionAdapter.codec;

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) {
    final launch = moduleContext.launchRequest;
    return MultiDivinationToolPage(
      moduleContext: moduleContext,
      sessionRepository: sessionRepository,
      sessionAdapter: toolSessionAdapter,
      sessionIdSource: sessionIdSource,
      initialConfig: launch?.toolId == descriptor.id
          ? launch?.initialConfig as MultiDivinationConfig?
          : null,
      initialParentSessionId: launch?.toolId == descriptor.id
          ? launch?.parentSessionId
          : null,
    );
  }

  @override
  Object replayInput(SessionRecord session, DecodedToolSession decoded) {
    final config = decoded.input;
    if (config is! MultiDivinationConfig) {
      throw const FormatException(
        'Multi-divination replay input has an invalid type.',
      );
    }
    return config.normalized(includeIntention: false);
  }

  @override
  List<ToolOptionalShareField> optionalShareFields(
    SessionRecord session,
    DecodedToolSession decoded,
  ) {
    final input = decoded.input;
    if (input is! MultiDivinationConfig || input.normalizedIntention == null) {
      return const <ToolOptionalShareField>[];
    }
    return <ToolOptionalShareField>[
      ToolOptionalShareField(
        id: 'intention',
        label: '问题或意图',
        value: input.normalizedIntention!,
      ),
    ];
  }

  static ToolSharePayload _renderSharePayload(
    ToolDescriptor descriptor,
    SessionRecord session,
    String summary,
  ) {
    const codec = MultiDivinationSessionCodec();
    final config = codec.decodeInput(session.input);
    final reading = codec.decodeOutcome(session.outcome, config);
    final lines = <String>[
      'Pocketools · ${descriptor.name}',
      summary,
      '方式：${multiDivinationModeLabel(config.mode)}',
      for (final group in reading.groups)
        '${multiDivinationGroupLabel(group.index)}：'
            'A ${group.primaryCard.card.name}（${tarotOrientationLabel(group.primaryCard.orientation)}） · '
            'B/C 为随机输入 · ${liuyaoLineKindLabel(group.lineKind)} · '
            '${group.isMoving ? '动爻' : '静爻'}',
      if (reading.isComplete)
        '本卦：第 ${reading.primaryHexagram!.kingWenNumber} 卦 '
            '${reading.primaryHexagram!.name}',
      if (reading.movingLineIndexes.isEmpty && reading.isComplete) '动爻：无 · 变卦无',
      if (reading.movingLineIndexes.isNotEmpty && reading.isComplete)
        '动爻：${reading.movingLineIndexes.map((index) => index + 1).join('、')} · '
            '变卦：第 ${reading.changedHexagram!.kingWenNumber} 卦 '
            '${reading.changedHexagram!.name}',
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
