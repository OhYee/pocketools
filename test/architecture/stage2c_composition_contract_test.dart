import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/registry/default_tool_registry.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_id_source.dart';

void main() {
  final featureFiles = Directory('lib/features')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList(growable: false);

  test('features do not import platform adapters or persistence plugins', () {
    const forbiddenImports = <String>[
      "package:pocketools/app/platform/",
      "package:shared_preferences/",
      "package:share_plus/",
      "package:web/",
      "dart:html",
      "dart:js_interop",
    ];

    for (final file in featureFiles) {
      final source = file.readAsStringSync();
      for (final forbidden in forbiddenImports) {
        expect(source, isNot(contains(forbidden)), reason: file.path);
      }
    }
  });

  test('feature pages use shared buttons instead of raw Flutter buttons', () {
    final pageFiles = featureFiles.where(
      (file) => file.path.endsWith('_page.dart'),
    );
    const rawButtons = <String>[
      'ElevatedButton(',
      'FilledButton(',
      'OutlinedButton(',
      'TextButton(',
      'IconButton(',
    ];

    for (final file in pageFiles) {
      final source = file.readAsStringSync();
      expect(source, contains('AppToolScaffold('), reason: file.path);
      for (final rawButton in rawButtons) {
        expect(source, isNot(contains(rawButton)), reason: file.path);
      }
    }
  });

  test('all six result pages use the one shared session action component', () {
    const pages = <String>[
      'lib/features/cards/presentation/card_tool_page.dart',
      'lib/features/coin/presentation/coin_tool_page.dart',
      'lib/features/dice/presentation/dice_tool_page.dart',
      'lib/features/tarot/presentation/tarot_tool_page.dart',
      'lib/features/liuyao/presentation/liuyao_tool_page.dart',
      'lib/features/multi_divination/presentation/multi_divination_tool_page.dart',
    ];
    for (final path in pages) {
      final source = File(path).readAsStringSync();
      expect(source, contains('AppSessionActions('), reason: path);
      expect(source, isNot(contains('Clipboard.')), reason: path);
      expect(source, isNot(contains('SharePlus')), reason: path);
    }
  });

  test(
    'shell history and share pipeline contain no first-party tool branches',
    () {
      const sharedConsumers = <String>[
        'lib/app/presentation/app_shell.dart',
        'lib/app/presentation/history_page.dart',
        'lib/core/tools/session_actions.dart',
      ];
      const toolIds = <String>[
        'tarot',
        'liuyao',
        'd20',
        'coin',
        'cards',
        'multi_divination',
      ];
      for (final path in sharedConsumers) {
        final source = File(path).readAsStringSync();
        for (final toolId in toolIds) {
          expect(
            source,
            isNot(contains("'$toolId'")),
            reason: '$path must not branch on $toolId',
          );
        }
      }
    },
  );

  test(
    'production modules require composition-root repository and id source',
    () {
      final offenders = <String>[];
      for (final file in featureFiles.where(
        (file) => file.path.endsWith('_tool_module.dart'),
      )) {
        final source = file.readAsStringSync();
        if (source.contains('InMemorySessionRepository()') ||
            RegExp(r'Incrementing\w+SessionIdSource\(\)').hasMatch(source)) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty);
    },
  );

  test('default registry injects one shared repository and id service into session tools', () {
    final repository = InMemorySessionRepository();
    final idSource = _SharedSessionIdSource();
    final registry = buildDefaultToolRegistry(
      sessionRepository: repository,
      sessionIdSource: idSource,
    );

    expect(registry.modules, hasLength(7));
    for (final module in registry.modules.where(
      (module) => module.descriptor.id != 'encyclopedia',
    )) {
      final infrastructure = module as dynamic;
      expect(
        identical(infrastructure.sessionRepository, repository),
        isTrue,
        reason: module.descriptor.id,
      );
      expect(
        identical(infrastructure.sessionIdSource, idSource),
        isTrue,
        reason: module.descriptor.id,
      );
    }
  });
}

final class _SharedSessionIdSource implements SessionIdSource {
  @override
  String next() => 'shared-session-id';
}
