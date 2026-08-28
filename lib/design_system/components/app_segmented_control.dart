import 'package:flutter/material.dart';

import '../app_tokens.dart';

@immutable
final class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

final class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.label,
    required this.segments,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
    super.key,
  });

  final String label;
  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    container: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (MediaQuery.textScalerOf(context).scale(1) >= 1.5)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: segments
                .map(
                  (segment) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Semantics(
                      selected: segment.value == selected,
                      button: true,
                      child: OutlinedButton.icon(
                        style: const ButtonStyle(
                          minimumSize: WidgetStatePropertyAll<Size>(
                            Size.fromHeight(AppSizes.minimumTapTarget),
                          ),
                        ),
                        onPressed: enabled
                            ? () => onSelected(segment.value)
                            : null,
                        icon: Icon(
                          segment.value == selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                        label: Text(segment.label),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          )
        else
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll<Size>(
                  Size(AppSizes.minimumTapTarget, AppSizes.minimumTapTarget),
                ),
              ),
              showSelectedIcon: false,
              multiSelectionEnabled: false,
              segments: segments
                  .map(
                    (segment) => ButtonSegment<T>(
                      value: segment.value,
                      label: Text(segment.label),
                      icon: segment.icon == null ? null : Icon(segment.icon),
                    ),
                  )
                  .toList(growable: false),
              selected: <T>{selected},
              onSelectionChanged: enabled
                  ? (selection) => onSelected(selection.single)
                  : null,
            ),
          ),
      ],
    ),
  );
}
