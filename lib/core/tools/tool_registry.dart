import '../session/session.dart';
import '../presets/preset.dart';
import '../presets/preset_capabilities.dart';
import '../presets/preset_configuration_policy.dart';
import 'tool_capabilities.dart';
import 'tool_module.dart';
import 'tool_session_adapter.dart';

final class ToolRegistry {
  ToolRegistry(Iterable<ToolModule> modules)
    : _modules = List<ToolModule>.unmodifiable(modules) {
    final ids = <String>{};
    final routes = <String>{};
    final sessionAdapters = <String, ToolSessionAdapter>{};
    final presetProviders = <String, ToolPresetProvider>{};
    final systemPresets = <ToolPreset>[];
    final systemPresetIds = <String>{};
    for (final module in _modules) {
      final descriptor = module.descriptor;
      if (!ids.add(descriptor.id)) {
        throw ArgumentError('Duplicate tool id: ${descriptor.id}');
      }
      if (!routes.add(descriptor.route)) {
        throw ArgumentError('Duplicate tool route: ${descriptor.route}');
      }
      if (module.sessionCodec.toolId != descriptor.id) {
        throw ArgumentError(
          'Codec ${module.sessionCodec.toolId} does not match ${descriptor.id}.',
        );
      }
      final adapter = resolveToolSessionAdapter(module);
      if (adapter.descriptor.id != descriptor.id ||
          adapter.codec.toolId != descriptor.id) {
        throw ArgumentError(
          'Session adapter does not match tool ${descriptor.id}.',
        );
      }
      sessionAdapters[descriptor.id] = adapter;
      if (module case final ToolPresetProvider provider) {
        if (provider.toolId != descriptor.id) {
          throw ArgumentError(
            'Preset provider ${provider.toolId} does not match ${descriptor.id}.',
          );
        }
        if (presetProviders.containsKey(provider.toolId)) {
          throw ArgumentError('Duplicate preset provider: ${provider.toolId}');
        }
        presetProviders[provider.toolId] = provider;
        for (final preset in provider.systemPresets) {
          if (preset.toolId != descriptor.id) {
            throw ArgumentError(
              'Preset ${preset.id} does not match tool ${descriptor.id}.',
            );
          }
          if (preset.type != PresetType.system ||
              preset.source != PresetSource.bundled) {
            throw ArgumentError(
              'System preset ${preset.id} must be system/bundled.',
            );
          }
          final errors = preset.validate();
          if (errors.isNotEmpty) {
            throw ArgumentError.value(
              preset.id,
              'systemPresets',
              errors.join(' '),
            );
          }
          if (!systemPresetIds.add(preset.id)) {
            throw ArgumentError('Duplicate system preset id: ${preset.id}');
          }
          try {
            final configuration = ToolPresetConfigurationPolicy.validateAndCopy(
              preset.configuration,
            );
            provider.decodePresetConfiguration(configuration);
          } on Object catch (error) {
            throw ArgumentError.value(
              preset.id,
              'systemPresets',
              'System preset configuration cannot be decoded: $error',
            );
          }
          systemPresets.add(preset);
        }
      }
    }
    _sessionAdapters = Map<String, ToolSessionAdapter>.unmodifiable(
      sessionAdapters,
    );
    _presetProviders = Map<String, ToolPresetProvider>.unmodifiable(
      presetProviders,
    );
    _systemPresets = List<ToolPreset>.unmodifiable(systemPresets);
  }

  final List<ToolModule> _modules;
  late final Map<String, ToolSessionAdapter> _sessionAdapters;
  late final Map<String, ToolPresetProvider> _presetProviders;
  late final List<ToolPreset> _systemPresets;

  List<ToolModule> get modules => _modules;

  /// Providers are aggregated in module registration order for generic UI.
  List<ToolPresetProvider> get presetProviders =>
      List<ToolPresetProvider>.unmodifiable(_presetProviders.values);

  List<ToolPreset> get systemPresets => _systemPresets;

  ToolPresetProvider? presetProviderFor(String toolId) =>
      _presetProviders[toolId];

  ToolModule? byId(String id) {
    for (final module in _modules) {
      if (module.descriptor.id == id) return module;
    }
    return null;
  }

  ToolModule? byRoute(String route) {
    for (final module in _modules) {
      if (module.descriptor.route == route) return module;
    }
    return null;
  }

  ToolSessionAdapter sessionAdapterFor(String toolId) {
    final adapter = _sessionAdapters[toolId];
    if (adapter == null) {
      throw ArgumentError.value(toolId, 'toolId', 'Unknown tool id.');
    }
    return adapter;
  }

  SessionRecord createCompletedSession({
    required String toolId,
    required String id,
    required int schemaVersion,
    required String ruleVersion,
    required String algorithmVersion,
    required Object input,
    required Object outcome,
    String? parentSessionId,
  }) {
    return sessionAdapterFor(toolId).createSession(
      id: id,
      schemaVersion: schemaVersion,
      ruleVersion: ruleVersion,
      algorithmVersion: algorithmVersion,
      status: SessionStatus.completed,
      input: input,
      outcome: outcome,
      parentSessionId: parentSessionId,
    );
  }

  DecodedToolSession decode(SessionRecord session) =>
      sessionAdapterFor(session.toolId).decode(session);

  ToolHistorySummary historySummary(SessionRecord session) =>
      sessionAdapterFor(session.toolId).historySummary(session);

  ToolSharePayload sharePayload(SessionRecord session) =>
      sessionAdapterFor(session.toolId).sharePayload(session);

  ToolLaunchRequest replayRequest(SessionRecord session) {
    final module = byId(session.toolId);
    if (module == null) {
      throw ArgumentError.value(session.toolId, 'toolId', 'Unknown tool id.');
    }
    final decoded = decode(session);
    final input = module is ToolReplayCapability
        ? (module as ToolReplayCapability).replayInput(session, decoded)
        : decoded.input;
    return ToolLaunchRequest(
      toolId: session.toolId,
      initialConfig: input,
      parentSessionId: session.id,
    );
  }

  /// Converts a validated preset through its provider into the normal launch
  /// request consumed by the existing tool input page.
  ToolLaunchRequest launchRequestForPreset(ToolPreset preset) {
    final provider = _presetProviders[preset.toolId];
    if (provider == null) {
      throw ArgumentError.value(
        preset.toolId,
        'toolId',
        'Tool has no preset provider.',
      );
    }
    final errors = preset.validate();
    if (errors.isNotEmpty) {
      throw ArgumentError.value(preset.id, 'preset', errors.join(' '));
    }
    final configuration = ToolPresetConfigurationPolicy.validateAndCopy(
      preset.configuration,
    );
    return ToolLaunchRequest(
      toolId: preset.toolId,
      initialConfig: provider.decodePresetConfiguration(configuration),
    );
  }

  List<ToolOptionalShareField> optionalShareFields(SessionRecord session) {
    final module = byId(session.toolId);
    if (module == null) return const <ToolOptionalShareField>[];
    if (module is! ToolShareOptionsCapability) {
      return const <ToolOptionalShareField>[];
    }
    return ToolOptionalShareFieldPolicy.review(
      session: session,
      declaredFields: (module as ToolShareOptionsCapability)
          .optionalShareFields(session, decode(session)),
    );
  }

  String summarize(SessionRecord session) {
    final adapter = _sessionAdapters[session.toolId];
    if (adapter == null) return '未知工具结果';
    return adapter.historySummary(session).summary;
  }
}
