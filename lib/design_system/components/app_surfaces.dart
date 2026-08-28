import 'package:flutter/material.dart';

import '../app_tokens.dart';

enum AppSurfaceTone { standard, entity, result, inset }

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    required this.child,
    this.title,
    this.semanticLabel,
    this.tone = AppSurfaceTone.standard,
    this.onTap,
    super.key,
  });

  final Widget child;
  final String? title;
  final String? semanticLabel;
  final AppSurfaceTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.appSurfaces;
    final colors = context.appColors;
    final cardColor = switch (tone) {
      AppSurfaceTone.inset => surfaces.surfaceInset,
      _ => surfaces.surface,
    };
    final elevation = switch (tone) {
      AppSurfaceTone.entity => AppElevation.entity,
      AppSurfaceTone.result => AppElevation.result,
      _ => AppElevation.section,
    };
    final accent = Theme.of(context).colorScheme.primary;
    final decoration = switch (tone) {
      AppSurfaceTone.entity => BoxDecoration(
        color: cardColor,
        gradient: LinearGradient(
          colors: <Color>[surfaces.surfaceRaised, cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      AppSurfaceTone.result => BoxDecoration(
        color: cardColor,
        gradient: LinearGradient(
          colors: <Color>[accent.withValues(alpha: 0.08), cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _ => BoxDecoration(color: cardColor),
    };
    return Semantics(
      container: true,
      button: onTap != null,
      enabled: onTap != null,
      label: semanticLabel,
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        color: cardColor,
        elevation: elevation,
        shadowColor: surfaces.shadow,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            tone == AppSurfaceTone.result
                ? AppRadii.extraLarge
                : AppRadii.large,
          ),
          side: BorderSide(
            color: tone == AppSurfaceTone.entity
                ? colors.borderStrong
                : colors.border,
          ),
        ),
        child: Ink(
          decoration: decoration,
          child: InkWell(
            onTap: onTap,
            mouseCursor: onTap == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            hoverColor: onTap == null ? null : accent.withValues(alpha: 0.08),
            splashColor: onTap == null ? null : accent.withValues(alpha: 0.14),
            child: Padding(
              padding: EdgeInsets.all(
                tone == AppSurfaceTone.result ? AppSpacing.xl : AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (title != null) ...<Widget>[
                    Row(
                      children: <Widget>[
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(AppRadii.full),
                          ),
                          child: const SizedBox(width: 4, height: 18),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            title!,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Adds a quiet halo around the physical object in each tool's first-run
/// stage. The entity itself remains owned by the feature; this chrome is
/// shared so dice, coins, cards, tarot, and 六爻 all get the same depth cue.
final class AppEntityStage extends StatelessWidget {
  const AppEntityStage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.appSurfaces;
    final accent = Theme.of(context).colorScheme.primary;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedContainer(
      duration: reduced ? context.appMotion.reduced : context.appMotion.base,
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.extraLarge),
        gradient: RadialGradient(
          center: const Alignment(0, -0.8),
          radius: 1.3,
          colors: <Color>[
            accent.withValues(alpha: 0.16),
            surfaces.surfaceInset.withValues(alpha: 0.78),
            surfaces.canvas,
          ],
          stops: const <double>[0, 0.62, 1],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: surfaces.shadowStrong,
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSizes.entityStageSlotHeight,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: RepaintBoundary(child: ClipRect(child: child)),
        ),
      ),
    );
  }
}

/// Reserves one stable plane for a physical object while its final details
/// are being revealed. It is intentionally shared by tools that need a
/// bounded object area, rather than letting each page invent a height.
final class AppPhysicalStageSlot extends StatelessWidget {
  const AppPhysicalStageSlot({
    required this.height,
    required this.child,
    super.key,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Align(alignment: Alignment.center, child: child),
  );
}

/// Keeps the geometry of a result stable while withholding its final text
/// from the tree's visible semantics until the physical reveal is complete.
final class AppRevealDetailsSlot extends StatelessWidget {
  const AppRevealDetailsSlot({
    required this.visible,
    required this.child,
    super.key,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => Visibility(
    visible: visible,
    maintainState: true,
    maintainAnimation: true,
    maintainSize: true,
    maintainSemantics: false,
    child: child,
  );
}

final class AppResultCard extends StatelessWidget {
  const AppResultCard({
    required this.title,
    required this.value,
    required this.details,
    this.status,
    super.key,
  });

  final String title;
  final String value;
  final String details;
  final Widget? status;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: '$title $value，$details',
    child: AppSectionCard(
      tone: AppSurfaceTone.result,
      semanticLabel: '检定结果',
      child: Center(
        child: Column(
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            AnimatedSwitcher(
              duration: MediaQuery.maybeOf(context)?.disableAnimations ?? false
                  ? context.appMotion.reduced
                  : context.appMotion.complete,
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Text(
                value,
                key: ValueKey<String>(value),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 56,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              details,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.appColors.textSecondary),
            ),
            if (status != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.appColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(color: context.appColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: status!,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

final class OutcomePlane extends StatelessWidget {
  const OutcomePlane({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppSectionCard(
    title: '骰子结果（按生成顺序）',
    tone: AppSurfaceTone.inset,
    child: Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: children,
    ),
  );
}
