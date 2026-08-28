import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/pocketools_app.dart';
import 'package:pocketools/app/presentation/app_settings_controller.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';
import 'package:pocketools/core/random/random_source.dart';

void main() {
  testWidgets('leaving and reopening tarot restores the same shell session', (
    tester,
  ) async {
    final random = _RecordingRandomSource(<int>[...List<int>.filled(77, 0), 1]);
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

    await tester.ensureVisible(find.text('塔罗'));
    await tester.tap(find.text('塔罗'));
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.textContaining('今日提示 · 愚者 · 正位'), findsOneWidget);
    expect(random.consumed, 2);

    await tester.tap(find.byIcon(Icons.home));
    await tester.pump();
    await tester.ensureVisible(find.text('塔罗'));
    await tester.tap(find.text('塔罗'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('今日提示 · 愚者 · 正位'), findsOneWidget);
    expect(find.text('再次抽牌会创建关联的新会话，不修改当前结果'), findsOneWidget);
    expect(random.consumed, 2);
  });

  testWidgets('leaving during motion restores the frozen shell session', (
    tester,
  ) async {
    final random = _RecordingRandomSource(<int>[...List<int>.filled(77, 0), 0]);
    await tester.pumpWidget(
      PocketoolsApp(
        randomSource: random,
        feedbackService: const NoopFeedbackService(),
        settings: AppSettingsController(
          reduceMotion: false,
          feedbackEnabled: false,
        ),
      ),
    );

    await tester.ensureVisible(find.text('塔罗'));
    await tester.tap(find.text('塔罗'));
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('tarot-deck')));
    await tester.tap(find.byKey(const Key('tarot-deck')));
    await tester.pump();
    expect(random.consumed, 2);

    await tester.tap(find.byIcon(Icons.home));
    await tester.pump();
    await tester.ensureVisible(find.text('塔罗'));
    await tester.tap(find.text('塔罗'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('今日提示 · 愚者 · 正位'), findsOneWidget);
    expect(random.consumed, 2);
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
