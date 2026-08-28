import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/platform/system_feedback_service.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('unsupported platforms silently skip haptics', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });

    await const SystemFeedbackService().emit(FeedbackIntensity.light);

    expect(calls, isEmpty);
  });

  test('Android maps light and medium feedback to platform calls', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });

    const service = SystemFeedbackService();
    await service.emit(FeedbackIntensity.light);
    await service.emit(FeedbackIntensity.medium);

    expect(calls.map((call) => call.method), <String>[
      'HapticFeedback.vibrate',
      'HapticFeedback.vibrate',
    ]);
    expect(calls.map((call) => call.arguments), <Object?>[
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
    ]);
  });

  test('Android platform errors remain a no-op', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => throw PlatformException(code: 'unavailable'),
    );

    await expectLater(
      const SystemFeedbackService().emit(FeedbackIntensity.light),
      completes,
    );
  });
}
