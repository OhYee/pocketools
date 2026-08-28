import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_surfaces.dart';

enum GenerationPhase {
  ready,
  pressed,
  generating,
  revealing,
  completed,
  reduced,
}

final class AppGenerationStateView extends StatelessWidget {
  const AppGenerationStateView({required this.phase, this.label, super.key});

  final GenerationPhase phase;
  final String? label;

  String get _defaultLabel => switch (phase) {
    GenerationPhase.ready => '准备就绪',
    GenerationPhase.pressed => '设置已冻结',
    GenerationPhase.generating => '正在生成结果',
    GenerationPhase.revealing => '结果已生成，正在揭示',
    GenerationPhase.completed => '结果已完成',
    GenerationPhase.reduced => '减少动态：结果已生成',
  };

  IconData get _icon => switch (phase) {
    GenerationPhase.ready => Icons.hourglass_empty,
    GenerationPhase.pressed => Icons.lock_outline,
    GenerationPhase.generating => Icons.sync,
    GenerationPhase.revealing => Icons.visibility_outlined,
    GenerationPhase.completed => Icons.check_circle_outline,
    GenerationPhase.reduced => Icons.motion_photos_off_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final resolvedLabel = label ?? _defaultLabel;
    final semanticColors = context.appColors;
    final (foreground, background) = switch (phase) {
      GenerationPhase.completed => (
        semanticColors.success,
        semanticColors.successSurface,
      ),
      GenerationPhase.ready || GenerationPhase.reduced => (
        semanticColors.textSecondary,
        semanticColors.surfaceMuted,
      ),
      _ => (
        Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
      ),
    };
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      liveRegion: true,
      label: resolvedLabel,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: ClipRect(
            child: SizedBox(
              height: AppSizes.generationStateSlotHeight,
              child: Align(
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: reduced
                      ? context.appMotion.reduced
                      : context.appMotion.base,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: foreground.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: foreground.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Icon(
                            _icon,
                            color: foreground,
                            size: AppSpacing.xl,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          resolvedLabel,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The single visual plane for a random tool's physical entity and lifecycle.
///
/// Keeping the phase indicator inside the same card as [child] prevents tools
/// from growing a second, competing "generating/result" layer below the main
/// interaction target.
final class AppEntityStateView extends StatelessWidget {
  const AppEntityStateView({
    required this.phase,
    required this.phaseLabel,
    required this.semanticLabel,
    required this.child,
    this.error,
    this.onActivate,
    this.affordanceHint,
    super.key,
  });

  final GenerationPhase phase;
  final String phaseLabel;
  final String semanticLabel;
  final Widget child;
  final String? error;
  final VoidCallback? onActivate;
  final String? affordanceHint;

  @override
  Widget build(BuildContext context) => AppSectionCard(
    semanticLabel: semanticLabel,
    tone: AppSurfaceTone.entity,
    onTap: onActivate,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (error == null)
          AppGenerationStateView(phase: phase, label: phaseLabel)
        else
          SizedBox(
            height: AppSizes.generationStateSlotHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                liveRegion: true,
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        child,
        if (affordanceHint != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              affordanceHint!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: context.appColors.textSecondary),
            ),
          ),
        ],
      ],
    ),
  );
}
