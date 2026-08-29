import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String ci;
  late String release;
  late String androidBuild;

  setUpAll(() {
    ci = File('.github/workflows/ci.yml').readAsStringSync();
    release = File('.github/workflows/release.yml').readAsStringSync();
    androidBuild = File('android/app/build.gradle.kts').readAsStringSync();
  });

  test('CI verifies source and archives Web and Android builds', () {
    expect(ci, contains('pull_request:'));
    expect(ci, contains('workflow_dispatch:'));
    expect(ci, contains('run: make verify'));
    expect(ci, contains('run: make build-android-release-split-per-abi'));
    expect(ci, contains('actions/upload-artifact@v4'));
    expect(ci, contains('build/web'));
    expect(ci, contains('app-*-release.apk'));
    expect(ci, contains('permissions:\n  contents: read'));
  });

  test('tag release validates version, signing, assets, and checksums', () {
    expect(release, contains("- 'v*'"));
    expect(release, contains('contents: write'));
    expect(release, contains('environment: release'));
    expect(release, contains('does not match pubspec version'));
    for (final secret in <String>[
      'ANDROID_KEYSTORE_BASE64',
      'ANDROID_KEY_ALIAS',
      'ANDROID_KEY_PASSWORD',
      'ANDROID_STORE_PASSWORD',
    ]) {
      expect(release, contains('\${{ secrets.$secret }}'));
    }
    expect(release, contains('apksigner'));
    expect(release, contains('sha256sum'));
    expect(release, contains('gh release create'));
    expect(release, contains('--verify-tag'));
  });

  test('Gradle uses release secrets only when the complete set exists', () {
    expect(androidBuild, contains('hasReleaseSigning'));
    expect(androidBuild, contains('create("release")'));
    expect(
      androidBuild,
      contains('if (hasReleaseSigning) "release" else "debug"'),
    );
  });
}
