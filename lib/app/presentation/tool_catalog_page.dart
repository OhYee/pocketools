import 'package:flutter/material.dart';

import '../../core/tools/tool_module.dart';
import '../../core/tools/tool_registry.dart';
import '../../design_system/app_tokens.dart';
import '../../design_system/components/app_tool_card.dart';
import '../../design_system/components/app_tool_scaffold.dart';

final class ToolCatalogPage extends StatelessWidget {
  const ToolCatalogPage({
    required this.registry,
    required this.onOpenTool,
    super.key,
  });

  final ToolRegistry registry;
  final ValueChanged<ToolModule> onOpenTool;

  @override
  Widget build(BuildContext context) => AppToolScaffold(
    title: '工具',
    subtitle: '选择一个工具开始。未完成模块会明确标记状态。',
    primary: Column(
      children: <Widget>[
        for (final module in registry.modules) ...<Widget>[
          AppToolCard(
            descriptor: module.descriptor,
            onPressed: () => onOpenTool(module),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    ),
  );
}
