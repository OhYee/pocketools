import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('domain and content stay Flutter and presentation independent', () {
    final files = Directory('lib/features/liuyao/domain')
        .listSync(recursive: true)
        .whereType<File>()
        .followedBy(
          Directory('lib/features/liuyao/content')
              .listSync(recursive: true)
              .whereType<File>(),
        );
    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('package:flutter/')), reason: file.path);
      expect(source, isNot(contains('/presentation/')), reason: file.path);
      expect(source, isNot(contains('HapticFeedback')), reason: file.path);
      expect(source, isNot(contains('Random(')), reason: file.path);
    }
  });

  test('presentation uses injected random feedback and shared components', () {
    final page = File('lib/features/liuyao/presentation/liuyao_tool_page.dart')
        .readAsStringSync();
    expect(page, contains('ToolModuleContext'));
    expect(page, contains('AppToolScaffold'));
    expect(page, contains('AppButton'));
    expect(page, contains('AppEntityStateView'));
    expect(page, contains('sessionAdapter.createSession'));
    expect(page, isNot(contains('Random(')));
    expect(page, isNot(contains('HapticFeedback')));
    expect(page, isNot(contains('Color(')));
    expect(page, isNot(contains('Duration(milliseconds:')));
  });

  test('only the line visual defines a Liuyao CustomPainter', () {
    final files = Directory('lib/features/liuyao/presentation')
        .listSync(recursive: true)
        .whereType<File>();
    final painters = <String>[];
    for (final file in files) {
      if (file.readAsStringSync().contains('extends CustomPainter')) {
        painters.add(file.path);
      }
    }
    expect(painters, <String>[
      'lib/features/liuyao/presentation/widgets/liuyao_line_primitive.dart',
    ]);
  });

  test('content stays bundled without external assets or network access', () {
    final source = File(
      'lib/features/liuyao/content/liuyao_content_catalog.dart',
    ).readAsStringSync();
    expect(source, contains("contentVersion = '1.0.0'"));
    expect(source, contains('all 64 hexagrams'));
    expect(source, isNot(contains('Image.asset')));
    expect(source, isNot(contains('http://')));
    expect(source, isNot(contains('https://')));
  });
}
