import '../../core/session/session.dart';
import '../../core/session/session_id_source.dart';
import '../../core/tools/tool_module.dart';
import '../../core/tools/tool_registry.dart';
import '../../features/cards/presentation/card_tool_module.dart';
import '../../features/coin/presentation/coin_tool_module.dart';
import '../../features/dice/presentation/dice_tool_module.dart';
import '../../features/encyclopedia/presentation/encyclopedia_tool_module.dart';
import '../../features/liuyao/presentation/liuyao_tool_module.dart';
import '../../features/multi_divination/presentation/multi_divination_tool_module.dart';
import '../../features/tarot/presentation/tarot_tool_module.dart';

ToolRegistry buildDefaultToolRegistry({
  SessionRepository? sessionRepository,
  SessionIdSource? sessionIdSource,
}) => ToolRegistry(<ToolModule>[
  TarotToolModule().configured(
    sessionRepository: sessionRepository,
    sessionIdSource: sessionIdSource,
  ),
  LiuyaoToolModule().configured(
    sessionRepository: sessionRepository,
    sessionIdSource: sessionIdSource,
  ),
  DiceToolModule(
    sessionRepository: sessionRepository,
    sessionIdSource: sessionIdSource,
  ),
  CoinToolModule(
    sessionRepository: sessionRepository,
    sessionIdSource: sessionIdSource,
  ),
  CardToolModule(
    sessionRepository: sessionRepository,
    sessionIdSource: sessionIdSource,
  ),
  MultiDivinationToolModule(
    sessionRepository: sessionRepository,
    sessionIdSource: sessionIdSource,
  ),
  const EncyclopediaToolModule(),
]);
