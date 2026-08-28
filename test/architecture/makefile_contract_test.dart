import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String makefile;

  setUpAll(() {
    makefile = File('Makefile').readAsStringSync();
  });

  test('default goal is help and all required targets are declared', () {
    expect(
      makefile,
      matches(RegExp(r'^\.DEFAULT_GOAL\s*:?=\s*help\s*$', multiLine: true)),
    );
    for (final target in <String>[
      'help',
      'bootstrap',
      'format',
      'analyze',
      'test',
      'test-unit',
      'test-widget',
      'build-web',
      'build-android',
      'build-android-release',
      'build-android-release-split-per-abi',
      'verify',
      'clean',
    ]) {
      expect(
        makefile,
        matches(RegExp('^${RegExp.escape(target)}\\s*:', multiLine: true)),
        reason: target,
      );
    }
  });

  test('Flutter checks provide an actionable FLUTTER_BIN error', () {
    expect(makefile, contains('ifndef FLUTTER_BIN'));
    expect(makefile, contains('check-flutter:'));
    expect(makefile, contains('Flutter not found. Set FLUTTER_BIN='));
    expect(makefile, contains('[ ! -x "\$(FLUTTER_BIN)" ]'));
  });

  test('clean is a thin flutter clean wrapper without broad deletion', () {
    final cleanStart = makefile.indexOf('\nclean:');
    expect(cleanStart, isNonNegative);
    final cleanRecipe = makefile.substring(cleanStart);

    expect(cleanRecipe, contains('"\$(FLUTTER_BIN)" clean'));
    expect(cleanRecipe, isNot(matches(RegExp(r'\brm\b'))));
    expect(cleanRecipe, isNot(matches(RegExp(r'\bfind\b'))));
    expect(cleanRecipe, isNot(contains('git clean')));
    expect(cleanRecipe, isNot(contains('../')));
  });

  test('verify delegates to the documented local gates', () {
    expect(
      makefile,
      matches(
        RegExp(
          r'^verify\s*:\s*check-format\s+analyze\s+test\s+build-web\b',
          multiLine: true,
        ),
      ),
    );
  });

  test(
    'keeps universal release separate from split-per-ABI release builds',
    () {
      final universalRecipe = _recipeFor(makefile, 'build-android-release');
      final splitRecipe = _recipeFor(
        makefile,
        'build-android-release-split-per-abi',
      );

      expect(
        universalRecipe,
        contains('"\$(FLUTTER_BIN)" build apk --release'),
      );
      expect(universalRecipe, isNot(contains('--split-per-abi')));
      expect(splitRecipe, contains('check-dart'));
      expect(
        splitRecipe,
        contains('"\$(FLUTTER_BIN)" build apk --release --split-per-abi'),
      );
      expect(splitRecipe, contains('tool/verify_android_apks.dart'));
    },
  );

  test('split-per-ABI release contract names every delivered ABI', () {
    final splitRecipe = _recipeFor(
      makefile,
      'build-android-release-split-per-abi',
    );

    for (final abi in <String>['arm64-v8a', 'armeabi-v7a', 'x86_64']) {
      expect(splitRecipe, contains(abi), reason: abi);
      expect(
        splitRecipe,
        contains('app-$abi-release.apk'),
        reason: 'expected output for $abi',
      );
    }
  });

  test('Dart discovery follows a symlinked Flutter installation', () {
    final sandbox = Directory.systemTemp.createTempSync(
      'pocketools-makefile-symlink-',
    );
    addTearDown(() => sandbox.deleteSync(recursive: true));

    final sdkBin = Directory('${sandbox.path}/sdk/bin')
      ..createSync(recursive: true);
    final flutter = File('${sdkBin.path}/flutter')
      ..writeAsStringSync('#!/bin/sh\nexit 0\n');
    final dart = File('${sdkBin.path}/cache/dart-sdk/bin/dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('#!/bin/sh\nexit 0\n');
    expect(
      Process.runSync('chmod', <String>[
        '+x',
        flutter.path,
        dart.path,
      ]).exitCode,
      0,
    );

    final launcher = Directory('${sandbox.path}/launcher')
      ..createSync(recursive: true);
    final linkedFlutter = Link('${launcher.path}/flutter')
      ..createSync(flutter.path);
    final environment = Map<String, String>.of(Platform.environment)
      ..remove('DART_BIN');

    final result = Process.runSync(
      'make',
      <String>[
        '--no-print-directory',
        '-f',
        File('Makefile').absolute.path,
        'check-dart',
        'FLUTTER_BIN=${linkedFlutter.path}',
      ],
      workingDirectory: sandbox.path,
      environment: environment,
    );

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });
}

String _recipeFor(String makefile, String target) {
  final start = makefile.indexOf(RegExp('^$target\\s*:', multiLine: true));
  expect(start, isNonNegative, reason: target);
  final recipeStart = makefile.indexOf('\n', start);
  expect(recipeStart, isNonNegative, reason: target);
  final nextTarget = RegExp(
    r'^\S.*:',
    multiLine: true,
  ).firstMatch(makefile.substring(recipeStart + 1));
  final end = nextTarget == null
      ? makefile.length
      : recipeStart + 1 + nextTarget.start;
  return makefile.substring(start, end);
}
