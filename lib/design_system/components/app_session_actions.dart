import 'package:flutter/material.dart';

import '../../core/session/session.dart';
import '../../core/tools/session_actions.dart';
import '../app_tokens.dart';
import 'app_button.dart';

/// Shared result operations. Feature pages supply a frozen session and a
/// regenerate callback but never render privacy or platform-share behavior.
final class AppSessionActions extends StatefulWidget {
  const AppSessionActions({
    required this.session,
    required this.controller,
    this.regenerateLabel,
    this.onRegenerate,
    this.regenerateKey,
    this.regenerateEnabled = true,
    super.key,
  });

  final SessionRecord? session;
  final SessionActionsController? controller;
  final String? regenerateLabel;
  final VoidCallback? onRegenerate;
  final Key? regenerateKey;
  final bool regenerateEnabled;

  @override
  State<AppSessionActions> createState() => _AppSessionActionsState();
}

final class _AppSessionActionsState extends State<AppSessionActions> {
  var _loadingPreview = false;

  Future<void> _openPreview() async {
    final session = widget.session;
    final controller = widget.controller;
    if (session == null || controller == null || _loadingPreview) return;
    setState(() => _loadingPreview = true);
    SessionSharePreview preview;
    try {
      preview = await controller.preview(session);
    } on Object {
      if (!mounted) return;
      setState(() => _loadingPreview = false);
      _showMessage('无法生成脱敏预览。');
      return;
    }
    if (!mounted) return;
    setState(() => _loadingPreview = false);
    await showDialog<void>(
      context: context,
      builder: (context) =>
          _SessionSharePreviewDialog(preview: preview, controller: controller),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (widget.session != null && widget.controller != null) ...<Widget>[
        AppButton(
          label: '复制或分享',
          variant: AppButtonVariant.secondary,
          leading: Icons.ios_share_outlined,
          loading: _loadingPreview,
          onPressed: _openPreview,
          expand: true,
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (widget.regenerateLabel != null && widget.onRegenerate != null)
        AppButton(
          key: widget.regenerateKey,
          label: widget.regenerateLabel!,
          leading: Icons.refresh,
          onPressed: widget.regenerateEnabled ? widget.onRegenerate : null,
          expand: true,
        ),
    ],
  );
}

final class _SessionSharePreviewDialog extends StatefulWidget {
  const _SessionSharePreviewDialog({
    required this.preview,
    required this.controller,
  });

  final SessionSharePreview preview;
  final SessionActionsController controller;

  @override
  State<_SessionSharePreviewDialog> createState() =>
      _SessionSharePreviewDialogState();
}

final class _SessionSharePreviewDialogState
    extends State<_SessionSharePreviewDialog> {
  final Set<String> _includedFieldIds = <String>{};
  var _includePrivateNote = false;
  var _includeTime = false;
  var _busy = false;

  String get _text => widget.preview.compose(
    includedFieldIds: _includedFieldIds,
    includePrivateNote: _includePrivateNote,
    includeTime: _includeTime,
  );

  Future<void> _share() async {
    setState(() => _busy = true);
    final outcome = await widget.controller.share(
      widget.preview,
      includedFieldIds: _includedFieldIds,
      includePrivateNote: _includePrivateNote,
      includeTime: _includeTime,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case SessionTextActionOutcome.shared:
        _closeWithMessage('已交给系统分享。');
      case SessionTextActionOutcome.copiedToClipboard:
        _closeWithMessage('系统分享不可用，文本已复制。');
      case SessionTextActionOutcome.dismissed:
        _showMessage('已取消分享，未复制文本。');
      case SessionTextActionOutcome.failed:
        _showMessage('分享和复制暂时不可用。');
    }
  }

  Future<void> _copy() async {
    setState(() => _busy = true);
    final outcome = await widget.controller.copy(
      widget.preview,
      includedFieldIds: _includedFieldIds,
      includePrivateNote: _includePrivateNote,
      includeTime: _includeTime,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome == SessionTextActionOutcome.copiedToClipboard) {
      _closeWithMessage('文本已复制。');
    } else {
      _showMessage('复制暂时不可用。');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _closeWithMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('分享预览'),
    content: SizedBox(
      width: AppSizes.formColumn,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SelectableText(_text, key: const Key('session-share-preview-text')),
            if (widget.preview.optionalFields.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Text('可选隐私字段', style: Theme.of(context).textTheme.titleSmall),
              for (final field in widget.preview.optionalFields)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(field.label),
                  subtitle: Text(field.value),
                  value: _includedFieldIds.contains(field.id),
                  onChanged: _busy
                      ? null
                      : (selected) => setState(() {
                          if (selected ?? false) {
                            _includedFieldIds.add(field.id);
                          } else {
                            _includedFieldIds.remove(field.id);
                          }
                        }),
                ),
            ],
            if (widget.preview.privateNote != null)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('包含私人备注'),
                value: _includePrivateNote,
                onChanged: _busy
                    ? null
                    : (value) =>
                          setState(() => _includePrivateNote = value ?? false),
              ),
            if (widget.preview.savedAtUtc != null)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('包含保存时间'),
                value: _includeTime,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _includeTime = value ?? false),
              ),
            const SizedBox(height: AppSpacing.sm),
            const Text('会话 ID、父会话 ID 与设备信息始终不会加入分享文本。'),
          ],
        ),
      ),
    ),
    actions: <Widget>[
      AppButton(
        label: '取消',
        variant: AppButtonVariant.quiet,
        onPressed: _busy ? null : () => Navigator.pop(context),
      ),
      AppButton(
        label: '复制',
        variant: AppButtonVariant.secondary,
        onPressed: _busy ? null : _copy,
      ),
      AppButton(label: '系统分享', loading: _busy, onPressed: _share),
    ],
  );
}
