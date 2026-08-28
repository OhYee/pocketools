import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/app_composition.dart';
import 'package:pocketools/app/pocketools_app.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/local_string_store.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_id_source.dart';
import 'package:pocketools/core/tools/session_actions.dart';

void main() {
  testWidgets(
    'production composition starts and uses transient sessions when reads fail',
    (tester) async {
      final composition = await PocketoolsComposition.production(
        stringStore: _ReadFailureStore(),
        randomSource: SequenceRandomSource(const <int>[]),
        sessionIdSource: _FixedSessionIdSource(),
        textGateway: const NoopSessionTextGateway(),
        feedbackService: const NoopFeedbackService(),
      );

      expect(composition.warnings.message, contains('结果将保留在本次会话'));
      final session = SessionRecord(
        id: 'transient-session',
        toolId: 'test-tool',
        schemaVersion: 1,
        ruleVersion: 'test-rule-v1',
        algorithmVersion: 'test-algorithm-v1',
        status: SessionStatus.completed,
        input: const <String, Object?>{'value': 1},
        outcome: const <String, Object?>{'value': 2},
      );
      await composition.sessionRepository.save(session);
      expect(
        await composition.sessionRepository.findById(session.id),
        same(session),
      );

      await tester.pumpWidget(
        PocketoolsApp.production(composition: composition),
      );
      await tester.pump();
      expect(find.text('今天想用哪个工具？'), findsOneWidget);
      expect(find.text('关闭'), findsOneWidget);
    },
  );
}

final class _ReadFailureStore implements LocalStringStore {
  @override
  Future<void> clearOwned(Set<String> allowList) async {}

  @override
  Future<String?> readString(String key) =>
      Future<String?>.error(StateError('storage unavailable'));

  @override
  Future<void> remove(String key) async {}

  @override
  Future<void> writeString(String key, String value) async {}
}

final class _FixedSessionIdSource implements SessionIdSource {
  @override
  String next() => 'fixed-session-id';
}
