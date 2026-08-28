import 'package:flutter/material.dart';

import '../../core/session/session_history.dart';
import '../../design_system/app_tokens.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_segmented_control.dart';
import '../../design_system/components/app_surfaces.dart';
import '../../design_system/components/app_tool_scaffold.dart';
import '../platform/local_app_settings.dart';
import 'app_settings_controller.dart';

final class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.settings,
    required this.historyRepository,
    this.onOpenPresets,
    super.key,
  });

  final AppSettingsController settings;
  final SessionHistoryRepository historyRepository;
  final VoidCallback? onOpenPresets;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

final class _SettingsPageState extends State<SettingsPage> {
  var _clearingHistory = false;

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除全部历史？'),
        content: const Text('这会删除 Pocketools 拥有的本地会话、收藏和私人备注，无法撤销。'),
        actions: <Widget>[
          AppButton(
            label: '取消',
            variant: AppButtonVariant.quiet,
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton(
            label: '确认清除',
            variant: AppButtonVariant.danger,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _clearingHistory = true);
    try {
      await widget.historyRepository.clearHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('本地历史已清除。')));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('本地历史暂时无法清除。')));
    } finally {
      if (mounted) setState(() => _clearingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return AppToolScaffold(
      title: '设置',
      subtitle: '全局偏好只影响呈现和后续保存位置，不改变任何已冻结结果。',
      primary: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppSectionCard(
            title: '外观与动态',
            child: Column(
              children: <Widget>[
                AppSegmentedControl<LocalThemeMode>(
                  label: '主题',
                  segments: const <AppSegment<LocalThemeMode>>[
                    AppSegment(value: LocalThemeMode.system, label: '跟随系统'),
                    AppSegment(value: LocalThemeMode.light, label: '浅色'),
                    AppSegment(value: LocalThemeMode.dark, label: '深色'),
                  ],
                  selected: settings.themeMode,
                  onSelected: (value) => settings.themeMode = value,
                ),
                const Divider(height: AppSpacing.xl),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('启用动画'),
                  subtitle: const Text('关闭后，所有工具直接显示已冻结结果。'),
                  value: settings.animationsEnabled,
                  onChanged: (value) => settings.animationsEnabled = value,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('减少动态效果'),
                  subtitle: const Text('与系统“减少动态”共同收敛为简化揭示。'),
                  value: settings.reduceMotion,
                  onChanged: (value) => settings.reduceMotion = value,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppSectionCard(
            title: '反馈',
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('声音'),
                  subtitle: const Text('当前版本保留此偏好；没有工具会擅自播放声音。'),
                  value: settings.soundEnabled,
                  onChanged: (value) => settings.soundEnabled = value,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('振动反馈'),
                  subtitle: const Text('Android 支持时提供轻／中反馈；Web 需能力、页面可见和用户激活。'),
                  value: settings.feedbackEnabled,
                  onChanged: (value) => settings.feedbackEnabled = value,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppSectionCard(
            title: '隐私与本地数据',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('保存新历史'),
                  subtitle: const Text('关闭后，新会话只在本次应用生命周期内保留；已有历史不会删除。'),
                  value: settings.historyEnabled,
                  onChanged: (value) => settings.historyEnabled = value,
                ),
                const Text(
                  'Web 使用站点本地存储。无痕模式、浏览器清理站点数据或系统回收空间都可能移除它；Pocketools 不上传会话。',
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: '管理预设',
                  variant: AppButtonVariant.secondary,
                  leading: Icons.tune_outlined,
                  onPressed: widget.onOpenPresets,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: '清除全部本地历史',
                  variant: AppButtonVariant.danger,
                  loading: _clearingHistory,
                  onPressed: _clearHistory,
                ),
              ],
            ),
          ),
        ],
      ),
      secondary: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const AppSectionCard(
            title: '随机过程',
            child: Text(
              '工具结果使用可注入的统一安全随机源；会话 ID 使用另一条独立安全熵路径。结果在动画和反馈前一次冻结并保存。安全熵不可用时会停止生成，不会用弱随机替代。',
            ),
          ),
        ],
      ),
    );
  }
}
