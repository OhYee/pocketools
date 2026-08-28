import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String makefile;
  late String bootstrap;
  late String worker;
  late String index;

  setUpAll(() {
    makefile = File('Makefile').readAsStringSync();
    bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();
    worker = File('web/pocketools_service_worker.js').readAsStringSync();
    index = File('web/index.html').readAsStringSync();
  });

  test(
    'Web build is clean, local-resource-only, and verifies custom output',
    () {
      expect(makefile, contains('WEB_BUILD_DIR := \$(CURDIR)/build/web'));
      expect(makefile, contains('rm -rf -- "\$(WEB_BUILD_DIR)"'));
      expect(makefile, contains('build web --no-web-resources-cdn'));
      expect(makefile, contains('pocketools_service_worker.js'));
      expect(makefile, contains('tool/verify_web_precache.dart'));
      expect(
        makefile,
        contains('rm -f -- "\$(WEB_BUILD_DIR)/flutter_service_worker.js"'),
      );
      expect(
        makefile,
        contains('test ! -e "\$(WEB_BUILD_DIR)/flutter_service_worker.js"'),
      );
      expect(makefile, isNot(contains('grep -q "flutter_service_worker.js"')));
      expect(makefile, isNot(contains('grep -q "serviceWorkerSettings"')));
      expect(makefile, contains("grep -q 'pocketools-pwa-v3'"));
      expect(makefile, contains("grep -q 'pocketools_service_worker.js'"));
    },
  );

  test(
    'bootstrap registers custom worker without deprecated loader settings',
    () {
      expect(bootstrap, contains('pocketools_service_worker.js'));
      expect(bootstrap, contains('updateViaCache: "none"'));
      expect(bootstrap, contains('canvasKitBaseUrl: "canvaskit/"'));
      expect(bootstrap, isNot(contains('serviceWorkerSettings')));
      expect(bootstrap, isNot(contains('flutter_service_worker.js')));
      expect(
        bootstrap.indexOf('.catch('),
        lessThan(bootstrap.indexOf('_flutter.loader.load')),
      );
    },
  );

  test(
    'worker precaches critical shell, assets, shaders, and engine variants',
    () {
      for (final resource in <String>[
        'index.html',
        'flutter_bootstrap.js',
        'flutter.js',
        'main.dart.js',
        'manifest.json',
        'icons/Icon-192.png',
        'icons/Icon-maskable-512.png',
        'assets/AssetManifest.bin',
        'assets/FontManifest.json',
        'assets/fonts/MaterialIcons-Regular.otf',
        'assets/shaders/ink_sparkle.frag',
        'canvaskit/canvaskit.wasm',
        'canvaskit/chromium/canvaskit.wasm',
        'canvaskit/webparagraph/canvaskit.wasm',
        'canvaskit/skwasm.wasm',
        'canvaskit/skwasm_heavy.wasm',
        'canvaskit/wimp.wasm',
      ]) {
        expect(worker, contains('"$resource"'), reason: resource);
      }
      expect(worker, contains('request.mode === "navigate"'));
      expect(worker, contains('cache: "no-store"'));
      expect(worker, contains('cache.put(pocketoolsIndexRequest'));
      expect(worker, contains('request.method !== "GET"'));
      expect(
        worker,
        contains('requestUrl.origin !== pocketoolsScopeUrl.origin'),
      );
    },
  );

  test('worker cache cleanup is restricted to the Pocketools prefix', () {
    expect(worker, contains('key.startsWith(POCKETOOLS_CACHE_PREFIX)'));
    expect(worker, contains('key !== POCKETOOLS_CACHE_NAME'));
    expect(worker, isNot(contains('keys.map((key) => caches.delete(key))')));
  });

  test('manifest remains standalone and allows every orientation', () {
    final manifest = jsonDecode(
      File('web/manifest.json').readAsStringSync(),
    ) as Map<String, Object?>;

    expect(manifest['display'], 'standalone');
    expect(manifest['orientation'], 'any');
  });

  test('Web shell declares a device-width viewport for responsive layout', () {
    expect(
      index,
      contains(
        '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
      ),
    );
  });
}
