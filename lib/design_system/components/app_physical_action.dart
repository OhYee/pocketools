import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// Gives a physical-looking tool object one reusable interaction contract.
///
/// The page owns the object and the action; this component owns the shared
/// hit target, focus behavior, hover/splash feedback, and semantics. Keeping
/// those concerns here prevents decks, coins, and dice from drifting apart as
/// new random tools are added.
final class AppPhysicalAction extends StatelessWidget {
  const AppPhysicalAction({
    required this.child,
    required this.label,
    this.onTap,
    this.hint,
    this.focusNode,
    this.padding = const EdgeInsets.all(AppSpacing.xs),
    this.semanticKey,
    super.key,
  });

  final Widget child;
  final String label;
  final VoidCallback? onTap;
  final String? hint;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry padding;
  final Key? semanticKey;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Semantics(
      key: semanticKey,
      button: onTap != null,
      enabled: onTap != null,
      label: label,
      hint: onTap == null ? null : hint,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.large),
          focusNode: focusNode,
          mouseCursor: onTap == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          hoverColor: onTap == null ? null : accent.withValues(alpha: 0.08),
          splashColor: onTap == null ? null : accent.withValues(alpha: 0.14),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppSizes.minimumTapTarget,
                minHeight: AppSizes.minimumTapTarget,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
