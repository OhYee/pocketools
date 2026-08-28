import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/design_system/components/app_choice_group.dart';
import 'package:pocketools/design_system/components/app_segmented_control.dart';

void main() {
  testWidgets('shared selection controls centrally support disabled state', (
    tester,
  ) async {
    var segmentChanges = 0;
    var choiceChanges = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: <Widget>[
              AppSegmentedControl<int>(
                label: '模式',
                segments: const <AppSegment<int>>[
                  AppSegment(value: 1, label: '一'),
                  AppSegment(value: 2, label: '二'),
                ],
                selected: 1,
                enabled: false,
                onSelected: (_) => segmentChanges++,
              ),
              AppChoiceGroup<int>(
                label: '数量',
                choices: const <AppChoice<int>>[
                  AppChoice(value: 3, label: '3'),
                  AppChoice(value: 5, label: '5'),
                ],
                selected: 3,
                enabled: false,
                onSelected: (_) => choiceChanges++,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('二'));
    await tester.tap(find.text('5'));

    expect(segmentChanges, 0);
    expect(choiceChanges, 0);
    expect(
      tester
          .widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>))
          .onSelectionChanged,
      isNull,
    );
  });
}
