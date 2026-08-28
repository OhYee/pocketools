import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/session/session.dart';

void main() {
  test('session maps and repository results are immutable snapshots', () async {
    final input = <String, Object?>{'count': 1};
    final session = SessionRecord(
      id: 'session-1',
      toolId: 'fake',
      schemaVersion: 1,
      ruleVersion: 'fake/1',
      algorithmVersion: 'random/1',
      status: SessionStatus.completed,
      input: input,
      outcome: <String, Object?>{'value': 4},
    );
    input['count'] = 2;

    expect(session.input['count'], 1);
    expect(() => session.outcome['value'] = 5, throwsUnsupportedError);

    final repository = InMemorySessionRepository();
    await repository.save(session);
    final sessions = await repository.findAll();
    expect(sessions.single, same(session));
    expect(() => sessions.clear(), throwsUnsupportedError);
  });

  test('session outcome is deeply immutable', () {
    final cards = <Object?>['clubs-two', 'hearts-ace'];
    final sourceOutcome = <String, Object?>{
      'cards': cards,
      'metadata': <String, Object?>{'remainingCount': 50},
    };
    final session = SessionRecord(
      id: 'session-cards',
      toolId: 'cards',
      schemaVersion: 1,
      ruleVersion: 'cards/1',
      algorithmVersion: 'random/1',
      status: SessionStatus.completed,
      input: const <String, Object?>{'drawCount': 2, 'includeJokers': false},
      outcome: sourceOutcome,
    );

    cards[0] = 'spades-king';
    (sourceOutcome['metadata']! as Map<String, Object?>)['remainingCount'] = 0;

    expect(session.outcome['cards'], <Object?>['clubs-two', 'hearts-ace']);
    expect(session.outcome['metadata'], <String, Object?>{
      'remainingCount': 50,
    });
    expect(
      () => (session.outcome['cards']! as List<Object?>)[0] = 'diamonds-two',
      throwsUnsupportedError,
    );
  });
}
