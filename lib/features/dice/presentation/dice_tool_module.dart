import 'package:flutter/material.dart';

import '../../../core/session/session.dart';
import '../../../core/session/session_id_source.dart';
import '../../../core/presets/preset.dart';
import '../../../core/presets/preset_capabilities.dart';
import '../../../core/tools/tool_module.dart';
import '../../../core/tools/tool_session_adapter.dart';
import '../domain/dice_models.dart';
import '../domain/dice_roller.dart';
import 'dice_session_codec.dart';
import 'dice_tool_page.dart';

final class DiceToolModule
    implements ToolModule, ToolSessionAdapterProvider, ToolPresetProvider {
  factory DiceToolModule({
    SessionRepository? sessionRepository,
    SessionIdSource? sessionIdSource,
  }) => DiceToolModule._(sessionRepository, sessionIdSource);

  DiceToolModule._(this._sessionRepository, this._sessionIdSource)
    : toolSessionAdapter = ToolSessionAdapter(
        descriptor: _descriptor,
        codec: const DiceSessionCodec(),
      );

  static const _descriptor = ToolDescriptor(
    id: 'd20',
    name: 'D20 检定',
    description: '快捷预设与可追溯自定义骰池',
    route: '/tools/d20',
    icon: Icons.casino_outlined,
    accent: ToolAccent.d20,
  );

  final SessionRepository? _sessionRepository;
  final SessionIdSource? _sessionIdSource;

  SessionRepository get sessionRepository =>
      _sessionRepository ??
      (throw StateError('DiceToolModule requires an app session repository.'));

  SessionIdSource get sessionIdSource =>
      _sessionIdSource ??
      (throw StateError('DiceToolModule requires an app session ID source.'));

  @override
  final ToolSessionAdapter toolSessionAdapter;

  @override
  ToolDescriptor get descriptor => _descriptor;

  @override
  ToolSessionCodec get sessionCodec => toolSessionAdapter.codec;

  @override
  String get toolId => descriptor.id;

  static final List<ToolPreset> _systemPresets = List<ToolPreset>.unmodifiable(
    <ToolPreset>[
      ToolPreset(
        id: 'd20.normal',
        toolId: _descriptor.id,
        displayName: '普通',
        ruleVersion: DiceRoller.ruleVersion,
        type: PresetType.system,
        source: PresetSource.bundled,
        configuration: const <String, Object?>{
          'diceCount': 1,
          'diceSides': 20,
          'aggregation': 'sum',
          'keepCount': null,
          'modifier': 0,
        },
      ),
      ToolPreset(
        id: 'd20.advantage',
        toolId: _descriptor.id,
        displayName: '优势',
        ruleVersion: DiceRoller.ruleVersion,
        type: PresetType.system,
        source: PresetSource.bundled,
        configuration: const <String, Object?>{
          'diceCount': 2,
          'diceSides': 20,
          'aggregation': 'keepHighest',
          'keepCount': 1,
          'modifier': 0,
        },
      ),
      ToolPreset(
        id: 'd20.disadvantage',
        toolId: _descriptor.id,
        displayName: '劣势',
        ruleVersion: DiceRoller.ruleVersion,
        type: PresetType.system,
        source: PresetSource.bundled,
        configuration: const <String, Object?>{
          'diceCount': 2,
          'diceSides': 20,
          'aggregation': 'keepLowest',
          'keepCount': 1,
          'modifier': 0,
        },
      ),
    ],
  );

  @override
  List<ToolPreset> get systemPresets => _systemPresets;

  @override
  Object decodePresetConfiguration(Map<String, Object?> configuration) {
    const expectedKeys = <String>{
      'diceCount',
      'diceSides',
      'aggregation',
      'keepCount',
      'modifier',
    };
    if (configuration.keys.toSet().difference(expectedKeys).isNotEmpty ||
        configuration.length != expectedKeys.length) {
      throw const PresetConfigurationException('D20 预设字段不完整或包含未知字段。');
    }
    final aggregationName = configuration['aggregation'];
    final aggregations = DiceAggregation.values.where(
      (value) => value.name == aggregationName,
    );
    final diceCount = configuration['diceCount'];
    final diceSides = configuration['diceSides'];
    final keepCount = configuration['keepCount'];
    final modifier = configuration['modifier'];
    if (diceCount is! int ||
        diceSides is! int ||
        modifier is! int ||
        (keepCount != null && keepCount is! int) ||
        aggregations.length != 1) {
      throw const PresetConfigurationException('D20 预设规则配置无效。');
    }
    final config = DicePoolConfig(
      diceCount: diceCount,
      diceSides: diceSides,
      aggregation: aggregations.single,
      keepCount: keepCount as int?,
      modifier: modifier,
    );
    if (config.validate().isNotEmpty) {
      throw const PresetConfigurationException('D20 预设规则配置超出支持范围。');
    }
    return config;
  }

  @override
  Map<String, Object?> encodePresetConfiguration(Object configuration) {
    if (configuration is! DicePoolConfig) {
      throw const PresetConfigurationException('不是有效的 D20 输入模型。');
    }
    final errors = configuration.validate();
    if (errors.isNotEmpty) {
      throw PresetConfigurationException(errors.join(' '));
    }
    return <String, Object?>{
      'diceCount': configuration.diceCount,
      'diceSides': configuration.diceSides,
      'aggregation': configuration.aggregation.name,
      'keepCount': configuration.keepCount,
      'modifier': configuration.modifier,
    };
  }

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) {
    final launch = moduleContext.launchRequest;
    return DiceToolPage(
      moduleContext: moduleContext,
      sessionRepository: sessionRepository,
      sessionAdapter: toolSessionAdapter,
      sessionIdSource: sessionIdSource,
      initialConfig: launch?.toolId == descriptor.id
          ? launch?.initialConfig as DicePoolConfig?
          : null,
      initialParentSessionId: launch?.toolId == descriptor.id
          ? launch?.parentSessionId
          : null,
    );
  }
}
