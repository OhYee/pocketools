import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/design_system/app_tokens.dart';
import 'package:pocketools/design_system/components/app_button.dart';

void main() {
  testWidgets('AppButton centralizes minimum size and semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppButton(
            label: '执行',
            semanticLabel: '执行随机工具',
            onPressed: () {},
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(FilledButton));
    expect(size.height, greaterThanOrEqualTo(AppSizes.minimumTapTarget));
    expect(size.width, greaterThanOrEqualTo(AppSizes.minimumTapTarget));
    expect(
      tester.getSemantics(find.byType(AppButton)).label,
      contains('执行随机工具'),
    );
  });

  testWidgets('loading state disables activation and announces progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: AppButton(label: '掷骰', onPressed: null, loading: true),
        ),
      ),
    );

    expect(find.text('处理中'), findsOneWidget);
    expect(tester.getSemantics(find.byType(AppButton)).value, '正在处理');
  });

  testWidgets('pressed feedback is owned by the shared motion token', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppButton(label: '执行', onPressed: () {}),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));

    final translated = tester
        .widgetList<Transform>(find.byType(Transform))
        .any(
          (transform) =>
              transform.transform.getTranslation().y ==
              AppMotionValues.buttonPressTranslation,
        );
    expect(translated, isTrue);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 90));
  });
}
