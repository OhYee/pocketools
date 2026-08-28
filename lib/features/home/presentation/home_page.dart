import 'package:flutter/material.dart';

import '../../../core/tools/tool_module.dart';
import '../../../core/tools/tool_registry.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/components/app_surfaces.dart';
import '../../../design_system/components/app_brand_header.dart';
import '../../../design_system/components/app_tool_card.dart';
import '../../../design_system/components/app_tool_scaffold.dart';

/// Registry-driven tool home. Adding a module changes this page through
/// registry data rather than a feature-specific branch or duplicated style.
final class HomePage extends StatelessWidget {
  const HomePage({required this.registry, required this.onOpenTool, super.key});

  final ToolRegistry registry;
  final ValueChanged<ToolModule> onOpenTool;

  @override
  Widget build(BuildContext context) => AppToolScaffold(
    title: '今天想用哪个工具？',
    subtitle: '本地模式 · 核心随机过程不依赖网络',
    primary: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppBrandHeader(),
        const SizedBox(height: AppSpacing.xl),
        for (final module in registry.modules) ...<Widget>[
          AppToolCard(
            key: ValueKey<String>('home-tool-${module.descriptor.id}'),
            descriptor: module.descriptor,
            onPressed: () => onOpenTool(module),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const AppSectionCard(
          child: Row(
            children: <Widget>[
              Icon(Icons.storage_outlined),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('本地模式 · 数据仅存于本机')),
              Icon(Icons.check_circle_outline),
            ],
          ),
        ),
      ],
    ),
  );
}
