import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/session/session.dart';

void main() {
  test(
    'session deeply freezes nested maps, lists, and sets in both payloads',
    () {
      final inputTags = <Object?>{'tabletop'};
      final input = <String, Object?>{
        'options': <String, Object?>{
          'labels': <Object?>['first'],
          'tags': inputTags,
        },
      };
      final outcomeCards = <Object?>[
        <String, Object?>{'id': 'clubs-two'},
      ];
      final outcome = <String, Object?>{'cards': outcomeCards};

      final session = SessionRecord(
        id: 'deep-freeze',
        toolId: 'fake',
        schemaVersion: 1,
        ruleVersion: 'fake/1',
        algorithmVersion: 'random/1',
        status: SessionStatus.completed,
        input: input,
        outcome: outcome,
      );

      inputTags.add('mutated');
      (input['options']! as Map<String, Object?>)['labels'] = <Object?>[
        'changed',
      ];
      (outcomeCards.single as Map<String, Object?>)['id'] = 'spades-ace';

      final frozenOptions = session.input['options']! as Map<String, Object?>;
      final frozenLabels = frozenOptions['labels']! as List<Object?>;
      final frozenTags = frozenOptions['tags']! as Set<Object?>;
      final frozenCards = session.outcome['cards']! as List<Object?>;
      final frozenCard = frozenCards.single as Map<String, Object?>;

      expect(frozenLabels, <Object?>['first']);
      expect(frozenTags, <Object?>{'tabletop'});
      expect(frozenCard['id'], 'clubs-two');
      expect(() => frozenLabels.add('second'), throwsUnsupportedError);
      expect(() => frozenTags.add('second'), throwsUnsupportedError);
      expect(() => frozenCard['id'] = 'diamonds-ace', throwsUnsupportedError);
    },
  );

  test('session freezes map list and set combinations without alias leaks', () {
    final nestedList = <Object?>[
      <String, Object?>{
        'choices': <Object?>{
          <Object?>['heads', 'tails'],
        },
      },
    ];
    final session = SessionRecord(
      id: 'nested-combinations',
      toolId: 'fake',
      schemaVersion: 1,
      ruleVersion: 'fake/1',
      algorithmVersion: 'random/1',
      status: SessionStatus.completed,
      input: <String, Object?>{'nested': nestedList},
      outcome: const <String, Object?>{},
    );

    final sourceMap = nestedList.single! as Map<String, Object?>;
    final sourceSet = sourceMap['choices']! as Set<Object?>;
    final sourceInnerList = sourceSet.single! as List<Object?>;
    sourceInnerList[0] = 'mutated';
    sourceSet.add('added');
    sourceMap['extra'] = true;
    nestedList.clear();

    final frozenNested = session.input['nested']! as List<Object?>;
    final frozenMap = frozenNested.single! as Map<String, Object?>;
    final frozenSet = frozenMap['choices']! as Set<Object?>;
    final frozenInnerList = frozenSet.single! as List<Object?>;

    expect(frozenInnerList, <Object?>['heads', 'tails']);
    expect(frozenMap, isNot(contains('extra')));
    expect(() => frozenNested.clear(), throwsUnsupportedError);
    expect(() => frozenSet.clear(), throwsUnsupportedError);
    expect(() => frozenInnerList[0] = 'changed', throwsUnsupportedError);
  });

  test('session rejects direct and indirect collection cycles', () {
    final directList = <Object?>[];
    directList.add(directList);

    final indirectMap = <String, Object?>{};
    final indirectList = <Object?>[indirectMap];
    indirectMap['back'] = indirectList;

    expect(
      () => SessionRecord(
        id: 'direct-cycle',
        toolId: 'fake',
        schemaVersion: 1,
        ruleVersion: 'fake/1',
        algorithmVersion: 'random/1',
        status: SessionStatus.completed,
        input: <String, Object?>{'cycle': directList},
        outcome: const <String, Object?>{},
      ),
      throwsArgumentError,
    );
    expect(
      () => SessionRecord(
        id: 'indirect-cycle',
        toolId: 'fake',
        schemaVersion: 1,
        ruleVersion: 'fake/1',
        algorithmVersion: 'random/1',
        status: SessionStatus.completed,
        input: const <String, Object?>{},
        outcome: <String, Object?>{'cycle': indirectMap},
      ),
      throwsArgumentError,
    );
  });

  test('session rejects non-string nested keys and unsupported values', () {
    expect(
      () => SessionRecord(
        id: 'illegal-key',
        toolId: 'fake',
        schemaVersion: 1,
        ruleVersion: 'fake/1',
        algorithmVersion: 'random/1',
        status: SessionStatus.completed,
        input: <String, Object?>{
          'nested': <Object?, Object?>{1: 'not-json-compatible'},
        },
        outcome: const <String, Object?>{},
      ),
      throwsArgumentError,
    );
    expect(
      () => deepFreezeValue(DateTime.utc(2026, 8, 23)),
      throwsArgumentError,
    );
  });
}
