import 'package:flutter/material.dart';

import '../../../core/session/session.dart';
import '../../../core/tools/tool_module.dart';
import '../../../core/tools/tool_session_adapter.dart';
import '../domain/card_models.dart';
import 'card_labels.dart';
import 'card_session_codec.dart';
import 'card_session_id_source.dart';
import 'card_tool_page.dart';

final class CardToolModule implements ToolModule, ToolSessionAdapterProvider {
  factory CardToolModule({
    SessionRepository? sessionRepository,
    CardSessionIdSource? sessionIdSource,
  }) => CardToolModule._(sessionRepository, sessionIdSource);

  CardToolModule._(this._sessionRepository, this._sessionIdSource)
    : toolSessionAdapter = ToolSessionAdapter(
        descriptor: _descriptor,
        codec: const CardSessionCodec(),
        shareRenderer: _renderSharePayload,
      );

  static const _descriptor = ToolDescriptor(
    id: 'cards',
    name: '抽扑克牌',
    description: '支持 1～10 副 52/54 张牌组，无放回按序抽取',
    route: '/tools/cards',
    icon: Icons.style_outlined,
    accent: ToolAccent.cards,
  );

  final SessionRepository? _sessionRepository;
  final CardSessionIdSource? _sessionIdSource;

  SessionRepository get sessionRepository =>
      _sessionRepository ??
      (throw StateError('CardToolModule requires an app session repository.'));

  CardSessionIdSource get sessionIdSource =>
      _sessionIdSource ??
      (throw StateError('CardToolModule requires an app session ID source.'));

  @override
  final ToolSessionAdapter toolSessionAdapter;

  @override
  ToolDescriptor get descriptor => _descriptor;

  @override
  ToolSessionCodec get sessionCodec => toolSessionAdapter.codec;

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) {
    final launch = moduleContext.launchRequest;
    return CardToolPage(
      moduleContext: moduleContext,
      sessionRepository: sessionRepository,
      sessionAdapter: toolSessionAdapter,
      sessionIdSource: sessionIdSource,
      initialConfig: launch?.toolId == descriptor.id
          ? launch?.initialConfig as CardDrawConfig?
          : null,
      initialParentSessionId: launch?.toolId == descriptor.id
          ? launch?.parentSessionId
          : null,
    );
  }

  static ToolSharePayload _renderSharePayload(
    ToolDescriptor descriptor,
    SessionRecord session,
    String summary,
  ) {
    const codec = CardSessionCodec();
    final config = codec.decodeInput(session.input);
    final result = codec.decodeOutcome(session.outcome, config);
    return ToolSharePayload(
      title: descriptor.name,
      summary: summary,
      plainText: <String>[
        '万象匣 · ${descriptor.name}',
        cardDeckSummary(config),
        for (var index = 0; index < result.cards.length; index++)
          '#${index + 1} ${playingCardLabel(result.cards[index])}',
        '剩余 ${result.remainingCount} 张',
        '规则版本：${session.ruleVersion}',
        '算法版本：${session.algorithmVersion}',
      ].join('\n'),
    );
  }
}
