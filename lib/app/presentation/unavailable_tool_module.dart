import 'package:flutter/material.dart';

import '../../core/session/session.dart';
import '../../core/tools/tool_module.dart';
import '../../design_system/components/app_surfaces.dart';
import '../../design_system/components/app_tool_scaffold.dart';

final class UnavailableToolModule implements ToolModule {
  const UnavailableToolModule(this.descriptor);

  @override
  final ToolDescriptor descriptor;

  @override
  ToolSessionCodec get sessionCodec => PlaceholderSessionCodec(descriptor.id);

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      AppToolScaffold(
        title: descriptor.name,
        subtitle: descriptor.description,
        onBack: moduleContext.onBack,
        primary: const AppSectionCard(
          child: Text('设计完善中。本阶段未开放生成能力，也不会消耗随机值。'),
        ),
      );
}

final class PlaceholderSessionCodec implements ToolSessionCodec {
  const PlaceholderSessionCodec(this.toolId);

  @override
  final String toolId;

  @override
  Map<String, Object?> encodeInput(Object input) =>
      Map<String, Object?>.unmodifiable(input as Map<String, Object?>);

  @override
  Map<String, Object?> decodeInput(Map<String, Object?> input) => input;

  @override
  Map<String, Object?> encodeOutcome(Object outcome) =>
      Map<String, Object?>.unmodifiable(outcome as Map<String, Object?>);

  @override
  Map<String, Object?> decodeOutcome(
    Map<String, Object?> outcome,
    Object input,
  ) => outcome;

  @override
  String summarize(SessionRecord session) => '未开放的工具结果';
}
