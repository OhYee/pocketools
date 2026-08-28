import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/design_system/components/app_nav_shell.dart';
import 'package:pocketools/design_system/components/app_tool_scaffold.dart';

void main() {
  testWidgets('desktop keeps the sidebar left of an expanded main body', (
    tester,
  ) async {
    _setViewport(tester, const Size(1440, 900));

    await tester.pumpWidget(
      _themed(
        AppNavShell(
          items: _navigationItems,
          selectedIndex: 0,
          onSelected: (_) {},
          child: const ColoredBox(
            key: Key('desktop-main-body'),
            color: Colors.white,
          ),
        ),
      ),
    );

    final rail = find.byType(NavigationRail);
    final mainBody = find.byKey(const Key('desktop-main-body'));
    expect(rail, findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      find.ancestor(of: mainBody, matching: find.byType(Expanded)),
      findsOneWidget,
    );

    final railRect = tester.getRect(rail);
    final mainBodyRect = tester.getRect(mainBody);
    expect(mainBodyRect.left, greaterThanOrEqualTo(railRect.right));
    expect(mainBodyRect.width, greaterThan(0));
    expect(mainBodyRect.top, 0);
    expect(mainBodyRect.bottom, 900);
  });

  testWidgets('tool scaffold aligns the shared content from the top', (
    tester,
  ) async {
    _setViewport(tester, const Size(1440, 900));

    await tester.pumpWidget(
      _themed(
        AppToolScaffold(
          title: '主体标题',
          primary: const SizedBox(key: Key('tool-primary'), height: 120),
        ),
      ),
    );

    final alignment = tester.widget<Align>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Align),
      ),
    );
    expect(alignment.alignment, Alignment.topCenter);
    expect(tester.getRect(find.text('主体标题')).top, lessThan(100));
  });

  testWidgets('narrow screens retain usable bottom navigation', (tester) async {
    _setViewport(tester, const Size(390, 844));
    var selectedIndex = -1;

    await tester.pumpWidget(
      _themed(
        AppNavShell(
          items: _navigationItems,
          selectedIndex: 0,
          onSelected: (index) => selectedIndex = index,
          child: const SizedBox(),
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    await tester.tap(find.text('设置'));
    expect(selectedIndex, 2);
  });
}

const _navigationItems = <AppNavItem>[
  AppNavItem(label: '首页', icon: Icons.home_outlined, selectedIcon: Icons.home),
  AppNavItem(
    label: '历史',
    icon: Icons.history_outlined,
    selectedIcon: Icons.history,
  ),
  AppNavItem(
    label: '设置',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];

Widget _themed(Widget child) =>
    MaterialApp(theme: AppTheme.light(), home: child);

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
