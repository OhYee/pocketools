import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'liuyao uses registry module adapter and shared presentation contracts',
    () {
      final registry = File('lib/app/registry/default_tool_registry.dart')
          .readAsStringSync();
      final module = File(
        'lib/features/liuyao/presentation/liuyao_tool_module.dart',
      ).readAsStringSync();
      final page = File(
        'lib/features/liuyao/presentation/liuyao_tool_page.dart',
      ).readAsStringSync();
      final shell = File('lib/app/presentation/app_shell.dart')
          .readAsStringSync();

      expect(registry, contains('LiuyaoToolModule()'));
      expect(
        RegExp(r'\bLiuyaoToolModule\s*\(').allMatches(registry),
        hasLength(1),
      );
      expect(
        module,
        contains('implements ToolModule, ToolSessionAdapterProvider'),
      );
      expect(module, contains('ToolSessionAdapter('));
      expect(module, contains('LiuyaoSessionCodec()'));
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
      expect(shell, isNot(contains("'liuyao'")));
      expect(shell, isNot(contains('LiuyaoTool')));
    },
  );

  test(
    'liuyao has no private random platform channel asset or magic style bypass',
    () {
      final files = Directory('lib/features/liuyao')
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
          'Color(0x',
          'Duration(milliseconds:',
        ]) {
          expect(source, isNot(contains(forbidden)), reason: file.path);
        }
        expect(
          RegExp(r'\bColors\.').hasMatch(source),
          isFalse,
          reason: file.path,
        );
        expect(
          RegExp(r'SizedBox\(\s*(?:width|height):\s*\d').hasMatch(source),
          isFalse,
          reason: file.path,
        );
        expect(
          RegExp(r'EdgeInsets\.(?:all|symmetric)\(\s*\d').hasMatch(source),
          isFalse,
          reason: file.path,
        );
      }
    },
  );

  test(
    'only the line is a dedicated primitive and domain stays presentation free',
    () {
      final presentationFiles = Directory('lib/features/liuyao/presentation')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList(growable: false);
      final primitiveClasses = <String>[];
      final painterFiles = <String>[];
      for (final file in presentationFiles) {
        final source = file.readAsStringSync();
        primitiveClasses.addAll(
          RegExp(r'final class (\w+Primitive)\b')
              .allMatches(source)
              .map((match) => match.group(1)!),
        );
        if (source.contains('extends CustomPainter')) {
          painterFiles.add(file.path);
        }
      }
      expect(primitiveClasses, <String>['LiuyaoLinePrimitive']);
      expect(painterFiles, <String>[
        'lib/features/liuyao/presentation/widgets/liuyao_line_primitive.dart',
      ]);

      final pureFiles = <File>[
        ...Directory('lib/features/liuyao/domain')
            .listSync(recursive: true)
            .whereType<File>(),
        ...Directory('lib/features/liuyao/content')
            .listSync(recursive: true)
            .whereType<File>(),
      ].where((file) => file.path.endsWith('.dart'));
      for (final file in pureFiles) {
        final source = file.readAsStringSync();
        expect(source, isNot(contains('package:flutter/')), reason: file.path);
        expect(source, isNot(contains('/presentation/')), reason: file.path);
        expect(source, isNot(contains('FeedbackService')), reason: file.path);
        expect(source, isNot(contains('HapticFeedback')), reason: file.path);
      }
    },
  );
}
