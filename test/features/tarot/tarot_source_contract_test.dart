import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tarot domain and content stay pure and presentation-independent', () {
    final files = <File>[
      ...Directory('lib/features/tarot/domain')
          .listSync(recursive: true)
          .whereType<File>(),
      ...Directory('lib/features/tarot/content')
          .listSync(recursive: true)
          .whereType<File>(),
    ].where((file) => file.path.endsWith('.dart'));

    expect(files, isNotEmpty);
    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('package:flutter/')), reason: file.path);
      expect(source, isNot(contains('/presentation/')), reason: file.path);
    }
  });

  test(
    'presentation composes shared contracts without platform or RNG bypass',
    () {
      final page = File('lib/features/tarot/presentation/tarot_tool_page.dart')
          .readAsStringSync();
      for (final sharedType in <String>[
        'AppToolScaffold(',
        'AppButton(',
        'AppChoiceGroup<',
        'AppSegmentedControl<',
        'AppEntityStateView(',
        'AppSectionCard(',
        'AppToolTheme(',
        'ToolSessionAdapter',
      ]) {
        expect(page, contains(sharedType), reason: sharedType);
      }
      expect(
        page,
        isNot(matches(RegExp(r'\b(?:Filled|Outlined|Elevated)Button\s*\('))),
      );

      final files = Directory('lib/features/tarot/presentation')
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
        expect(
          source,
          isNot(matches(RegExp(r'\bColors\.'))),
          reason: file.path,
        );
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
    'animation widgets consume frozen results without random dependencies',
    () {
      final files = Directory('lib/features/tarot/presentation/widgets')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in files) {
        final source = file.readAsStringSync();
        expect(source, isNot(contains('RandomSource')), reason: file.path);
        expect(source, isNot(contains('nextInt(')), reason: file.path);
        expect(source, isNot(contains('TarotReader(')), reason: file.path);
        expect(source, isNot(contains('Image.asset(')), reason: file.path);
        expect(source, isNot(contains('DecorationImage(')), reason: file.path);
      }
    },
  );
}
