import 'package:flutter/material.dart';

import '../../core/tools/tool_module.dart';
import '../app_tokens.dart';

/// Applies a registered tool's semantic accent to shared controls.
final class AppToolTheme extends StatelessWidget {
  const AppToolTheme({required this.accent, required this.child, super.key});

  final ToolAccent accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = context.appColors.accentFor(accent);
    final accentSurface = context.appColors.accentSurfaceFor(accent);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: accentColor,
          primaryContainer: accentSurface,
          onPrimary: context.appColors.onAccentFor(accent),
        ),
      ),
      child: child,
    );
  }
}
