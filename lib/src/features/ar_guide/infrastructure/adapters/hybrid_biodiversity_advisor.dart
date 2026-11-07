import '../../domain/entities/biodiversity_topic.dart';
import '../../domain/entities/guide_response.dart';
import '../../domain/entities/ukumari_animation.dart';
import '../../domain/ports/biodiversity_advisor_port.dart';

/// Adapter implementing [BiodiversityAdvisorPort] for the official
/// Ruta Biodiversidad — UNSM (Tarapoto, San Martín) interactive guide.
class HybridBiodiversityAdvisor implements BiodiversityAdvisorPort {
  HybridBiodiversityAdvisor({String? initialApiKey})
      : _apiKey = initialApiKey?.trim();

  String? _apiKey;

  static const List<String> officialQuestions = [
    '¿Cómo llegar a la biodiversidad?',
    '¿Qué hay en la biodiversidad?',
  ];

  @override
  bool get hasCloudAiKey => _apiKey != null && _apiKey!.isNotEmpty;

  @override
  void configureApiKey(String? apiKey) {
    final trimmed = apiKey?.trim();
    _apiKey = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  Future<GuideResponse> explainTopic(BiodiversityTopic topic) async {
    return GuideResponse(
      replyText: topic.narrationScript,
      primaryAnimation: topic.primaryAnimation,
      followUpSuggestions: officialQuestions,
      source: GuideResponseSource.localKnowledge,
      topicTitle: topic.title,
      audioAssetKey: topic.audioAssetKey,
    );
  }

  @override
  Future<GuideResponse> askQuestion(String question) async {
    final normalized = _normalizeSpanish(question);

    if (_matchesAny(normalized, [
      'como llegar',
      'donde queda',
      'ubicacion',
      'direccion',
      'carretera',
      'kilometro',
      'tarapoto',
      'yurimaguas',
      'llegar',
    ])) {
      final topic = BiodiversityTopic.defaultCatalog[0];
      return GuideResponse(
        replyText: topic.narrationScript,
        primaryAnimation: UkumariAnimation.wave,
        followUpSuggestions: officialQuestions,
        source: GuideResponseSource.localKnowledge,
        topicTitle: topic.title,
        audioAssetKey: topic.audioAssetKey,
      );
    }

    if (_matchesAny(normalized, [
      'que hay',
      'zona a',
      'zona b',
      'animales',
      'especies',
      'ruta',
      'mapa',
      'condor',
      'tigrillo',
      'loros',
      'motelo',
      'piscina',
      'mirador',
    ])) {
      final topic = BiodiversityTopic.defaultCatalog[1];
      return GuideResponse(
        replyText: topic.narrationScript,
        primaryAnimation: UkumariAnimation.celebrate,
        followUpSuggestions: officialQuestions,
        source: GuideResponseSource.localKnowledge,
        topicTitle: topic.title,
        audioAssetKey: topic.audioAssetKey,
      );
    }

    // Default to explaining how to get to Biodiversity UNSM
    final defaultTopic = BiodiversityTopic.defaultCatalog[0];
    return GuideResponse(
      replyText: defaultTopic.narrationScript,
      primaryAnimation: UkumariAnimation.wave,
      followUpSuggestions: officialQuestions,
      source: GuideResponseSource.localKnowledge,
      topicTitle: defaultTopic.title,
      audioAssetKey: defaultTopic.audioAssetKey,
    );
  }

  static String _normalizeSpanish(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
  }

  static bool _matchesAny(String normalizedText, List<String> keywords) {
    for (final keyword in keywords) {
      if (normalizedText.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
