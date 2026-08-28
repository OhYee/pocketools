import 'package:flutter/material.dart';

import '../../assets/runtime/runtime_asset_manifest.dart';

typedef RuntimeAssetBuilder = Widget Function(
  BuildContext context,
  RuntimeAssetReference asset,
  Widget fallback,
);

/// Renders a local runtime asset when it is shipped and falls back to the
/// deterministic artwork supplied by the feature when it is not.
final class RuntimeAssetSlot extends StatelessWidget {
  const RuntimeAssetSlot({
    required this.asset,
    required this.fallback,
    this.assetBuilder,
    this.fit = BoxFit.contain,
    super.key,
  });

  final RuntimeAssetReference asset;
  final Widget fallback;
  final RuntimeAssetBuilder? assetBuilder;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (assetBuilder != null) {
      return _wrap(assetBuilder!(context, asset, fallback));
    }
    return _wrap(
      Image.asset(
        asset.path,
        fit: fit,
        gaplessPlayback: true,
        semanticLabel: asset.semanticLabel,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }

  Widget _wrap(Widget child) => Semantics(
    label: asset.semanticLabel,
    child: ExcludeSemantics(child: child),
  );
}
