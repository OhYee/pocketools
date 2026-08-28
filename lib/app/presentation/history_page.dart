import 'package:flutter/material.dart';

import '../../core/session/session_history.dart';
import '../../core/tools/tool_capabilities.dart';
import '../../core/tools/tool_registry.dart';
import '../../core/tools/session_actions.dart';
import '../../design_system/app_tokens.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_segmented_control.dart';
import '../../design_system/components/app_session_actions.dart';
import '../../design_system/components/app_surfaces.dart';
import '../../design_system/components/app_tool_scaffold.dart';

enum _HistoryRange { all, sevenDays, thirtyDays }

final class HistoryPage extends StatefulWidget {
  const HistoryPage({
    required this.registry,
    required this.repository,
    required this.onReplay,
    this.active = true,
    this.sessionActions,
    super.key,
  });

  final ToolRegistry registry;
  final SessionHistoryRepository repository;
  final ValueChanged<ToolLaunchRequest> onReplay;
  final bool active;
  final SessionActionsController? sessionActions;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

final class _HistoryPageState extends State<HistoryPage> {
  List<HistoryEntry>? _entries;
  Object? _loadError;
  String? _toolId;
  var _favoritesOnly = false;
  var _range = _HistoryRange.all;
  var _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        (!oldWidget.active && widget.active)) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _entries = null;
      _loadError = null;
    });
    try {
      final entries = List<HistoryEntry>.of(
        await widget.repository.listHistory(),
      )..sort((left, right) => right.savedAtUtc.compareTo(left.savedAtUtc));
      if (!mounted) return;
      setState(() => _entries = entries);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  String _summary(HistoryEntry entry) {
    try {
      return widget.registry.historySummary(entry.session).summary;
    } on Object {
      return '此结果无法由当前版本解码。';
    }
  }

  List<HistoryEntry> get _filteredEntries {
    final entries = _entries ?? const <HistoryEntry>[];
    final now = DateTime.now().toUtc();
    final cutoff = switch (_range) {
      _HistoryRange.all => null,
      _HistoryRange.sevenDays => now.subtract(const Duration(days: 7)),
      _HistoryRange.thirtyDays => now.subtract(const Duration(days: 30)),
    };
    final query = _query.trim().toLowerCase();
    return entries
        .where((entry) {
          final session = entry.session;
          if (_toolId != null && session.toolId != _toolId) return false;
          if (_favoritesOnly && !entry.annotation.favorite) return false;
          if (cutoff != null && entry.savedAtUtc.isBefore(cutoff)) return false;
          if (query.isEmpty) return true;
          final module = widget.registry.byId(session.toolId);
          final searchable =
              '${module?.descriptor.name ?? session.toolId} '
                      '${_summary(entry)} ${entry.annotation.privateNote ?? ''}'
                  .toLowerCase();
          return searchable.contains(query);
        })
        .toList(growable: false);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            AppButton(
              label: '取消',
              variant: AppButtonVariant.quiet,
              onPressed: () => Navigator.pop(context, false),
            ),
            AppButton(
              label: '确认删除',
              variant: AppButtonVariant.danger,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _deleteAll() async {
    if (!await _confirm(title: '清除全部历史？', message: '此操作只删除万象匣本地历史，无法撤销。')) {
      return;
    }
    await widget.repository.clearHistory();
    await _load();
  }

  Future<void> _deleteTool() async {
    final toolId = _toolId;
    final module = toolId == null ? null : widget.registry.byId(toolId);
    if (toolId == null || module == null) return;
    if (!await _confirm(
      title: '删除${module.descriptor.name}历史？',
      message: '只删除该工具的本地历史，其他工具不受影响。',
    )) {
      return;
    }
    await widget.repository.deleteByTool(toolId);
    await _load();
  }

  Future<void> _showDetails(HistoryEntry entry) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _HistoryDetailsDialog(
        entry: entry,
        registry: widget.registry,
        repository: widget.repository,
        onReplay: widget.onReplay,
        sessionActions: widget.sessionActions,
        onDelete: () async {
          if (!await _confirm(title: '删除这条历史？', message: '此操作无法撤销。')) {
            return false;
          }
          await widget.repository.deleteById(entry.session.id);
          return true;
        },
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;
    return AppToolScaffold(
      title: '历史',
      subtitle: '已完成会话按保存时间倒序保存在本地；草稿不会出现在这里。',
      primary: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppSectionCard(
            title: '筛选',
            child: Column(
              children: <Widget>[
                TextField(
                  decoration: const InputDecoration(
                    labelText: '搜索本地结果',
                    hintText: '输入工具名或结果摘要',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String?>(
                  initialValue: _toolId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '工具'),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        '全部工具',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...widget.registry.modules.map(
                      (module) => DropdownMenuItem<String?>(
                        value: module.descriptor.id,
                        child: Text(
                          module.descriptor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _toolId = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSegmentedControl<_HistoryRange>(
                  label: '保存时间',
                  segments: const <AppSegment<_HistoryRange>>[
                    AppSegment(value: _HistoryRange.all, label: '全部'),
                    AppSegment(value: _HistoryRange.sevenDays, label: '7 天'),
                    AppSegment(value: _HistoryRange.thirtyDays, label: '30 天'),
                  ],
                  selected: _range,
                  onSelected: (value) => setState(() => _range = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('只看收藏'),
                  value: _favoritesOnly,
                  onChanged: (value) => setState(() => _favoritesOnly = value),
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    AppButton(
                      label: '刷新',
                      variant: AppButtonVariant.secondary,
                      leading: Icons.refresh,
                      onPressed: _load,
                    ),
                    AppButton(
                      label: '删除当前工具历史',
                      variant: AppButtonVariant.quiet,
                      onPressed: _toolId == null ? null : _deleteTool,
                    ),
                    AppButton(
                      label: '清除全部历史',
                      variant: AppButtonVariant.danger,
                      onPressed: (_entries?.isEmpty ?? true)
                          ? null
                          : _deleteAll,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_entries == null && _loadError == null)
            const AppSectionCard(
              semanticLabel: '正在加载历史',
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null)
            AppSectionCard(
              title: '无法读取历史',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('本地历史暂时不可用，不影响继续生成新结果。'),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(label: '重试', onPressed: _load),
                ],
              ),
            )
          else if (entries.isEmpty)
            const AppSectionCard(child: Text('没有符合当前筛选条件的已完成结果。'))
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _HistoryEntryCard(
                  entry: entry,
                  toolName:
                      widget.registry
                          .byId(entry.session.toolId)
                          ?.descriptor
                          .name ??
                      '未知工具',
                  summary: _summary(entry),
                  onOpen: () => _showDetails(entry),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.entry,
    required this.toolName,
    required this.summary,
    required this.onOpen,
  });

  final HistoryEntry entry;
  final String toolName;
  final String summary;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => AppSectionCard(
    semanticLabel: '$toolName 历史结果',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(toolName, style: Theme.of(context).textTheme.titleMedium),
            if (entry.annotation.favorite)
              Semantics(
                label: '已收藏',
                child: const Icon(Icons.star, size: AppSpacing.xl),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(summary),
        const SizedBox(height: AppSpacing.sm),
        Text(
          entry.savedAtUtc.toLocal().toString(),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: context.appColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: '查看详情',
          variant: AppButtonVariant.secondary,
          onPressed: onOpen,
        ),
      ],
    ),
  );
}

final class _HistoryDetailsDialog extends StatefulWidget {
  const _HistoryDetailsDialog({
    required this.entry,
    required this.registry,
    required this.repository,
    required this.onReplay,
    required this.onDelete,
    this.sessionActions,
  });

  final HistoryEntry entry;
  final ToolRegistry registry;
  final SessionHistoryRepository repository;
  final ValueChanged<ToolLaunchRequest> onReplay;
  final Future<bool> Function() onDelete;
  final SessionActionsController? sessionActions;

  @override
  State<_HistoryDetailsDialog> createState() => _HistoryDetailsDialogState();
}

final class _HistoryDetailsDialogState extends State<_HistoryDetailsDialog> {
  late final TextEditingController _noteController;
  late bool _favorite;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _favorite = widget.entry.annotation.favorite;
    _noteController = TextEditingController(
      text: widget.entry.annotation.privateNote ?? '',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveAnnotation() async {
    setState(() => _saving = true);
    try {
      await widget.repository.updateAnnotation(
        widget.entry.session.id,
        SessionAnnotation(
          favorite: _favorite,
          privateNote: _noteController.text,
        ),
      );
      if (mounted) Navigator.pop(context);
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('私人注释暂时无法保存。')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.entry.session;
    String resultText;
    var canUseSessionActions = true;
    try {
      widget.registry.decode(session);
      resultText = widget.registry.sharePayload(session).plainText;
    } on Object {
      resultText = '此结果无法由当前版本解码。';
      canUseSessionActions = false;
    }
    return AlertDialog(
      title: Text(
        widget.registry.byId(session.toolId)?.descriptor.name ?? '历史详情',
      ),
      content: SizedBox(
        width: AppSizes.formColumn,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SelectableText(resultText),
              const SizedBox(height: AppSpacing.lg),
              AppSessionActions(
                session: session,
                controller: canUseSessionActions ? widget.sessionActions : null,
                regenerateLabel: canUseSessionActions ? '复用配置' : null,
                regenerateEnabled: !_saving,
                onRegenerate: canUseSessionActions
                    ? () {
                        final request = widget.registry.replayRequest(session);
                        Navigator.pop(context);
                        widget.onReplay(request);
                      }
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('会话 schema：${session.schemaVersion}'),
              Text('规则：${session.ruleVersion}'),
              Text('算法：${session.algorithmVersion}'),
              Text('保存时间：${widget.entry.savedAtUtc.toLocal()}'),
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('收藏'),
                value: _favorite,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _favorite = value),
              ),
              TextField(
                controller: _noteController,
                enabled: !_saving,
                maxLength: SessionAnnotation.maximumPrivateNoteLength,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: '私人备注',
                  helperText: '只保存在本地；默认分享不会包含。',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        AppButton(
          label: '删除',
          variant: AppButtonVariant.danger,
          onPressed: _saving
              ? null
              : () async {
                  if (await widget.onDelete() && context.mounted) {
                    Navigator.pop(context);
                  }
                },
        ),
        AppButton(label: '保存注释', loading: _saving, onPressed: _saveAnnotation),
      ],
    );
  }
}
