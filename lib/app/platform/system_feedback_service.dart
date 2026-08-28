import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/feedback/feedback_service.dart';
import 'web_vibration_adapter_stub.dart'
    if (dart.library.js_interop) 'web_vibration_adapter_web.dart';

final class SystemFeedbackService implements FeedbackService {
  const SystemFeedbackService();

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> emit(FeedbackIntensity intensity) async {
    if (kIsWeb) {
      await emitWebVibration(intensity);
      return;
    }
    if (!_isSupported) return;
    try {
      switch (intensity) {
        case FeedbackIntensity.light:
          await HapticFeedback.lightImpact();
          break;
        case FeedbackIntensity.medium:
          await HapticFeedback.mediumImpact();
          break;
      }
    } on PlatformException {
      // Feedback is always optional and must not interrupt result display.
    }
  }
}
