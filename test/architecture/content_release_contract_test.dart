import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/features/liuyao/content/liuyao_content_catalog.dart';
import 'package:pocketools/features/tarot/content/tarot_content_catalog.dart';

void main() {
  group('v0.1.0 independent content release contract', () {
    test('bundled content catalogs remain complete and internally valid', () {
      expect(TarotContentCatalog.contentVersion, '1.0.0');
      expect(TarotContentCatalog.validate(), isEmpty);
      expect(LiuyaoContentCatalog.contentVersion, '1.1.0');
      expect(LiuyaoContentCatalog.validate(), isEmpty);
    });

    test('content catalogs have no external package or I/O imports', () {
      const catalogDirectories = <String>[
        'lib/features/tarot/content',
        'lib/features/liuyao/content',
      ];
      final violations = <String>[];

      for (final directoryPath in catalogDirectories) {
        final files = Directory(directoryPath)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'));
        for (final file in files) {
          final source = file.readAsStringSync();
          final imports = RegExp(
            r'''^import\s+['"]([^'"]+)['"]''',
            multiLine: true,
          ).allMatches(source);
          for (final match in imports) {
            final import = match.group(1)!;
            if ((import.startsWith('dart:') && import != 'dart:collection') ||
                import.startsWith('package:')) {
              violations.add('${file.path}: $import');
            }
          }
        }
      }

      expect(violations, isEmpty);
    });

    test('feature runtime cannot fetch content or register review assets', () {
      const featureDirectories = <String>[
        'lib/features/tarot',
        'lib/features/liuyao',
      ];
      const forbiddenRuntimeTokens = <String>[
        'package:http',
        'dart:io',
        'HttpClient',
        'NetworkImage(',
        'Image.network(',
        'AssetImage(',
        'Image.asset(',
        'rootBundle',
        'DefaultAssetBundle',
        'loadString(',
        'http://',
        'https://',
        'docs/design',
        'output/imagegen',
      ];
      final violations = <String>[];

      for (final directoryPath in featureDirectories) {
        final files = Directory(directoryPath)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'));
        for (final file in files) {
          final source = file.readAsStringSync();
          for (final token in forbiddenRuntimeTokens) {
            if (source.contains(token)) {
              violations.add('${file.path}: $token');
            }
          }
        }
      }

      final activePubspec = File('pubspec.yaml')
          .readAsLinesSync()
          .map((line) => line.split('#').first)
          .where((line) => line.trim().isNotEmpty)
          .join('\n');
      expect(
        RegExp(r'^\s+assets\s*:', multiLine: true).hasMatch(activePubspec),
        isTrue,
      );
      expect(activePubspec, contains('assets/runtime/'));
      expect(
        RegExp(r'^\s+fonts\s*:', multiLine: true).hasMatch(activePubspec),
        isFalse,
      );
      expect(activePubspec, isNot(contains('docs/design')));
      expect(activePubspec, isNot(contains('output/imagegen')));
      expect(violations, isEmpty);
    });
  });
}
