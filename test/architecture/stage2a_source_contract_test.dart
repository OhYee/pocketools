import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/registry/default_tool_registry.dart';

void main() {
  test(
    'default registry is the ordered source for exactly seven home tools',
    () {
      final registry = buildDefaultToolRegistry();

      expect(registry.modules.map((module) => module.descriptor.id), <String>[
        'tarot',
        'liuyao',
        'd20',
        'coin',
        'cards',
        'multi_divination',
        'encyclopedia',
      ]);

      final home = File('lib/features/home/presentation/home_page.dart')
          .readAsStringSync();
      final shell = File('lib/app/presentation/app_shell.dart')
          .readAsStringSync();
      expect(home, contains('for (final module in registry.modules)'));
      expect('AppToolCard('.allMatches(home), hasLength(1));
      expect(home, isNot(matches(RegExp(r'(?:if|switch)\s*\([^)]*\.id'))));
      expect(shell, isNot(matches(RegExp(r'(?:if|switch)\s*\([^)]*\.id'))));
      for (final id in <String>[
        'tarot',
        'liuyao',
        'd20',
        'coin',
        'cards',
        'multi_divination',
        'encyclopedia',
      ]) {
        expect(home, isNot(contains("'$id'")), reason: id);
        expect(shell, isNot(contains("'$id'")), reason: id);
      }
    },
  );

  test('card presentation has no platform RNG haptics or magic styles', () {
    final files = Directory('lib/features/cards/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    expect(files, isNotEmpty);
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
  });
}
