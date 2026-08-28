import 'dart:io';

void main(List<String> arguments) {
  if (arguments.length < 2) {
    stderr.writeln(
      'Usage: dart tool/verify_android_apks.dart OUTPUT_DIR APK_NAME [APK_NAME ...]',
    );
    exitCode = 64;
    return;
  }

  final outputDirectory = Directory(arguments.first).absolute;
  final apkNames = arguments.skip(1).toList(growable: false);

  if (!outputDirectory.existsSync()) {
    stderr.writeln(
      'Android APK output directory does not exist: '
      '${outputDirectory.path}',
    );
    exitCode = 1;
    return;
  }

  final missing = <String>[];
  final empty = <String>[];
  final sizes = <String, int>{};
  for (final apkName in apkNames) {
    final apk = File('${outputDirectory.path}/$apkName');
    if (!apk.existsSync()) {
      missing.add(apkName);
      continue;
    }

    final size = apk.lengthSync();
    if (size == 0) {
      empty.add(apkName);
      continue;
    }
    sizes[apkName] = size;
  }

  if (missing.isNotEmpty || empty.isNotEmpty) {
    stderr.writeln('Android split-per-ABI APK verification failed.');
    if (missing.isNotEmpty) {
      stderr.writeln('Missing APKs: ${missing.join(', ')}');
    }
    if (empty.isNotEmpty) {
      stderr.writeln('Empty APKs: ${empty.join(', ')}');
    }
    stderr.writeln('Expected output directory: ${outputDirectory.path}');
    stderr.writeln('Expected APKs: ${apkNames.join(', ')}');
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Verified ${apkNames.length} Android split-per-ABI release APKs in '
    '${outputDirectory.path}:',
  );
  for (final apkName in apkNames) {
    stdout.writeln('  $apkName (${sizes[apkName]} bytes)');
  }
}
