import 'package:flutter/material.dart';

import '../app_tokens.dart';

enum AppButtonVariant { primary, secondary, quiet, danger }

final class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.leading,
    this.loading = false,
    this.expand = false,
    this.semanticLabel,
    this.focusNode,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? leading;
  final bool loading;
  final bool expand;
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  State<AppButton> createState() => _AppButtonState();
}

final class _AppButtonState extends State<AppButton> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    final semanticLabel = widget.semanticLabel;
    final child = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.loading)
          const SizedBox.square(
            dimension: AppSpacing.xl,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (widget.leading != null)
          Icon(widget.leading, size: AppSpacing.xl),
        if (widget.loading || widget.leading != null)
          const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(widget.loading ? '处理中' : label)),
      ],
    );
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size(AppSizes.minimumTapTarget, AppSizes.minimumTapTarget),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
    final callback = widget.loading ? null : widget.onPressed;
    final button = switch (widget.variant) {
      AppButtonVariant.primary => FilledButton(
        style: style,
        focusNode: widget.focusNode,
        onPressed: callback,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        style: style,
        focusNode: widget.focusNode,
        onPressed: callback,
        child: child,
      ),
      AppButtonVariant.quiet => TextButton(
        style: style,
        focusNode: widget.focusNode,
        onPressed: callback,
        child: child,
      ),
      AppButtonVariant.danger => FilledButton(
        style: style.copyWith(
          backgroundColor: WidgetStatePropertyAll<Color>(
            Theme.of(context).colorScheme.error,
          ),
          foregroundColor: WidgetStatePropertyAll<Color>(
            Theme.of(context).colorScheme.onError,
          ),
        ),
        focusNode: widget.focusNode,
        onPressed: callback,
        child: child,
      ),
    };
    return Semantics(
      button: true,
      enabled: callback != null,
      label: semanticLabel ?? label,
      value: widget.loading ? '正在处理' : null,
      child: Listener(
        onPointerDown: callback == null ? null : (_) => _setPressed(true),
        onPointerUp: callback == null ? null : (_) => _setPressed(false),
        onPointerCancel: callback == null ? null : (_) => _setPressed(false),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: AppSpacing.zero,
            end: _pressed ? 1 : AppSpacing.zero,
          ),
          duration: context.appMotion.press,
          curve: Curves.easeOut,
          child: button,
          builder: (context, progress, animatedButton) {
            final scale = 1 - (1 - AppMotionValues.buttonPressScale) * progress;
            return Transform.translate(
              offset: Offset(
                AppSpacing.zero,
                AppMotionValues.buttonPressTranslation * progress,
              ),
              child: Transform.scale(scale: scale, child: animatedButton),
            );
          },
        ),
      ),
    );
  }
}
