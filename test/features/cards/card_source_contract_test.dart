import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('card page composes shared controls without local style magic', () {
    final source = File('lib/features/cards/presentation/card_tool_page.dart')
        .readAsStringSync();

    for (final sharedType in <String>[
      'AppButton(',
      'AppStepper(',
      'AppEntityStateView(',
      'AppSectionCard(',
      'AppToolScaffold(',
      'AppToolTheme(',
    ]) {
      expect(source, contains(sharedType), reason: sharedType);
    }
    expect(
      source,
      isNot(matches(RegExp(r'\b(?:Filled|Outlined|Text|Elevated)Button\s*\('))),
    );
    for (final pattern in <RegExp>[
      RegExp(r'\bColor\s*\('),
      RegExp(r'\bDuration\s*\('),
      RegExp(r'BorderRadius\.circular\s*\(\s*\d'),
      RegExp(r'EdgeInsets\.(?:all|only|symmetric)\s*\([^)]*\b\d'),
      RegExp(r'SizedBox\s*\([^)]*(?:height|width)\s*:\s*\d'),
    ]) {
      expect(source, isNot(matches(pattern)), reason: pattern.pattern);
    }
  });

  test('card presentation receives randomness and feedback by abstraction', () {
    final files = Directory('lib/features/cards/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('SecureRandomSource(')), reason: file.path);
      expect(source, isNot(contains('HapticFeedback.')), reason: file.path);
    }
  });
}
