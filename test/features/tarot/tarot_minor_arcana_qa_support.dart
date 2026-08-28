import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_id_source.dart';
import 'package:pocketools/core/tools/tool_module.dart';
import 'package:pocketools/core/tools/tool_session_adapter.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';
import 'package:pocketools/features/tarot/presentation/tarot_session_codec.dart';

/// Shared test-only helpers for the independent minor-arcana acceptance tests.
///
/// The production contract did not freeze the Dart field spelling. The tests
/// therefore exercise the behavior through either of the two conventional
/// spellings while still requiring one explicit persisted option.
abstract final class TarotMinorArcanaQa {
  static const parameterNames = <String>[
    'useMinorArcana',
    'includeMinorArcana',
  ];

  static TarotReadingConfig config({
    required bool useMinorArcana,
    TarotSpreadPreset spread = TarotSpreadPreset.dailyCard,
    bool useReversals = true,
    TarotRevealMode revealMode = TarotRevealMode.sequential,
    String? intention,
  }) {
    final common = <Symbol, Object?>{
      #spread: spread,
      #useReversals: useReversals,
      #revealMode: revealMode,
      #intention: intention,
    };
    for (final parameterName in parameterNames) {
      try {
        return Function.apply(
          TarotReadingConfig.new,
          const <Object?>[],
          <Symbol, Object?>{...common, Symbol(parameterName): useMinorArcana},
        ) as TarotReadingConfig;
      } on NoSuchMethodError {
        // Keep the test independent of the implementation's chosen spelling.
      }
    }
    fail(
      'TarotReadingConfig must expose useMinorArcana or includeMinorArcana.',
    );
  }

  static bool useMinorArcana(TarotReadingConfig config) {
    final dynamic value = config;
    for (final parameterName in parameterNames) {
      try {
        final candidate = parameterName == 'useMinorArcana'
            ? value.useMinorArcana
            : value.includeMinorArcana;
        if (candidate is bool) return candidate;
      } on NoSuchMethodError {
        // Try the other spelling.
      }
    }
    fail(
      'TarotReadingConfig must expose useMinorArcana or includeMinorArcana.',
    );
  }

  static String inputKey(Map<String, Object?> input) {
    for (final parameterName in parameterNames) {
      if (input.containsKey(parameterName)) return parameterName;
    }
    fail(
      'Encoded Tarot input must persist useMinorArcana or includeMinorArcana.',
    );
  }

  static ToolSessionAdapter adapter() => ToolSessionAdapter(
    descriptor: const ToolDescriptor(
      id: 'tarot',
      name: '塔罗',
      description: 'Minor arcana independent QA module',
      route: '/tools/tarot',
      icon: Icons.auto_awesome_outlined,
      accent: ToolAccent.tarot,
    ),
    codec: const TarotSessionCodec(),
  );
}

final class TarotMinorArcanaQaRandomSource implements RandomSource {
  TarotMinorArcanaQaRandomSource({this.returnMaximum = true});

  final bool returnMaximum;
  final List<int> bounds = <int>[];

  int get calls => bounds.length;

  @override
  int nextInt(int maxExclusive) {
    bounds.add(maxExclusive);
    if (returnMaximum) return maxExclusive - 1;
    return (bounds.length * 17) % maxExclusive;
  }
}

final class TarotMinorArcanaQaSessionIds implements SessionIdSource {
  TarotMinorArcanaQaSessionIds([Iterable<String> values = const <String>[]])
    : _values = List<String>.of(values);

  final List<String> _values;
  var _index = 0;

  @override
  String next() {
    if (_index >= _values.length) return 'minor-qa-${_index + 1}';
    return _values[_index++];
  }
}

final class TarotMinorArcanaQaSessionRepository implements SessionRepository {
  final List<SessionRecord> saved = <SessionRecord>[];

  @override
  Future<SessionRecord?> findById(String id) async {
    for (final session in saved) {
      if (session.id == id) return session;
    }
    return null;
  }

  @override
  Future<List<SessionRecord>> findAll() async =>
      List<SessionRecord>.unmodifiable(saved.reversed);

  @override
  Future<void> save(SessionRecord session) async => saved.add(session);
}
