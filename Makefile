PROJECT_FLUTTER := $(CURDIR)/.tooling/flutter/bin/flutter
WEB_BUILD_DIR := $(CURDIR)/build/web
ANDROID_APK_OUTPUT_DIR := $(CURDIR)/build/app/outputs/flutter-apk

ifndef FLUTTER_BIN
ifneq ($(wildcard $(PROJECT_FLUTTER)),)
FLUTTER_BIN := $(PROJECT_FLUTTER)
else
FLUTTER_BIN := $(shell command -v flutter 2>/dev/null)
endif
endif

FLUTTER_REAL_BIN := $(shell realpath "$(FLUTTER_BIN)" 2>/dev/null || printf '%s' "$(FLUTTER_BIN)")
FLUTTER_DART_BIN := $(abspath $(dir $(FLUTTER_REAL_BIN))cache/dart-sdk/bin/dart)

ifndef DART_BIN
ifneq ($(wildcard $(FLUTTER_DART_BIN)),)
DART_BIN := $(FLUTTER_DART_BIN)
else
DART_BIN := $(shell command -v dart 2>/dev/null)
endif
endif

.DEFAULT_GOAL := help
.PHONY: help bootstrap format check-format analyze test test-unit test-widget build-web build-android build-android-release build-android-release-split-per-abi verify clean check-flutter check-dart

help: ## Show available development commands.
	@awk 'BEGIN {FS = ":.*## "; printf "Pocketools development commands:\n\n"} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check-flutter:
	@if [ -z "$(FLUTTER_BIN)" ] || [ ! -x "$(FLUTTER_BIN)" ]; then \
		echo "Flutter not found. Set FLUTTER_BIN=./.tooling/flutter/bin/flutter or install it at .tooling/flutter/bin/flutter." >&2; \
		exit 1; \
	fi

check-dart: check-flutter
	@if [ ! -x "$(DART_BIN)" ]; then \
		echo "Dart not found beside Flutter. Set DART_BIN=./.tooling/flutter/bin/cache/dart-sdk/bin/dart." >&2; \
		exit 1; \
	fi

bootstrap: check-flutter ## Resolve the locked Flutter dependencies.
	@"$(FLUTTER_BIN)" pub get

format: check-dart ## Format Dart source and tests.
	@"$(DART_BIN)" format lib test

check-format: check-dart ## Verify Dart formatting without changing files.
	@"$(DART_BIN)" format --output=none --set-exit-if-changed lib test

analyze: check-flutter ## Run static analysis.
	@"$(FLUTTER_BIN)" analyze

test: check-flutter ## Run all tests.
	@"$(FLUTTER_BIN)" test

test-unit: check-flutter ## Run random, session, dice, cards, and architecture unit tests.
	@"$(FLUTTER_BIN)" test test/core test/features test/architecture

test-widget: check-flutter ## Run component, navigation, accessibility, and DND widget tests.
	@"$(FLUTTER_BIN)" test test/widget

build-web: check-dart ## Build the production Web application.
	@rm -rf -- "$(WEB_BUILD_DIR)"
	@"$(FLUTTER_BIN)" build web --no-web-resources-cdn
	@rm -f -- "$(WEB_BUILD_DIR)/flutter_service_worker.js"
	@test -f "$(WEB_BUILD_DIR)/pocketools_service_worker.js"
	@test -f "$(WEB_BUILD_DIR)/flutter_bootstrap.js"
	@test ! -e "$(WEB_BUILD_DIR)/flutter_service_worker.js"
	@grep -q 'pocketools_service_worker.js' "$(WEB_BUILD_DIR)/flutter_bootstrap.js"
	@grep -q 'pocketools-pwa-v3' "$(WEB_BUILD_DIR)/flutter_bootstrap.js"
	@grep -q '\.register(' "$(WEB_BUILD_DIR)/flutter_bootstrap.js"
	@grep -q 'canvasKitBaseUrl: "canvaskit/"' "$(WEB_BUILD_DIR)/flutter_bootstrap.js"
	@"$(DART_BIN)" tool/verify_web_precache.dart "$(WEB_BUILD_DIR)"

build-android: check-flutter ## Build a debug Android APK.
	@"$(FLUTTER_BIN)" build apk --debug

build-android-release: check-flutter ## Build an optimized release Android APK candidate.
	@"$(FLUTTER_BIN)" build apk --release

build-android-release-split-per-abi: check-dart ## Build arm64-v8a, armeabi-v7a, and x86_64 release APKs.
	@rm -f -- \
		"$(ANDROID_APK_OUTPUT_DIR)/app-arm64-v8a-release.apk" \
		"$(ANDROID_APK_OUTPUT_DIR)/app-armeabi-v7a-release.apk" \
		"$(ANDROID_APK_OUTPUT_DIR)/app-x86_64-release.apk"
	@"$(FLUTTER_BIN)" build apk --release --split-per-abi
	@"$(DART_BIN)" tool/verify_android_apks.dart \
		"$(ANDROID_APK_OUTPUT_DIR)" \
		"app-arm64-v8a-release.apk" \
		"app-armeabi-v7a-release.apk" \
		"app-x86_64-release.apk"

verify: check-format analyze test build-web ## Run the local/CI verification gate.

clean: check-flutter ## Remove only Flutter-generated project build caches.
	@"$(FLUTTER_BIN)" clean
