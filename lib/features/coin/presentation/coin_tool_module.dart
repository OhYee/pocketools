import 'package:flutter/material.dart';

import '../../../core/session/session.dart';
import '../../../core/presets/preset.dart';
import '../../../core/presets/preset_capabilities.dart';
import '../../../core/tools/tool_module.dart';
import '../../../core/tools/tool_session_adapter.dart';
import '../domain/coin_models.dart';
import '../domain/coin_tosser.dart';
import 'coin_labels.dart';
import 'coin_session_codec.dart';
import 'coin_session_id_source.dart';
import 'coin_tool_page.dart';

final class CoinToolModule
    implements ToolModule, ToolSessionAdapterProvider, ToolPresetProvider {
  factory CoinToolModule({
    SessionRepository? sessionRepository,
    CoinSessionIdSource? sessionIdSource,
  }) => CoinToolModule._(sessionRepository, sessionIdSource);

  CoinToolModule._(this._sessionRepository, this._sessionIdSource)
    : toolSessionAdapter = ToolSessionAdapter(
        descriptor: _descriptor,
        codec: const CoinSessionCodec(),
        shareRenderer: _renderSharePayload,
      );

  static const _descriptor = ToolDescriptor(
    id: 'coin',
    name: '抛硬币',
    description: '单次、批量与率先达到，保留原始二值序列',
    route: '/tools/coin',
    icon: Icons.circle_outlined,
    accent: ToolAccent.coin,
  );

  final SessionRepository? _sessionRepository;
  final CoinSessionIdSource? _sessionIdSource;

  SessionRepository get sessionRepository =>
      _sessionRepository ??
      (throw StateError('CoinToolModule requires an app session repository.'));

  CoinSessionIdSource get sessionIdSource =>
      _sessionIdSource ??
      (throw StateError('CoinToolModule requires an app session ID source.'));

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
      _countPreset('coin.single', '单次', CoinTossMode.single, 1),
      _countPreset('coin.batch-3', '批量 3 次', CoinTossMode.batch, 3),
      _countPreset('coin.batch-5', '批量 5 次', CoinTossMode.batch, 5),
      _countPreset('coin.batch-10', '批量 10 次', CoinTossMode.batch, 10),
    ],
  );

  static ToolPreset _countPreset(
    String id,
    String displayName,
    CoinTossMode mode,
    int batchCount,
  ) => ToolPreset(
    id: id,
    toolId: _descriptor.id,
    displayName: displayName,
    ruleVersion: CoinTosser.ruleVersion,
    type: PresetType.system,
    source: PresetSource.bundled,
    configuration: <String, Object?>{
      'mode': mode.name,
      'batchCount': batchCount,
      'raceTarget': null,
      'headsLabel': '正面',
      'tailsLabel': '反面',
    },
  );

  @override
  List<ToolPreset> get systemPresets => _systemPresets;

  @override
  Object decodePresetConfiguration(Map<String, Object?> configuration) {
    const expectedKeys = <String>{
      'mode',
      'batchCount',
      'raceTarget',
      'headsLabel',
      'tailsLabel',
    };
    if (configuration.keys.toSet().difference(expectedKeys).isNotEmpty ||
        configuration.length != expectedKeys.length) {
      throw const PresetConfigurationException('硬币预设字段不完整或包含未知字段。');
    }
    final modes = CoinTossMode.values.where(
      (value) => value.name == configuration['mode'],
    );
    final batchCount = configuration['batchCount'];
    final raceTarget = configuration['raceTarget'];
    final headsLabel = configuration['headsLabel'];
    final tailsLabel = configuration['tailsLabel'];
    if (modes.length != 1 ||
        batchCount is! int ||
        (raceTarget != null && raceTarget is! int) ||
        headsLabel is! String ||
        tailsLabel is! String) {
      throw const PresetConfigurationException('硬币预设规则配置无效。');
    }
    final config = CoinTossConfig(
      mode: modes.single,
      batchCount: batchCount,
      raceTarget: raceTarget as int?,
      headsLabel: headsLabel,
      tailsLabel: tailsLabel,
    ).normalized();
    if (config.validate().isNotEmpty) {
      throw const PresetConfigurationException('硬币预设规则配置超出支持范围。');
    }
    return config;
  }

  @override
  Map<String, Object?> encodePresetConfiguration(Object configuration) {
    if (configuration is! CoinTossConfig) {
      throw const PresetConfigurationException('不是有效的硬币输入模型。');
    }
    final normalized = configuration.normalized();
    final errors = normalized.validate();
    if (errors.isNotEmpty) {
      throw PresetConfigurationException(errors.join(' '));
    }
    return <String, Object?>{
      'mode': normalized.mode.name,
      'batchCount': normalized.batchCount,
      'raceTarget': normalized.raceTarget,
      'headsLabel': normalized.headsLabel,
      'tailsLabel': normalized.tailsLabel,
    };
  }

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) {
    final launch = moduleContext.launchRequest;
    return CoinToolPage(
      moduleContext: moduleContext,
      sessionRepository: sessionRepository,
      sessionAdapter: toolSessionAdapter,
      sessionIdSource: sessionIdSource,
      initialConfig: launch?.toolId == descriptor.id
          ? launch?.initialConfig as CoinTossConfig?
          : null,
      initialParentSessionId: launch?.toolId == descriptor.id
          ? launch?.parentSessionId
          : null,
    );
  }

  static ToolSharePayload _renderSharePayload(
    ToolDescriptor descriptor,
    SessionRecord session,
    String summary,
  ) {
    const codec = CoinSessionCodec();
    final config = codec.decodeInput(session.input);
    final result = codec.decodeOutcome(session.outcome, config);
    return ToolSharePayload(
      title: descriptor.name,
      summary: summary,
      plainText: <String>[
        '万象匣 · ${descriptor.name}',
        '标签：heads=${config.headsLabel}；tails=${config.tailsLabel}',
        '共抛 ${result.tossCount} 次',
        '计数：${config.headsLabel} ${result.headsCount}（heads）；'
            '${config.tailsLabel} ${result.tailsCount}（tails）',
        '序列：${coinSequenceLabel(result)}',
        '停止原因：${coinStopReasonLabel(result)}',
        '规则版本：${session.ruleVersion}',
        '算法版本：${session.algorithmVersion}',
      ].join('\n'),
    );
  }
}
