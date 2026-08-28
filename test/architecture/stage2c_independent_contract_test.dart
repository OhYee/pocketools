import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_registry.dart';

void main() {
  final featureFiles = Directory('lib/features')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList(growable: false);

  test('features depend on injected services and shared presentation only', () {
    const forbidden = <String>[
      'dart:html',
      'dart:js_interop',
      'package:pocketools/app/platform/',
      'package:shared_preferences/',
      'package:share_plus/',
      'package:web/',
      'Random.secure(',
      'SecureRandomSource(',
      'InMemorySessionRepository(',
      'IncrementingSessionIdSource(',
      'HapticFeedback.',
      'MethodChannel(',
      'SharePlus.',
      'Clipboard.',
    ];
    final violations = <String>[];

    for (final file in featureFiles) {
      final source = file.readAsStringSync();
      for (final token in forbidden) {
        if (source.contains(token)) violations.add('${file.path}: $token');
      }
    }

    expect(violations, isEmpty);
  });

  test('six feature pages use shared scaffold buttons actions and tokens', () {
    const pagePaths = <String>[
      'lib/features/tarot/presentation/tarot_tool_page.dart',
      'lib/features/liuyao/presentation/liuyao_tool_page.dart',
      'lib/features/dice/presentation/dice_tool_page.dart',
      'lib/features/coin/presentation/coin_tool_page.dart',
      'lib/features/cards/presentation/card_tool_page.dart',
      'lib/features/multi_divination/presentation/multi_divination_tool_page.dart',
    ];
    const rawButtons = <String>[
      'ElevatedButton(',
      'FilledButton(',
      'OutlinedButton(',
      'TextButton(',
      'IconButton(',
    ];

    for (final path in pagePaths) {
      final source = File(path).readAsStringSync();
      expect(source, contains('AppToolScaffold('), reason: path);
      expect(source, contains('AppButton('), reason: path);
      expect(source, contains('AppSessionActions('), reason: path);
      expect(source, contains('AppSpacing.'), reason: path);
      for (final raw in rawButtons) {
        expect(source, isNot(contains(raw)), reason: '$path: $raw');
      }
    }
  });

  test('shared shell history and share contain no six-tool ID switch', () {
    const consumers = <String>[
      'lib/app/presentation/app_shell.dart',
      'lib/app/presentation/history_page.dart',
      'lib/core/tools/session_actions.dart',
      'lib/design_system/components/app_session_actions.dart',
    ];
    const toolIds = <String>[
      'tarot',
      'liuyao',
      'd20',
      'coin',
      'cards',
      'multi_divination',
    ];

    for (final path in consumers) {
      final source = File(path).readAsStringSync();
      for (final id in toolIds) {
        expect(
          source,
          isNot(matches(RegExp("['\"]$id['\"]"))),
          reason: '$path must stay tool-neutral for $id',
        );
      }
    }
  });

  test(
    'registration alone gives fake module session history share and replay',
    () {
      final registry = ToolRegistry(<ToolModule>[
        const _IndependentFakeModule(),
      ]);
      final session = registry.createCompletedSession(
        toolId: 'independent-fake',
        id: 'fake-session',
        schemaVersion: 1,
        ruleVersion: 'fake/rule-v1',
        algorithmVersion: 'fake/algorithm-v1',
        input: const <String, Object?>{'count': 2},
        outcome: const <String, Object?>{'value': 17},
      );

      expect(registry.modules.single.descriptor.name, 'Independent Fake');
      expect(registry.historySummary(session).summary, 'Fake value 17');
      expect(
        registry.sharePayload(session).plainText,
        contains('Fake value 17'),
      );
      expect(
        registry.sharePayload(session).plainText,
        contains('fake/rule-v1'),
      );
      final replay = registry.replayRequest(session);
      expect(replay.toolId, 'independent-fake');
      expect(replay.initialConfig, <String, Object?>{'count': 2});
      expect(replay.parentSessionId, session.id);
    },
  );
}

final class _IndependentFakeModule implements ToolModule {
  const _IndependentFakeModule();

  @override
  ToolDescriptor get descriptor => const ToolDescriptor(
    id: 'independent-fake',
    name: 'Independent Fake',
    description: 'Stage 2C extensibility fixture',
    route: '/tools/independent-fake',
    icon: Icons.extension_outlined,
    accent: ToolAccent.neutral,
  );

  @override
  ToolSessionCodec get sessionCodec => const _IndependentFakeCodec();

  @override
  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext) =>
      const Center(child: Text('Independent fake config'));
}

final class _IndependentFakeCodec implements ToolSessionCodec {
  const _IndependentFakeCodec();

  @override
  String get toolId => 'independent-fake';

  @override
  Map<String, Object?> decodeInput(Map<String, Object?> input) => input;

  @override
  Map<String, Object?> decodeOutcome(
    Map<String, Object?> outcome,
    Object input,
  ) => outcome;

  @override
  Map<String, Object?> encodeInput(Object input) =>
      Map<String, Object?>.of(input as Map<String, Object?>);

  @override
  Map<String, Object?> encodeOutcome(Object outcome) =>
      Map<String, Object?>.of(outcome as Map<String, Object?>);

  @override
  String summarize(SessionRecord session) =>
      'Fake value ${session.outcome['value']}';
}
