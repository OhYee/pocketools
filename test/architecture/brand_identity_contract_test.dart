import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android, Web, and Flutter expose the 万象匣 brand', () {
    final androidManifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final webManifest = File('web/manifest.json').readAsStringSync();
    final webIndex = File('web/index.html').readAsStringSync();
    final appSource = File('lib/app/pocketools_app.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(androidManifest, contains('android:label="万象匣"'));
    expect(androidManifest, contains('android:icon="@mipmap/ic_launcher"'));
    expect(webManifest, contains('"name": "万象匣"'));
    expect(webManifest, contains('"short_name": "万象匣"'));
    expect(webIndex, contains('<title>万象匣</title>'));
    expect(appSource, contains("title: '万象匣'"));
    expect(pubspec, contains('- assets/branding/'));
  });

  test('every platform brand image exists and is non-empty', () {
    for (final path in <String>[
      'assets/branding/app_icon.png',
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
      'web/favicon.png',
      'web/icons/Icon-192.png',
      'web/icons/Icon-512.png',
      'web/icons/Icon-maskable-192.png',
      'web/icons/Icon-maskable-512.png',
    ]) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      expect(file.lengthSync(), greaterThan(0), reason: path);
    }
  });
}
