import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import '../../core/feedback/feedback_service.dart';
import 'web_vibration_contract.dart';

Future<void> emitWebVibration(FeedbackIntensity intensity) async {
  try {
    final navigator = web.window.navigator;
    final capabilities = WebVibrationCapabilities(
      hasVibrationApi: navigator.has('vibrate'),
      isDocumentVisible: web.document.visibilityState == 'visible',
      hasUserActivation: navigator.has('userActivation'),
      isUserActivationActive:
          navigator.has('userActivation') && navigator.userActivation.isActive,
    );
    if (!shouldEmitWebVibration(capabilities)) return;
    navigator.vibrate(webVibrationDurationMilliseconds(intensity).toJS);
  } on Object {
    // Vibration support, permissions, and activation can change at runtime.
  }
}
