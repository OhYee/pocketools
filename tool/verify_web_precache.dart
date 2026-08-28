import 'dart:io';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart tool/verify_web_precache.dart BUILD_WEB_DIR');
    exitCode = 64;
    return;
  }

  final buildDirectory = Directory(arguments.single).absolute;
  final workerFile = File(
    '${buildDirectory.path}/pocketools_service_worker.js',
  );
  if (!workerFile.existsSync()) {
    stderr.writeln('Missing built Pocketools service worker.');
    exitCode = 1;
    return;
  }

  final worker = workerFile.readAsStringSync();
  final listMatch = RegExp(
    r'const POCKETOOLS_PRECACHE_RESOURCES = Object\.freeze\(\[([\s\S]*?)\]\);',
  ).firstMatch(worker);
  if (listMatch == null) {
    stderr.writeln('Built service worker has no parseable precache list.');
    exitCode = 1;
    return;
  }

  final resources = RegExp(r'"([^"\\]+)"')
      .allMatches(listMatch.group(1)!)
      .map((match) => match.group(1)!)
      .toList();
  if (resources.isEmpty || resources.toSet().length != resources.length) {
    stderr.writeln('Precache resources must be non-empty and unique.');
    exitCode = 1;
    return;
  }

  final missing = <String>[];
  for (final resource in resources) {
    if (resource.startsWith('/') ||
        resource.contains('..') ||
        resource.contains('?') ||
        resource.contains('#')) {
      stderr.writeln('Unsafe precache resource path: $resource');
      exitCode = 1;
      return;
    }
    final relativeFile = resource == './' ? 'index.html' : resource;
    if (!File('${buildDirectory.path}/$relativeFile').existsSync()) {
      missing.add(resource);
    }
  }
  if (missing.isNotEmpty) {
    stderr.writeln('Missing precache build outputs: ${missing.join(', ')}');
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Verified ${resources.length} Pocketools precache resources in '
    '${buildDirectory.path}.',
  );
}
