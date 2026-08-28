import '../../core/feedback/feedback_service.dart';

final class WebVibrationCapabilities {
  const WebVibrationCapabilities({
    required this.hasVibrationApi,
    required this.isDocumentVisible,
    required this.hasUserActivation,
    required this.isUserActivationActive,
  });

  final bool hasVibrationApi;
  final bool isDocumentVisible;
  final bool hasUserActivation;
  final bool isUserActivationActive;
}

bool shouldEmitWebVibration(WebVibrationCapabilities capabilities) =>
    capabilities.hasVibrationApi &&
    capabilities.isDocumentVisible &&
    capabilities.hasUserActivation &&
    capabilities.isUserActivationActive;

int webVibrationDurationMilliseconds(FeedbackIntensity intensity) =>
    switch (intensity) {
      FeedbackIntensity.light => 12,
      FeedbackIntensity.medium => 24,
    };
