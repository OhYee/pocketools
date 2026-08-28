import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';
import 'package:pocketools/core/tools/tool_session_adapter.dart';

void main() {
  test('a codec-only fake module gets session, history, and share flows', () {
    final registry = ToolRegistry(<ToolModule>[const _FakeToolModule()]);

    final session = registry.createCompletedSession(
      toolId: 'fake',
      id: 'fake-session-1',
      schemaVersion: 1,
      ruleVersion: 'fake/1',
      algorithmVersion: 'random/1',
      input: const _FakeInput('demo'),
      outcome: const _FakeOutcome(7),
    );
    final history = registry.historySummary(session);
    final share = registry.sharePayload(session);

    expect(session.status, SessionStatus.completed);
    expect(session.input, <String, Object?>{'name': 'demo'});
    expect(session.outcome, <String, Object?>{'value': 7});
    expect(history.toolName, 'Fake Tool');
    expect(history.summary, 'Fake summary · 7');
    expect(share.title, 'Fake Tool');
    expect(share.summary, 'Fake summary · 7');
    expect(share.plainText, contains('规则版本：fake/1'));
    expect(share.plainText, contains('算法版本：random/1'));
  });

  test('the default adapter decodes the same frozen session envelope', () {
    final registry = ToolRegistry(<ToolModule>[const _FakeToolModule()]);
    final sourceOutcome = <String, Object?>{
      'value': 7,
      'nested': <Object?>[
        <String, Object?>{'stable': true},
      ],
    };
    final session = registry.createCompletedSession(
      toolId: 'fake',
      id: 'fake-session-default',
      schemaVersion: 1,
      ruleVersion: 'fake/1',
      algorithmVersion: 'random/1',
      input: const _FakeInput('default'),
      outcome: _FakeOutcome(7, extra: sourceOutcome['nested']),
      parentSessionId: 'fake-parent',
    );

    (sourceOutcome['nested']! as List<Object?>).clear();
    final decoded = registry.decode(session);

    expect(session.parentSessionId, 'fake-parent');
    expect((decoded.input as _FakeInput).name, 'default');
    expect((decoded.outcome as _FakeOutcome).value, 7);
    expect(session.outcome['nested'], <Object?>[
      <String, Object?>{'stable': true},
    ]);
  });

  test(
    'a fake module can customize sharing without bypassing the registry',
    () {
      final registry = ToolRegistry(<ToolModule>[
        const _CustomFakeToolModule(),
      ]);
      final session = registry.createCompletedSession(
        toolId: 'custom-fake',
        id: 'fake-session-custom',
        schemaVersion: 1,
        ruleVersion: 'custom/1',
        algorithmVersion: 'random/1',
        input: const _FakeInput('custom'),
        outcome: const _FakeOutcome(9),
      );

      expect(registry.decode(session).outcome, isA<_FakeOutcome>());
      expect(registry.historySummary(session).summary, 'Fake summary · 9');
      expect(registry.sharePayload(session).plainText, 'custom-share:9');
    },
  );

  test('registry rejects a custom adapter for a different tool', () {
    expect(
      () => ToolRegistry(<ToolModule>[const _MismatchedAdapterModule()]),
      throwsArgumentError,
    );
  });
}

final class _FakeInput {
  const _FakeInput(this.name);

  final String name;
}

final class _FakeOutcome {
  const _FakeOutcome(this.value, {this.extra});

  final int value;
  final Object? extra;
}

final class _FakeToolModule implements ToolModule {
  const _FakeToolModule();

  @override
  ToolDescriptor get descriptor => const ToolDescriptor(
    id: 'fake',
    name: 'Fake Tool',
    description: 'Session adapter test module',
    route: '/tools/fake',
    icon: Icons.extension_outlined,
    accent: ToolAccent.neutral,
  );

  @override
  ToolSessionCodec get sessionCodec => const _FakeCodec();

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      const SizedBox.shrink();
}

final class _FakeCodec implements ToolSessionCodec {
  const _FakeCodec();

  @override
  String get toolId => 'fake';

  @override
  Map<String, Object?> encodeInput(Object input) => <String, Object?>{
    'name': (input as _FakeInput).name,
  };

  @override
  _FakeInput decodeInput(Map<String, Object?> input) =>
      _FakeInput(input['name']! as String);

  @override
  Map<String, Object?> encodeOutcome(Object outcome) {
    final fakeOutcome = outcome as _FakeOutcome;
    return <String, Object?>{
      'value': fakeOutcome.value,
      if (fakeOutcome.extra != null) 'nested': fakeOutcome.extra,
    };
  }

  @override
  _FakeOutcome decodeOutcome(Map<String, Object?> outcome, Object input) =>
      _FakeOutcome(outcome['value']! as int, extra: outcome['nested']);

  @override
  String summarize(SessionRecord session) =>
      'Fake summary · ${session.outcome['value']}';
}

final class _CustomFakeToolModule
    implements ToolModule, ToolSessionAdapterProvider {
  const _CustomFakeToolModule();

  static const _descriptor = ToolDescriptor(
    id: 'custom-fake',
    name: 'Custom Fake Tool',
    description: 'Custom adapter test module',
    route: '/tools/custom-fake',
    icon: Icons.extension_outlined,
    accent: ToolAccent.neutral,
  );
  static const _codec = _FakeCodecWithId('custom-fake');

  @override
  ToolDescriptor get descriptor => _descriptor;

  @override
  ToolSessionCodec get sessionCodec => _codec;

  @override
  ToolSessionAdapter get toolSessionAdapter => ToolSessionAdapter(
    descriptor: _descriptor,
    codec: _codec,
    shareRenderer: (descriptor, session, summary) => ToolSharePayload(
      title: descriptor.name,
      summary: summary,
      plainText: 'custom-share:${session.outcome['value']}',
    ),
  );

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      const SizedBox.shrink();
}

final class _MismatchedAdapterModule
    implements ToolModule, ToolSessionAdapterProvider {
  const _MismatchedAdapterModule();

  @override
  ToolDescriptor get descriptor => const ToolDescriptor(
    id: 'fake',
    name: 'Fake Tool',
    description: 'Mismatched adapter test module',
    route: '/tools/fake',
    icon: Icons.extension_outlined,
    accent: ToolAccent.neutral,
  );

  @override
  ToolSessionCodec get sessionCodec => const _FakeCodec();

  @override
  ToolSessionAdapter get toolSessionAdapter => ToolSessionAdapter(
    descriptor: const ToolDescriptor(
      id: 'other',
      name: 'Other Tool',
      description: 'Wrong adapter',
      route: '/tools/other',
      icon: Icons.extension_outlined,
      accent: ToolAccent.neutral,
    ),
    codec: const _FakeCodecWithId('other'),
  );

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      const SizedBox.shrink();
}

final class _FakeCodecWithId implements ToolSessionCodec {
  const _FakeCodecWithId(this.toolId);

  @override
  final String toolId;

  @override
  Map<String, Object?> encodeInput(Object input) => <String, Object?>{
    'name': (input as _FakeInput).name,
  };

  @override
  _FakeInput decodeInput(Map<String, Object?> input) =>
      _FakeInput(input['name']! as String);

  @override
  Map<String, Object?> encodeOutcome(Object outcome) => <String, Object?>{
    'value': (outcome as _FakeOutcome).value,
  };

  @override
  _FakeOutcome decodeOutcome(Map<String, Object?> outcome, Object input) =>
      _FakeOutcome(outcome['value']! as int);

  @override
  String summarize(SessionRecord session) =>
      'Fake summary · ${session.outcome['value']}';
}
