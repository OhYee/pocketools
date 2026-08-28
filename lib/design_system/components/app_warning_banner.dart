import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';

final class AppWarningBanner extends StatelessWidget {
  const AppWarningBanner({
    required this.message,
    required this.onDismiss,
    super.key,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.errorContainer,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Semantics(liveRegion: true, child: Text(message))),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              label: '关闭',
              variant: AppButtonVariant.quiet,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    ),
  );
}
