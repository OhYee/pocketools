import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/presets/preset.dart';
import '../../core/presets/preset_controller.dart';
import '../../design_system/app_tokens.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_surfaces.dart';
import '../../design_system/components/app_tool_scaffold.dart';

final class PresetManagementPage extends StatefulWidget {
  const PresetManagementPage({
    required this.controller,
    required this.onApply,
    required this.onBack,
    super.key,
  });

  final PresetController controller;
  final ValueChanged<ToolPreset> onApply;
  final VoidCallback onBack;

  @override
  State<PresetManagementPage> createState() => _PresetManagementPageState();
}

final class _PresetManagementPageState extends State<PresetManagementPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    unawaited(widget.controller.load());
  }

  @override
  void didUpdateWidget(PresetManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
      unawaited(widget.controller.load());
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '预设管理',
    child: AppToolScaffold(
      title: '预设管理',
      subtitle: '系统预设只读；修改系统预设会创建独立的用户副本。私人问题、备注和结果不会进入预设。',
      primary: Column(
        key: const Key('preset-management-page'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppButton(
            label: '返回设置',
            variant: AppButtonVariant.quiet,
            leading: Icons.arrow_back,
            onPressed: widget.onBack,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.controller.isLoading && !widget.controller.isLoaded)
            const AppSectionCard(child: Text('正在读取本地用户预设…')),
          for (final section in _sections()) ...<Widget>[
            AppSectionCard(
              title: section.title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final preset in section.presets) ...<Widget>[
                    _PresetTile(
                      preset: preset,
                      toolName: section.toolName,
                      onApply: _apply,
                      onCopy: _copy,
                      onRename: _rename,
                      onDelete: _delete,
                    ),
                    if (preset != section.presets.last)
                      const Divider(height: AppSpacing.xl),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          if (_sections().isEmpty)
            const AppSectionCard(
              child: Text('当前没有可管理的预设。工具能力不可用时，已有历史和六个工具仍不受影响。'),
            ),
        ],
      ),
    ),
  );

  List<_PresetSection> _sections() {
    final grouped = <String, List<ToolPreset>>{};
    for (final preset in widget.controller.presets) {
      grouped.putIfAbsent(preset.toolId, () => <ToolPreset>[]).add(preset);
    }
    return grouped.entries
        .map(
          (entry) => _PresetSection(
            toolName:
                widget.controller.registry.byId(entry.key)?.descriptor.name ??
                '不可用工具',
            title:
                widget.controller.registry.byId(entry.key)?.descriptor.name ??
                '不可用工具',
            presets: List<ToolPreset>.unmodifiable(entry.value),
          ),
        )
        .toList(growable: false);
  }

  void _apply(ToolPreset preset) {
    try {
      widget.onApply(preset);
    } on Object catch (error) {
      _showError('无法应用此预设：$error');
    }
  }

  Future<void> _copy(ToolPreset preset) async {
    final name = await _askName(
      title: '保存为用户预设',
      initialValue: preset.displayName,
      confirmLabel: '保存副本',
    );
    if (name == null || !mounted) return;
    try {
      await widget.controller.copyAsUser(preset, displayName: name);
      if (mounted) _showMessage('已创建用户预设副本。');
    } on Object catch (error) {
      if (mounted) _showError('无法保存用户预设：$error');
    }
  }

  Future<void> _rename(ToolPreset preset) async {
    final name = await _askName(
      title: '重命名用户预设',
      initialValue: preset.displayName,
      confirmLabel: '保存名称',
    );
    if (name == null || !mounted) return;
    try {
      await widget.controller.renameUser(preset.id, displayName: name);
      if (mounted) _showMessage('用户预设名称已更新。');
    } on Object catch (error) {
      if (mounted) _showError('无法重命名用户预设：$error');
    }
  }

  Future<void> _delete(ToolPreset preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除用户预设？'),
        content: Text('只会删除“${preset.displayName}”的本地规则配置，不会删除历史或会话结果。'),
        actions: <Widget>[
          AppButton(
            label: '取消',
            variant: AppButtonVariant.quiet,
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton(
            label: '删除',
            variant: AppButtonVariant.danger,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.controller.deleteUser(preset.id);
      if (mounted) _showMessage('用户预设已删除；历史记录未受影响。');
    } on Object catch (error) {
      if (mounted) _showError('无法删除用户预设：$error');
    }
  }

  Future<String?> _askName({
    required String title,
    required String initialValue,
    required String confirmLabel,
  }) async {
    final controller = TextEditingController(text: initialValue);
    String? error;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: TextField(
            autofocus: true,
            controller: controller,
            maxLength: ToolPreset.maximumDisplayNameLength,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: '名称', errorText: error),
            onSubmitted: (_) {
              final value = controller.text.trim();
              final validation = ToolPreset.validateDisplayName(value);
              if (validation != null) {
                setDialogState(() => error = validation);
              } else {
                Navigator.pop(context, value);
              }
            },
          ),
          actions: <Widget>[
            AppButton(
              label: '取消',
              variant: AppButtonVariant.quiet,
              onPressed: () => Navigator.pop(context),
            ),
            AppButton(
              label: confirmLabel,
              variant: AppButtonVariant.primary,
              onPressed: () {
                final value = controller.text.trim();
                final validation = ToolPreset.validateDisplayName(value);
                if (validation != null) {
                  setDialogState(() => error = validation);
                } else {
                  Navigator.pop(context, value);
                }
              },
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

final class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.toolName,
    required this.onApply,
    required this.onCopy,
    required this.onRename,
    required this.onDelete,
  });

  final ToolPreset preset;
  final String toolName;
  final ValueChanged<ToolPreset> onApply;
  final Future<void> Function(ToolPreset) onCopy;
  final Future<void> Function(ToolPreset) onRename;
  final Future<void> Function(ToolPreset) onDelete;

  @override
  Widget build(BuildContext context) {
    final state = preset.type == PresetType.system ? '系统预设（只读）' : '用户预设';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          container: true,
          label: '$toolName，${preset.displayName}，$state',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(preset.displayName),
            subtitle: Text('$state · 规则版本：${preset.ruleVersion}'),
            trailing: preset.type == PresetType.system
                ? const Icon(Icons.lock_outline)
                : const Icon(Icons.person_outline),
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            AppButton(
              key: Key('apply-preset-${preset.id}'),
              label: '应用',
              variant: AppButtonVariant.primary,
              onPressed: () => onApply(preset),
            ),
            if (preset.type == PresetType.system)
              AppButton(
                key: Key('copy-preset-${preset.id}'),
                label: '保存为用户副本',
                variant: AppButtonVariant.secondary,
                onPressed: () => onCopy(preset),
              )
            else ...<Widget>[
              AppButton(
                key: Key('rename-preset-${preset.id}'),
                label: '重命名',
                variant: AppButtonVariant.secondary,
                onPressed: () => onRename(preset),
              ),
              AppButton(
                key: Key('delete-preset-${preset.id}'),
                label: '删除',
                variant: AppButtonVariant.danger,
                onPressed: () => onDelete(preset),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

final class _PresetSection {
  const _PresetSection({
    required this.title,
    required this.toolName,
    required this.presets,
  });

  final String title;
  final String toolName;
  final List<ToolPreset> presets;
}
