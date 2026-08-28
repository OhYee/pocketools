import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DND page composes shared controls instead of raw button styles', () {
    final source = File('lib/features/dice/presentation/dice_tool_page.dart')
        .readAsStringSync();

    for (final sharedType in <String>[
      'AppButton(',
      'AppStepper(',
      'AppSegmentedControl<',
      'AppSectionCard(',
      'AppResultCard(',
    ]) {
      expect(source, contains(sharedType), reason: sharedType);
    }
    expect(
      source,
      isNot(matches(RegExp(r'\b(?:Filled|Outlined|Text|Elevated)Button\s*\('))),
    );
  });

  test('DND page has no local color, duration, radius, or numeric spacing', () {
    final source = File('lib/features/dice/presentation/dice_tool_page.dart')
        .readAsStringSync();

    final forbidden = <RegExp>[
      RegExp(r'\bColor\s*\('),
      RegExp(r'\bDuration\s*\('),
      RegExp(r'BorderRadius\.circular\s*\(\s*\d'),
      RegExp(r'EdgeInsets\.(?:all|only|symmetric)\s*\([^)]*\b\d'),
      RegExp(r'SizedBox\s*\([^)]*(?:height|width)\s*:\s*\d'),
    ];
    for (final pattern in forbidden) {
      expect(source, isNot(matches(pattern)), reason: pattern.pattern);
    }
  });

  test('shared AppButton owns the common 48px minimum target', () {
    final source = File('lib/design_system/components/app_button.dart')
        .readAsStringSync();

    expect(source, contains('AppSizes.minimumTapTarget'));
    expect(source, contains('Semantics('));
    expect(source, contains('semanticLabel ?? label'));
  });

  test('presentation and feedback code do not create a random source', () {
    final files = <File>[
      ...Directory('lib/app/presentation')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
      ...Directory('lib/app/platform')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
      ...Directory('lib/features/dice/presentation')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
      ...Directory('lib/core/feedback')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
    ];

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('SecureRandomSource(')), reason: file.path);
      expect(
        source,
        isNot(contains('SecureEntropySource(')),
        reason: file.path,
      );
    }
  });
}
