import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// Shared product identity used by entry surfaces without coupling them to a
/// specific tool. Tool pages can keep their focused title while the home
/// surface still feels like the same product.
final class AppBrandHeader extends StatelessWidget {
  const AppBrandHeader({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: context.appSurfaces.shadow,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          child: Image.asset(
            'assets/branding/app_icon.png',
            width: AppSpacing.xxxl,
            height: AppSpacing.xxxl,
            fit: BoxFit.cover,
            semanticLabel: '万象匣标志',
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '万象匣',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            'v0.1.3 · 本地随机工具箱',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: context.appColors.textSecondary),
          ),
        ],
      ),
    ],
  );
}
