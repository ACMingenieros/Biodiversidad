import '../entities/biodiversity_topic.dart';
import '../entities/guide_response.dart';

/// Output port defining how the application requests biodiversity explanations
/// and answers to open-ended user questions.
abstract interface class BiodiversityAdvisorPort {
  /// Generates an interactive response for a free-form user question in Spanish.
  Future<GuideResponse> askQuestion(String question);

  /// Produces a structured explanation for a selected [BiodiversityTopic].
  Future<GuideResponse> explainTopic(BiodiversityTopic topic);

  /// Updates the optional cloud AI API key at runtime.
  void configureApiKey(String? apiKey);

  /// Returns true when an external AI API key is currently configured.
  bool get hasCloudAiKey;
}
