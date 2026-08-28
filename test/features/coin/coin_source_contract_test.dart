import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('coin domain stays pure and does not depend on presentation', () {
    final files = Directory('lib/features/coin/domain')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    expect(files, isNotEmpty);
    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('package:flutter/')), reason: file.path);
      expect(source, isNot(contains('/presentation/')), reason: file.path);
    }
  });

  test(
    'coin presentation composes shared contracts without platform bypass',
    () {
      final page = File('lib/features/coin/presentation/coin_tool_page.dart')
          .readAsStringSync();
      for (final sharedType in <String>[
        'AppToolScaffold(',
        'AppButton(',
        'AppStepper(',
        'AppSegmentedControl<',
        'AppEntityStateView(',
        'AppSectionCard(',
        'AppToolTheme(',
      ]) {
        expect(page, contains(sharedType), reason: sharedType);
      }
      expect(page, contains('ToolSessionAdapter'));
      expect(
        page,
        isNot(matches(RegExp(r'\b(?:Filled|Outlined|Elevated)Button\s*\('))),
      );

      final files = Directory('lib/features/coin/presentation')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      for (final file in files) {
        final source = file.readAsStringSync();
        for (final forbidden in <String>[
          "import 'package:flutter/services.dart'",
          'HapticFeedback.',
          'MethodChannel(',
          'SystemChannels.',
          'SecureRandomSource(',
          'SecureEntropySource(',
          'Random.secure(',
        ]) {
          expect(source, isNot(contains(forbidden)), reason: file.path);
        }
        for (final pattern in <RegExp>[
          RegExp(r'\bColor\s*\('),
          RegExp(r'\bDuration\s*\('),
          RegExp(r'BorderRadius\.circular\s*\(\s*\d'),
          RegExp(r'EdgeInsets\.(?:all|only|symmetric)\s*\([^)]*\b\d'),
          RegExp(r'SizedBox\s*\([^)]*(?:height|width)\s*:\s*\d'),
        ]) {
          expect(source, isNot(matches(pattern)), reason: file.path);
        }
      }
    },
  );

  test(
    'coin animation receives frozen results and has no random dependency',
    () {
      final widgets = Directory('lib/features/coin/presentation/widgets')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in widgets) {
        final source = file.readAsStringSync();
        expect(source, isNot(contains('RandomSource')), reason: file.path);
        expect(source, isNot(contains('nextInt(')), reason: file.path);
        expect(source, isNot(contains('CoinTosser(')), reason: file.path);
      }
    },
  );
}
