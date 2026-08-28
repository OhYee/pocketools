import 'package:flutter/material.dart';

import '../../core/tools/tool_module.dart';
import '../app_tokens.dart';

@immutable
final class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

final class AppNavShell extends StatelessWidget {
  const AppNavShell({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.child,
    this.accent,
    super.key,
  });

  final List<AppNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget child;
  final ToolAccent? accent;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    final accentColor = accent == null
        ? Theme.of(context).colorScheme.primary
        : context.appColors.accentFor(accent!);
    final accentSurface = accent == null
        ? Theme.of(context).colorScheme.primaryContainer
        : context.appColors.accentSurfaceFor(accent!);
    if (desktop) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= AppBreakpoints.wide,
              minExtendedWidth: AppSizes.navigationSidebar,
              leading: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.xl,
                ),
                child: Tooltip(
                  message: '万象匣',
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
              ),
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelected,
              labelType: MediaQuery.sizeOf(context).width >= AppBreakpoints.wide
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              indicatorColor: accentSurface,
              selectedIconTheme: IconThemeData(color: accentColor),
              selectedLabelTextStyle: TextStyle(color: accentColor),
              destinations: items
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(growable: false),
            ),
            VerticalDivider(width: 1, color: context.appColors.border),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: accentSurface,
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
            (states) => states.contains(WidgetState.selected)
                ? IconThemeData(color: accentColor)
                : null,
          ),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
            (states) => states.contains(WidgetState.selected)
                ? TextStyle(color: accentColor)
                : null,
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          destinations: items
              .map(
                (item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}
