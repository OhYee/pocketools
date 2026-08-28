import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'tarot uses registry, module, adapter and shared presentation contracts',
    () {
      final registry = File('lib/app/registry/default_tool_registry.dart')
          .readAsStringSync();
      final module = File(
        'lib/features/tarot/presentation/tarot_tool_module.dart',
      ).readAsStringSync();
      final page = File('lib/features/tarot/presentation/tarot_tool_page.dart')
          .readAsStringSync();
      final shell = File('lib/app/presentation/app_shell.dart')
          .readAsStringSync();

      expect(registry, contains('TarotToolModule()'));
      expect(
        RegExp(r'\bTarotToolModule\s*\(').allMatches(registry),
        hasLength(1),
      );
      expect(
        module,
        contains('implements ToolModule, ToolSessionAdapterProvider'),
      );
      expect(module, contains('ToolSessionAdapter('));
      expect(module, contains('TarotSessionCodec()'));
      expect(page, contains('widget.sessionAdapter.createSession('));
      expect(page, isNot(contains('SessionRecord(')));
      for (final sharedContract in <String>[
        'AppToolScaffold(',
        'AppButton(',
        'AppChoiceGroup<',
        'AppSegmentedControl<',
        'AppEntityStateView(',
        'AppSectionCard(',
        'AppToolTheme(',
        'widget.moduleContext.randomSource',
        'widget.moduleContext.feedbackService',
      ]) {
        expect(page, contains(sharedContract), reason: sharedContract);
      }
      expect(shell, isNot(contains("'tarot'")));
      expect(shell, isNot(contains('TarotTool')));
    },
  );

  test(
    'tarot has no private RNG, platform haptic or runtime card asset bypass',
    () {
      final files = Directory('lib/features/tarot')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList(growable: false);

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
          'math.Random(',
          'Image.asset(',
          'Image.network(',
          'AssetImage(',
          'NetworkImage(',
          'DecorationImage(',
          'SvgPicture.',
        ]) {
          expect(source, isNot(contains(forbidden)), reason: file.path);
        }
      }

      final pubspecLines = File('pubspec.yaml').readAsLinesSync();
      final activeAssetDeclarations = pubspecLines.where((line) {
        final trimmed = line.trimLeft();
        return !trimmed.startsWith('#') &&
            (trimmed == 'assets:' || trimmed.startsWith('- assets/'));
      });
      expect(activeAssetDeclarations, contains('  assets:'));
      expect(activeAssetDeclarations, contains('    - assets/runtime/'));
    },
  );

  test('tarot domain and content cannot depend on Flutter or presentation', () {
    final files = <File>[
      ...Directory('lib/features/tarot/domain')
          .listSync(recursive: true)
          .whereType<File>(),
      ...Directory('lib/features/tarot/content')
          .listSync(recursive: true)
          .whereType<File>(),
    ].where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('package:flutter/')), reason: file.path);
      expect(source, isNot(contains('/presentation/')), reason: file.path);
      expect(source, isNot(contains('FeedbackService')), reason: file.path);
      expect(source, isNot(contains('HapticFeedback')), reason: file.path);
    }
  });
}
