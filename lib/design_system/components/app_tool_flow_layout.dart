import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_surfaces.dart';

/// Shared first-run layout for every random tool.
///
/// The feature owns the entity, controls, and result content; this component
/// owns their order and spacing so interaction changes remain one-line global
/// updates instead of five page-specific edits.
final class AppToolFlowLayout extends StatelessWidget {
  const AppToolFlowLayout({
    required this.coreEntity,
    required this.actionBar,
    required this.advancedOptions,
    required this.outcome,
    super.key,
  });

  final Widget coreEntity;
  final Widget actionBar;
  final Widget advancedOptions;
  final Widget outcome;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      AppEntityStage(child: coreEntity),
      const SizedBox(height: AppSpacing.lg),
      actionBar,
      const SizedBox(height: AppSpacing.lg),
      advancedOptions,
      const SizedBox(height: AppSpacing.xl),
      outcome,
    ],
  );
}
