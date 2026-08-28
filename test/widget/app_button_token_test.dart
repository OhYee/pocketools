import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/design_system/app_tokens.dart';
import 'package:pocketools/design_system/components/app_button.dart';

void main() {
  testWidgets('one motion token override changes the shared AppButton', (
    tester,
  ) async {
    final theme = AppTheme.light().copyWith(
      extensions: <ThemeExtension<dynamic>>[
        AppSemanticColors.light,
        const AppMotionTokens.standard().copyWith(
          press: const Duration(seconds: 1),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: AppButton(label: '统一按钮', onPressed: () {}),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final translations = tester
        .widgetList<Transform>(find.byType(Transform))
        .map((transform) => transform.transform.getTranslation().y);
    expect(
      translations.any(
        (translation) =>
            translation > AppSpacing.zero &&
            translation < AppMotionValues.buttonPressTranslation,
      ),
      isTrue,
    );
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(AppSizes.minimumTapTarget),
    );

    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
  });
}
