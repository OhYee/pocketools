import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/pocketools_app.dart';
import 'package:pocketools/app/presentation/app_settings_controller.dart';
import 'package:pocketools/app/presentation/app_warning_controller.dart';
import 'package:pocketools/app/registry/default_tool_registry.dart';
import 'package:pocketools/core/random/random_source.dart';
import 'package:pocketools/core/session/resilient_session_repository.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_history.dart';
import 'package:pocketools/core/session/session_id_source.dart';

void main() {
  testWidgets('durable save failure reveals one transient result and warning', (
    tester,
  ) async {
    final warnings = AppWarningController();
    final persistent = _WriteFailureHistory();
    final transient = InMemorySessionRepository();
    final repository = ResilientSessionRepository(
      persistentRepository: persistent,
      persistentHistory: persistent,
      transientRepository: transient,
      historyEnabled: () => true,
      onWarning: warnings.show,
    );
    final idSource = _FixedIdSource();
    final random = _RecordingRandomSource();
    final registry = buildDefaultToolRegistry(
      sessionRepository: repository,
      sessionIdSource: idSource,
    );

    await tester.pumpWidget(
      PocketoolsApp(
        registry: registry,
        randomSource: random,
        settings: AppSettingsController(reduceMotion: true),
        sessionRepository: repository,
        historyRepository: repository,
        sessionIdSource: idSource,
        warnings: warnings,
      ),
    );
    await tester.tap(find.byKey(const Key('home-tool-d20')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('roll-button')));
    await tester.tap(find.byKey(const Key('roll-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('本次应用会话'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(random.consumed, 1);
    expect(await transient.findAll(), hasLength(1));
    expect((await transient.findAll()).single.id, 'fallback-session');
  });
}

final class _FixedIdSource implements SessionIdSource {
  @override
  String next() => 'fallback-session';
}

final class _RecordingRandomSource implements RandomSource {
  var consumed = 0;

  @override
  int nextInt(int maxExclusive) {
    consumed++;
    return 0;
  }
}

final class _WriteFailureHistory
    implements SessionRepository, SessionHistoryRepository {
  @override
  Future<void> save(SessionRecord session) =>
      Future<void>.error(StateError('write failed'));

  @override
  Future<SessionRecord?> findById(String id) async => null;

  @override
  Future<List<SessionRecord>> findAll() async => const <SessionRecord>[];

  @override
  Future<void> clearHistory() async {}

  @override
  Future<void> deleteById(String id) async {}

  @override
  Future<void> deleteByTool(String toolId) async {}

  @override
  Future<HistoryEntry?> findHistoryEntry(String id) async => null;

  @override
  Future<List<HistoryEntry>> listHistory({String? toolId}) async =>
      const <HistoryEntry>[];

  @override
  Future<SessionLoadReport> loadReport() async => SessionLoadReport();

  @override
  Future<void> updateAnnotation(
    String id,
    SessionAnnotation annotation,
  ) async {}
}
