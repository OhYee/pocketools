import 'package:flutter/material.dart';

import '../../core/tools/tool_module.dart';
import '../app_tokens.dart';

final class AppToolCard extends StatelessWidget {
  const AppToolCard({
    required this.descriptor,
    required this.onPressed,
    super.key,
  });

  final ToolDescriptor descriptor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${descriptor.name}，${descriptor.description}',
    child: Card(
      color: context.appSurfaces.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.large),
        side: BorderSide(color: context.appColors.border),
      ),
      child: InkWell(
        onTap: onPressed,
        mouseCursor: SystemMouseCursors.click,
        hoverColor: context.appColors
            .accentSurfaceFor(descriptor.accent)
            .withValues(alpha: 0.42),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.minimumTapTarget * 2,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.appColors.accentSurfaceFor(
                      descriptor.accent,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.medium),
                    border: Border.all(
                      color: context.appColors
                          .accentFor(descriptor.accent)
                          .withValues(alpha: 0.24),
                    ),
                  ),
                  child: SizedBox.square(
                    dimension: AppSpacing.xxl,
                    child: Icon(
                      descriptor.icon,
                      size: AppSpacing.xl,
                      color: context.appColors.accentFor(descriptor.accent),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        descriptor.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(descriptor.description),
                      if (descriptor.availability ==
                          ToolAvailability.designInProgress) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '设计完善中',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: context.appColors.textSecondary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.xs),
                    child: Icon(Icons.chevron_right, size: AppSpacing.lg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
