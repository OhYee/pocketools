import 'package:flutter/material.dart';

import '../../../core/session/session.dart';
import '../../../core/tools/tool_module.dart';
import '../../../core/tools/tool_capabilities.dart';
import '../../../core/tools/tool_session_adapter.dart';
import '../domain/liuyao_caster.dart';
import '../domain/liuyao_hexagrams.dart';
import '../domain/liuyao_models.dart';
import 'liuyao_labels.dart';
import 'liuyao_session_codec.dart';
import 'liuyao_session_id_source.dart';
import 'liuyao_tool_page.dart';

final class LiuyaoToolModule
    with ToolPrivacyCapabilities
    implements ToolModule, ToolSessionAdapterProvider {
  factory LiuyaoToolModule({
    SessionRepository? sessionRepository,
    LiuyaoSessionIdSource? sessionIdSource,
  }) => LiuyaoToolModule._(sessionRepository, sessionIdSource);

  LiuyaoToolModule._(this._sessionRepository, this._sessionIdSource)
    : toolSessionAdapter = ToolSessionAdapter(
        descriptor: _descriptor,
        codec: const LiuyaoSessionCodec(),
        shareRenderer: _renderSharePayload,
      );

  LiuyaoToolModule configured({
    required SessionRepository? sessionRepository,
    required LiuyaoSessionIdSource? sessionIdSource,
  }) => LiuyaoToolModule(
    sessionRepository: sessionRepository,
    sessionIdSource: sessionIdSource,
  );

  static const _descriptor = ToolDescriptor(
    id: 'liuyao',
    name: '六爻起卦',
    description: '三枚硬币或手工录入，追溯本卦与变卦',
    route: '/tools/liuyao',
    icon: Icons.reorder,
    accent: ToolAccent.liuyao,
  );

  final SessionRepository? _sessionRepository;
  final LiuyaoSessionIdSource? _sessionIdSource;

  SessionRepository get sessionRepository =>
      _sessionRepository ??
      (throw StateError(
        'LiuyaoToolModule requires an app session repository.',
      ));

  LiuyaoSessionIdSource get sessionIdSource =>
      _sessionIdSource ??
      (throw StateError('LiuyaoToolModule requires an app session ID source.'));

  @override
  final ToolSessionAdapter toolSessionAdapter;

  @override
  ToolDescriptor get descriptor => _descriptor;

  @override
  ToolSessionCodec get sessionCodec => toolSessionAdapter.codec;

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) {
    final launch = moduleContext.launchRequest;
    return LiuyaoToolPage(
      moduleContext: moduleContext,
      sessionRepository: sessionRepository,
      sessionAdapter: toolSessionAdapter,
      sessionIdSource: sessionIdSource,
      initialConfig: launch?.toolId == descriptor.id
          ? launch?.initialConfig as LiuyaoConfig?
          : null,
      initialParentSessionId: launch?.toolId == descriptor.id
          ? launch?.parentSessionId
          : null,
    );
  }

  @override
  Object replayInput(SessionRecord session, DecodedToolSession decoded) =>
      (decoded.input as LiuyaoConfig).normalized(includeIntention: false);

  @override
  List<ToolOptionalShareField> optionalShareFields(
    SessionRecord session,
    DecodedToolSession decoded,
  ) {
    final intention = (decoded.input as LiuyaoConfig).normalizedIntention;
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
    const codec = LiuyaoSessionCodec();
    final config = codec.decodeInput(session.input);
    final reading = codec.decodeOutcome(session.outcome, config);
    final lines = <String>[
      '万象匣 · ${descriptor.name}',
      summary,
      '方式：${liuyaoModeLabel(config.mode)}',
      for (final line in reading.lines)
        '${liuyaoLinePositionLabel(line.index)}：和值 ${line.value} · '
            '${liuyaoLineKindLabel(line.kind)} · '
            '${line.isMoving ? '动爻' : '静爻'}'
            '${line.coins == null ? '' : ' · ${line.coins!.map(liuyaoCoinLabel).join('、')}'}',
    ];
    if (reading.isComplete) {
      final primary = LiuyaoHexagrams.resolve(reading.lines);
      lines.add(
        '本卦：第 ${primary.kingWenNumber} 卦 ${primary.name} · '
        '上${primary.upper.name}下${primary.lower.name}',
      );
      if (reading.movingLineIndexes.isEmpty) {
        lines.add('无动爻，本卦不变。');
      } else {
        final changed = LiuyaoHexagrams.resolve(reading.lines, changed: true);
        lines.add(
          '变卦：第 ${changed.kingWenNumber} 卦 ${changed.name} · '
          '动爻 ${reading.movingLineIndexes.map((index) => index + 1).join('、')}',
        );
      }
    }
    lines.addAll(<String>[
      '规则版本：${session.ruleVersion}',
      '算法版本：${session.algorithmVersion}',
    ]);
    return ToolSharePayload(
      title: descriptor.name,
      summary: summary,
      plainText: lines.join('\n'),
    );
  }

  static String algorithmVersionFor(LiuyaoMode mode) =>
      mode == LiuyaoMode.automatic
      ? LiuyaoCaster.automaticAlgorithmVersion
      : LiuyaoCaster.manualAlgorithmVersion;
}
