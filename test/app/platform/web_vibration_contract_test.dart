import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/platform/web_vibration_contract.dart';
import 'package:pocketools/core/feedback/feedback_service.dart';

void main() {
  const available = WebVibrationCapabilities(
    hasVibrationApi: true,
    isDocumentVisible: true,
    hasUserActivation: true,
    isUserActivationActive: true,
  );

  test(
    'Web vibration requires capability, visibility, and active user gesture',
    () {
      expect(shouldEmitWebVibration(available), isTrue);
      for (final unavailable in <WebVibrationCapabilities>[
        const WebVibrationCapabilities(
          hasVibrationApi: false,
          isDocumentVisible: true,
          hasUserActivation: true,
          isUserActivationActive: true,
        ),
        const WebVibrationCapabilities(
          hasVibrationApi: true,
          isDocumentVisible: false,
          hasUserActivation: true,
          isUserActivationActive: true,
        ),
        const WebVibrationCapabilities(
          hasVibrationApi: true,
          isDocumentVisible: true,
          hasUserActivation: false,
          isUserActivationActive: false,
        ),
        const WebVibrationCapabilities(
          hasVibrationApi: true,
          isDocumentVisible: true,
          hasUserActivation: true,
          isUserActivationActive: false,
        ),
      ]) {
        expect(shouldEmitWebVibration(unavailable), isFalse);
      }
    },
  );

  test('feedback patterns are intentionally short and ordered', () {
    final light = webVibrationDurationMilliseconds(FeedbackIntensity.light);
    final medium = webVibrationDurationMilliseconds(FeedbackIntensity.medium);

    expect(light, inInclusiveRange(1, 50));
    expect(medium, inInclusiveRange(1, 50));
    expect(medium, greaterThan(light));
  });
}
