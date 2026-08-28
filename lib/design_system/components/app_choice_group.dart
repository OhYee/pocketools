import 'package:flutter/material.dart';

import '../app_tokens.dart';

@immutable
final class AppChoice<T> {
  const AppChoice({required this.value, required this.label});

  final T value;
  final String label;
}

final class AppChoiceGroup<T> extends StatelessWidget {
  const AppChoiceGroup({
    required this.label,
    required this.choices,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
    super.key,
  });

  final String label;
  final List<AppChoice<T>> choices;
  final T selected;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: choices
              .map(
                (choice) => ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: AppSizes.minimumTapTarget,
                    minHeight: AppSizes.minimumTapTarget,
                  ),
                  child: Semantics(
                    selected: choice.value == selected,
                    button: true,
                    label: choice.label,
                    child: ChoiceChip(
                      label: Text(choice.label),
                      selected: choice.value == selected,
                      onSelected: enabled
                          ? (_) => onSelected(choice.value)
                          : null,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    ),
  );
}
