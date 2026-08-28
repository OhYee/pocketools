import 'package:flutter/material.dart';

import '../../../core/session/session.dart';
import '../../../core/tools/tool_module.dart';
import 'encyclopedia_session_codec.dart';
import 'encyclopedia_tool_page.dart';

final class EncyclopediaToolModule implements ToolModule {
  const EncyclopediaToolModule();

  static const _descriptor = ToolDescriptor(
    id: 'encyclopedia',
    name: '塔罗/周易图鉴',
    description: '浏览 78 张塔罗牌与 64 卦的牌面、结构和释义',
    route: '/tools/encyclopedia',
    icon: Icons.menu_book_outlined,
    accent: ToolAccent.neutral,
  );

  @override
  ToolDescriptor get descriptor => _descriptor;

  @override
  ToolSessionCodec get sessionCodec => const EncyclopediaSessionCodec();

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      EncyclopediaToolPage(moduleContext: moduleContext);
}
