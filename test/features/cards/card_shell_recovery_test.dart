import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/pocketools_app.dart';
import 'package:pocketools/app/presentation/app_settings_controller.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';

void main() {
  testWidgets('leaving and reopening cards restores the same shell session', (
    tester,
  ) async {
    final random = _RecordingRandomSource(List<int>.filled(1, 0));
    await tester.pumpWidget(
      PocketoolsApp(
        randomSource: random,
        feedbackService: const NoopFeedbackService(),
        settings: AppSettingsController(
          reduceMotion: true,
          feedbackEnabled: false,
        ),
      ),
    );

    await tester.ensureVisible(find.text('抽扑克牌'));
    await tester.tap(find.text('抽扑克牌'));
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('cards-deck')));
    await tester.tap(find.byKey(const Key('cards-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('梅花 2'), findsOneWidget);
    expect(random.consumed, 1);

    await tester.tap(find.byIcon(Icons.home));
    await tester.pump();
    await tester.ensureVisible(find.text('抽扑克牌'));
    await tester.tap(find.text('抽扑克牌'));
    await tester.pump();
    await tester.pump();

    expect(find.text('梅花 2'), findsOneWidget);
    expect(find.text('梅花 3'), findsNothing);
    expect(find.text('梅花 4'), findsNothing);
    expect(find.text('重新抽取会创建新会话，不修改当前结果'), findsNothing);
    expect(random.consumed, 1);
  });
}

final class _RecordingRandomSource implements RandomSource {
  _RecordingRandomSource(Iterable<int> values)
    : _delegate = SequenceRandomSource(values);

  final SequenceRandomSource _delegate;

  int get consumed => _delegate.consumed;

  @override
  int nextInt(int maxExclusive) => _delegate.nextInt(maxExclusive);
}
