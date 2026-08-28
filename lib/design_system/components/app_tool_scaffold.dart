import 'package:flutter/material.dart';

import '../app_tokens.dart';

final class AppToolScaffold extends StatelessWidget {
  const AppToolScaffold({
    required this.title,
    required this.primary,
    this.secondary,
    this.subtitle,
    this.onBack,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget primary;
  final Widget? secondary;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    final padding = wide
        ? AppSizes.desktopPagePadding
        : MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet
        ? AppSizes.tabletPagePadding
        : AppSizes.smallPagePadding;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.contentMax),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    if (onBack != null) ...<Widget>[
                      IconButton(
                        key: const Key('tool-back-button'),
                        tooltip: '返回上一级',
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: context.appColors.textSecondary),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                if (wide && secondary != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: primary),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(child: secondary!),
                    ],
                  )
                else ...<Widget>[
                  primary,
                  if (secondary != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xl),
                    secondary!,
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
