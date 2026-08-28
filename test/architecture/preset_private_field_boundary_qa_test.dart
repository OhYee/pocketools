import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/presets/preset.dart';
import 'package:pocketools/core/presets/preset_capabilities.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';

void main() {
  test(
    'registry rejects a fake provider that declares private preset fields',
    () {
      expect(
        () => ToolRegistry(<ToolModule>[const _PrivatePresetModule()]),
        throwsArgumentError,
      );
    },
  );
}

final class _PrivatePresetModule implements ToolModule, ToolPresetProvider {
  const _PrivatePresetModule();

  static const _descriptor = ToolDescriptor(
    id: 'private-preset-fake',
    name: 'Private preset fake',
    description: 'Independent QA privacy attack fixture',
    route: '/tools/private-preset-fake',
    icon: Icons.extension_outlined,
    accent: ToolAccent.neutral,
  );

  @override
  ToolDescriptor get descriptor => _descriptor;

  @override
  ToolSessionCodec get sessionCodec => const _PrivatePresetCodec();

  @override
  String get toolId => descriptor.id;

  @override
  List<ToolPreset> get systemPresets => <ToolPreset>[
    ToolPreset(
      id: 'private-preset-fake.default',
      toolId: descriptor.id,
      displayName: 'Private payload',
      ruleVersion: 'private-preset-fake/1.0.0',
      type: PresetType.system,
      source: PresetSource.bundled,
      configuration: const <String, Object?>{
        'value': 7,
        'sessionId': 'session-secret-123',
        'parentSessionId': 'parent-secret-456',
        'privateNote': 'private-note-secret',
      },
    ),
  ];

  @override
  Object decodePresetConfiguration(Map<String, Object?> configuration) =>
      configuration['value']! as int;

  @override
  Map<String, Object?> encodePresetConfiguration(Object configuration) =>
      <String, Object?>{
        'value': configuration as int,
        'sessionId': 'session-secret-123',
        'parentSessionId': 'parent-secret-456',
        'privateNote': 'private-note-secret',
      };

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      const SizedBox.shrink();
}

final class _PrivatePresetCodec implements ToolSessionCodec {
  const _PrivatePresetCodec();

  @override
  String get toolId => 'private-preset-fake';

  @override
  Object decodeInput(Map<String, Object?> input) => input;

  @override
  Object decodeOutcome(Map<String, Object?> outcome, Object input) => outcome;

  @override
  Map<String, Object?> encodeInput(Object input) =>
      Map<String, Object?>.of(input as Map<String, Object?>);

  @override
  Map<String, Object?> encodeOutcome(Object outcome) =>
      Map<String, Object?>.of(outcome as Map<String, Object?>);

  @override
  String summarize(SessionRecord session) => 'private preset fake';
}
