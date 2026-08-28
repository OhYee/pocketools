import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/design_system/app_tokens.dart';
import 'package:pocketools/design_system/components/app_surfaces.dart';
import 'package:pocketools/design_system/components/app_tool_flow_layout.dart';

void main() {
  test('light and dark themes expose distinct shared surface tokens', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();
    final lightSurfaces = light.extension<AppSurfaceTokens>()!;
    final darkSurfaces = dark.extension<AppSurfaceTokens>()!;

    expect(lightSurfaces.canvas, AppSurfaceTokens.light.canvas);
    expect(darkSurfaces.canvas, AppSurfaceTokens.dark.canvas);
    expect(lightSurfaces.canvas, isNot(darkSurfaces.canvas));
    expect(lightSurfaces.shadow, isNot(darkSurfaces.shadow));
  });

  testWidgets('the shared flow gives the physical entity its own stage', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppToolFlowLayout(
            coreEntity: const AppSectionCard(child: SizedBox(height: 40)),
            actionBar: const SizedBox(height: 48),
            advancedOptions: const SizedBox(height: 48),
            outcome: const SizedBox(height: 48),
          ),
        ),
      ),
    );

    expect(find.byType(AppEntityStage), findsOneWidget);
    final card = tester.widget<Card>(find.byType(Card));
    expect(card.elevation, AppElevation.section);
    expect(card.shadowColor, AppSurfaceTokens.light.shadow);
  });

  testWidgets('result cards use the elevated result token and keep semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: AppResultCard(
            title: '总值',
            value: '17',
            details: 'D20 · 目标值 15',
          ),
        ),
      ),
    );

    expect(find.text('17'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(AppResultCard)).label,
      contains('总值 17'),
    );
    final card = tester.widget<Card>(find.byType(Card));
    expect(card.elevation, AppElevation.result);
    expect(card.shadowColor, AppSurfaceTokens.dark.shadow);
  });
}
