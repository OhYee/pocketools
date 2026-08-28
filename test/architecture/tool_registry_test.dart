import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/pocketools_app.dart';
import 'package:pocketools/app/presentation/app_settings_controller.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';

void main() {
  group('registry validation', () {
    test('rejects duplicate tool ids', () {
      expect(
        () => ToolRegistry(<ToolModule>[
          const _FakeToolModule(),
          _ConfigurableToolModule(
            descriptor: _descriptor(id: 'fake', route: '/tools/other'),
            codec: const _FakeCodec('fake'),
          ),
        ]),
        throwsArgumentError,
      );
    });

    test('rejects duplicate routes', () {
      expect(
        () => ToolRegistry(<ToolModule>[
          const _FakeToolModule(),
          _ConfigurableToolModule(
            descriptor: _descriptor(id: 'other', route: '/tools/fake'),
            codec: const _FakeCodec('other'),
          ),
        ]),
        throwsArgumentError,
      );
    });

    test('rejects a codec whose tool id differs from the descriptor', () {
      expect(
        () => ToolRegistry(<ToolModule>[
          _ConfigurableToolModule(
            descriptor: _descriptor(id: 'fake', route: '/tools/fake'),
            codec: const _FakeCodec('other'),
          ),
        ]),
        throwsArgumentError,
      );
    });

    test('exposes an immutable module list and codec summary', () {
      final registry = ToolRegistry(<ToolModule>[const _FakeToolModule()]);
      final session = SessionRecord(
        id: 'fake-1',
        toolId: 'fake',
        schemaVersion: 1,
        ruleVersion: 'fake/1',
        algorithmVersion: 'random/1',
        status: SessionStatus.completed,
        input: const <String, Object?>{},
        outcome: const <String, Object?>{},
      );

      expect(registry.byId('fake'), isNotNull);
      expect(registry.byRoute('/tools/fake'), isNotNull);
      expect(registry.summarize(session), 'Fake summary');
      expect(() => registry.modules.clear(), throwsUnsupportedError);
    });
  });

  testWidgets(
    'a fake registered module appears and opens without shell edits',
    (tester) async {
      final registry = ToolRegistry(<ToolModule>[const _FakeToolModule()]);
      await tester.pumpWidget(
        PocketoolsApp(
          registry: registry,
          randomSource: SequenceRandomSource(const <int>[0]),
          feedbackService: const NoopFeedbackService(),
          settings: AppSettingsController(reduceMotion: true),
        ),
      );

      expect(find.text('Fake Tool'), findsOneWidget);
      await tester.tap(find.text('Fake Tool'));
      await tester.pump();

      expect(find.text('Fake configuration'), findsOneWidget);
      final navigation = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navigation.selectedIndex, 0);
    },
  );

  test('feature domain directories do not import presentation or Flutter', () {
    final domainFiles = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.contains('/domain/'));

    expect(domainFiles, isNotEmpty);
    for (final file in domainFiles) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('package:flutter/')), reason: file.path);
      expect(source, isNot(contains('/presentation/')), reason: file.path);
    }
  });

  test('the app shell has no feature-specific imports', () {
    final source = File('lib/app/presentation/app_shell.dart')
        .readAsStringSync();

    expect(source, isNot(contains('/features/')));
    expect(source, isNot(contains('features/')));
  });
}

final class _FakeToolModule implements ToolModule {
  const _FakeToolModule();

  @override
  ToolDescriptor get descriptor => const ToolDescriptor(
    id: 'fake',
    name: 'Fake Tool',
    description: 'Registry test module',
    route: '/tools/fake',
    icon: Icons.extension_outlined,
    accent: ToolAccent.neutral,
  );

  @override
  ToolSessionCodec get sessionCodec => const _FakeCodec('fake');

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      const Center(child: Text('Fake configuration'));
}

final class _FakeCodec implements ToolSessionCodec {
  const _FakeCodec(this.toolId);

  @override
  final String toolId;

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
  String summarize(SessionRecord session) => 'Fake summary';
}

ToolDescriptor _descriptor({required String id, required String route}) =>
    ToolDescriptor(
      id: id,
      name: id,
      description: 'Registry validation module',
      route: route,
      icon: Icons.extension_outlined,
      accent: ToolAccent.neutral,
    );

final class _ConfigurableToolModule implements ToolModule {
  const _ConfigurableToolModule({
    required this.descriptor,
    required this.codec,
  });

  @override
  final ToolDescriptor descriptor;

  final ToolSessionCodec codec;

  @override
  ToolSessionCodec get sessionCodec => codec;

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      const SizedBox.shrink();
}
