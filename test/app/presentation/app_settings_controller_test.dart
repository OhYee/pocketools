import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/pocketools_app.dart';
import 'package:pocketools/app/platform/local_app_settings.dart';
import 'package:pocketools/app/platform/local_settings_store.dart';
import 'package:pocketools/app/presentation/app_settings_controller.dart';
import 'package:pocketools/app/presentation/settings_page.dart';
import 'package:pocketools/core/session/local_string_store.dart';
import 'package:pocketools/core/session/persistent_session_repository.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';
import 'package:pocketools/design_system/app_theme.dart';

void main() {
  test('controller persists every setting across an app restart', () async {
    final backend = MemoryLocalStringStore();
    final first = await AppSettingsController.load(
      store: LocalSettingsStore(store: backend),
    );

    first
      ..themeMode = LocalThemeMode.dark
      ..animationsEnabled = false
      ..reduceMotion = true
      ..soundEnabled = true
      ..feedbackEnabled = false
      ..historyEnabled = false;
    await first.flush();

    final restarted = await AppSettingsController.load(
      store: LocalSettingsStore(store: backend),
    );
    expect(
      restarted.value,
      const LocalAppSettings(
        themeMode: LocalThemeMode.dark,
        animationsEnabled: false,
        reduceMotion: true,
        soundEnabled: true,
        feedbackEnabled: false,
        historyEnabled: false,
      ),
    );
  });

  test(
    'failed persistence warns while retaining app-lifetime selection',
    () async {
      final warnings = <String>[];
      final controller = AppSettingsController(
        store: LocalSettingsStore(store: _WriteFailureStore()),
        onWarning: warnings.add,
      );

      controller.themeMode = LocalThemeMode.light;
      await controller.flush();

      expect(controller.themeMode, LocalThemeMode.light);
      expect(warnings.single, contains('无法保存'));
    },
  );

  testWidgets('PocketoolsApp themeMode follows the settings controller', (
    tester,
  ) async {
    final settings = AppSettingsController(themeMode: LocalThemeMode.light);
    await tester.pumpWidget(PocketoolsApp(settings: settings));
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );

    settings.themeMode = LocalThemeMode.dark;
    await tester.pump();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets(
    'shell converges animation and feedback settings in module context',
    (tester) async {
      final module = _ContextRecordingModule();
      final settings = AppSettingsController(
        animationsEnabled: false,
        feedbackEnabled: false,
      );
      await tester.pumpWidget(
        PocketoolsApp(
          registry: ToolRegistry(<ToolModule>[module]),
          settings: settings,
        ),
      );
      await tester.tap(find.text('Context Tool'));
      await tester.pump();

      expect(module.moduleContext!.reduceMotion, isTrue);
      expect(module.moduleContext!.feedbackEnabled, isFalse);
    },
  );

  testWidgets('system disableAnimations converges to reduced motion', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    final module = _ContextRecordingModule();
    await tester.pumpWidget(
      PocketoolsApp(
        registry: ToolRegistry(<ToolModule>[module]),
        settings: AppSettingsController(),
      ),
    );
    await tester.tap(find.text('Context Tool'));
    await tester.pump();

    expect(module.moduleContext!.reduceMotion, isTrue);
  });

  testWidgets('settings page has no overflow at 360px and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = PersistentSessionRepository(
      store: MemoryLocalStringStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: SettingsPage(
          settings: AppSettingsController(),
          historyRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('开源许可'), findsNothing);
    expect(find.text('查看第三方许可'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

final class _ContextRecordingModule implements ToolModule {
  ToolModuleContext? moduleContext;

  @override
  ToolDescriptor get descriptor => const ToolDescriptor(
    id: 'context',
    name: 'Context Tool',
    description: 'Context test',
    route: '/context',
    icon: Icons.extension,
    accent: ToolAccent.neutral,
  );

  @override
  ToolSessionCodec get sessionCodec => const _ContextCodec();

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) {
    this.moduleContext = moduleContext;
    return const Center(child: Text('Context configured'));
  }
}

final class _ContextCodec implements ToolSessionCodec {
  const _ContextCodec();

  @override
  String get toolId => 'context';

  @override
  Map<String, Object?> decodeInput(Map<String, Object?> input) => input;

  @override
  Map<String, Object?> decodeOutcome(
    Map<String, Object?> outcome,
    Object input,
  ) => outcome;

  @override
  Map<String, Object?> encodeInput(Object input) => const <String, Object?>{};

  @override
  Map<String, Object?> encodeOutcome(Object outcome) =>
      const <String, Object?>{};

  @override
  String summarize(SessionRecord session) => 'Context';
}

final class _WriteFailureStore implements LocalStringStore {
  @override
  Future<void> clearOwned(Set<String> allowList) async {}

  @override
  Future<String?> readString(String key) async => null;

  @override
  Future<void> remove(String key) async {}

  @override
  Future<void> writeString(String key, String value) =>
      Future<void>.error(StateError('write failure'));
}
