import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_physical_action.dart';

/// Shared interaction entry point for card-like random tools.
///
/// Tarot and playing cards intentionally provide different artwork and
/// interpretation content, but the physical affordance is the same: one
/// persistent deck, one tap for one draw, and a stable accessible hit target.
final class AppPhysicalDeck extends StatelessWidget {
  const AppPhysicalDeck({
    required this.child,
    required this.label,
    this.onTap,
    this.hint,
    this.focusNode,
    super.key,
  });

  final Widget child;
  final String label;
  final VoidCallback? onTap;
  final String? hint;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => AppPhysicalAction(
    label: label,
    hint: hint,
    onTap: onTap,
    focusNode: focusNode,
    child: child,
  );
}

/// Places a persistent deck before the newly drawn cards in a responsive flow.
///
/// [Wrap] is deliberate: cards are appended to the right and continue on the
/// next row when the viewport cannot fit another card. No feature page should
/// implement a second deck layout.
final class AppDeckResultFlow extends StatelessWidget {
  const AppDeckResultFlow({required this.deck, required this.cards, super.key});

  final Widget deck;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.start,
    crossAxisAlignment: WrapCrossAlignment.start,
    spacing: AppSpacing.lg,
    runSpacing: AppSpacing.lg,
    children: <Widget>[deck, ...cards],
  );
}
