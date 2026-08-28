enum FeedbackIntensity { light, medium }

/// Optional presentation feedback. Domain code must never depend on this API.
abstract interface class FeedbackService {
  Future<void> emit(FeedbackIntensity intensity);
}

final class NoopFeedbackService implements FeedbackService {
  const NoopFeedbackService();

  @override
  Future<void> emit(FeedbackIntensity intensity) async {}
}
