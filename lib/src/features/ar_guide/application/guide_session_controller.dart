import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/entities/biodiversity_topic.dart';
import '../domain/entities/guide_response.dart';
import '../domain/entities/ukumari_animation.dart';
import '../domain/ports/ar_stage_port.dart';
import '../domain/ports/biodiversity_advisor_port.dart';
import '../domain/ports/speech_port.dart';

/// Represents the current interaction phase of the Ukumari AR guide session.
enum GuideSessionPhase {
  initializing,
  readyIdle,
  listeningUserVoice,
  thinkingAnswer,
  speakingResponse,
}

class OfflineQuiz {
  const OfflineQuiz({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.successAnimation,
    required this.failureAnimation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final UkumariAnimation successAnimation;
  final UkumariAnimation failureAnimation;
}

/// Application layer state machine coordinating the 3D AR stage, studio neural
/// audio + real-time waveform lip-sync, continuous organic animations, and
/// clickable questions.
class GuideSessionController extends ChangeNotifier {
  GuideSessionController({
    required this.advisorPort,
    required this.speechPort,
    required this.arStagePort,
  });

  final BiodiversityAdvisorPort advisorPort;
  final SpeechPort speechPort;
  final ArStagePort arStagePort;

  StreamSubscription<double>? _lipSyncSubscription;
  Timer? _gestureTransitionTimer;
  int _activeSpeechToken = 0;
  int _offlinePointToken = 0;
  int _tourSceneIndex = 0;
  bool _disposed = false;

  GuideSessionPhase _phase = GuideSessionPhase.initializing;
  UkumariAnimation _currentAnimation = UkumariAnimation.wave;
  BiodiversityTopic? _selectedTopic;
  String _subtitleText =
      '¡Hola! Soy Ukumari, tu guía de Biodiversidad de la UNSM. ¡Qué alegría verte por aquí! Toca una de las preguntas de abajo para descubrir nuestra ruta en Tarapoto.';
  final String _partialVoiceTranscript = '';
  List<String> _followUpSuggestions = const [
    '¿Cómo llegar a la biodiversidad?',
    '¿Qué hay en la biodiversidad?',
  ];
  GuideResponseSource _lastResponseSource = GuideResponseSource.localKnowledge;
  bool _isVoiceMuted = false;
  bool _isStageLoaded = false;
  double _characterScale = 0.40;
  double _currentLipSyncWeight = 0.0;

  // Public read-only state getters
  GuideSessionPhase get phase => _phase;
  UkumariAnimation get currentAnimation => _currentAnimation;
  BiodiversityTopic? get selectedTopic => _selectedTopic;
  String get subtitleText => _subtitleText;
  String get partialVoiceTranscript => _partialVoiceTranscript;
  List<String> get followUpSuggestions => _followUpSuggestions;
  GuideResponseSource get lastResponseSource => _lastResponseSource;
  bool get isVoiceMuted => _isVoiceMuted;
  bool get isStageLoaded => _isStageLoaded;
  double get characterScale => _characterScale;
  double get currentLipSyncWeight => _currentLipSyncWeight;
  int get tourSceneIndex => _tourSceneIndex;
  String get tourSceneTitle => const [
    'Bienvenida',
    'Cómo llegar',
    'Qué encontrarás',
    'Despedida',
  ][_tourSceneIndex];
  bool get isLastTourScene => _tourSceneIndex == 3;
  bool get hasCloudAiKey => advisorPort.hasCloudAiKey;
  List<BiodiversityTopic> get topics => BiodiversityTopic.defaultCatalog;

  /// Initializes the speech subsystem and subscribes to the fallback 30Hz
  /// `Boca_abierta` lip-sync amplitude envelope stream.
  Future<void> initialize() async {
    await speechPort.initialize();
    if (_disposed) return;
    _lipSyncSubscription = speechPort.lipSyncAmplitudeStream.listen((weight) {
      _currentLipSyncWeight = weight;
      arStagePort.setLipSyncAmplitude(weight);
    });
    _phase = GuideSessionPhase.readyIdle;
    notifyListeners();
  }

  /// Invoked by the WebGL AR stage once `Ukumari_AR_Produccion.glb` is parsed
  /// and ready to play skeletal and morph target animations.
  Future<void> onArStageReady() async {
    if (_isStageLoaded) return;
    _isStageLoaded = true;
    notifyListeners();
    await playWelcomeGreeting();
  }

  /// Plays Ukumari's initial greeting (`02_Saludo`) with studio neural voice
  /// narration and real-time waveform lip-sync.
  Future<void> playWelcomeGreeting() async {
    _tourSceneIndex = 0;
    const greetingText =
        '¡Hola! Soy Ukumari, tu guía de Biodiversidad de la UNSM. ¡Qué alegría verte por aquí! Toca una de las preguntas de abajo para descubrir nuestra ruta en Tarapoto.';
    await _deliverResponse(
      const GuideResponse(
        replyText: greetingText,
        primaryAnimation: UkumariAnimation.wave,
        followUpSuggestions: [
          '¿Cómo llegar a la biodiversidad?',
          '¿Qué hay en la biodiversidad?',
        ],
        source: GuideResponseSource.localKnowledge,
        topicTitle: 'Bienvenida · Biodiversidad UNSM',
        audioAssetKey: 'saludo_inicial',
      ),
    );
  }

  /// Explains one of the official biodiversity topics.
  Future<void> selectTopic(BiodiversityTopic topic) async {
    final topicIndex = BiodiversityTopic.defaultCatalog.indexOf(topic);
    if (topicIndex >= 0) _tourSceneIndex = topicIndex + 1;
    _selectedTopic = topic;
    notifyListeners();

    final response = await advisorPort.explainTopic(topic);
    await _deliverResponse(response);
  }

  Future<void> playTourScene(int index) async {
    await cancelOfflinePoint();
    _tourSceneIndex = index % 4;
    notifyListeners();
    switch (_tourSceneIndex) {
      case 0:
        await playWelcomeGreeting();
      case 1:
        await selectTopic(BiodiversityTopic.defaultCatalog[0]);
      case 2:
        await selectTopic(BiodiversityTopic.defaultCatalog[1]);
      case 3:
        await _deliverResponse(
          const GuideResponse(
            replyText: '¡Gracias por recorrer Biodiversidad con nosotros! Cuida este bosque nublado y vuelve pronto. ¡Hasta la próxima!',
            primaryAnimation: UkumariAnimation.goodbye,
            followUpSuggestions: [],
            source: GuideResponseSource.localKnowledge,
            topicTitle: 'Despedida · Biodiversidad UNSM',
          ),
        );
    }
  }

  Future<void> replayTourScene() => playTourScene(_tourSceneIndex);
  Future<void> nextTourScene() => playTourScene((_tourSceneIndex + 1) % 4);

  /// Narrates one approved offline QR stop with its suggested gestures.
  Future<OfflineQuiz?> playOfflinePoint(Map<String, dynamic> point) async {
    final playbackToken = ++_offlinePointToken;
    if (point['fuente'] == 'por_validar') {
      _subtitleText = 'Este contenido está pendiente de validación.';
      notifyListeners();
      return null;
    }

    final greetings = (point['saludos'] as List<dynamic>).cast<String>();
    if (greetings.isNotEmpty) {
      await _deliverResponse(
        GuideResponse(
          replyText: greetings[Random().nextInt(greetings.length)],
          primaryAnimation: UkumariAnimation.wave,
          followUpSuggestions: const [],
          source: GuideResponseSource.localKnowledge,
          topicTitle: point['nombre'] as String,
        ),
      );
      if (playbackToken != _offlinePointToken) return null;
    }

    final messages =
        (point['mensajes'] as List<dynamic>)
            .map((value) => Map<String, dynamic>.from(value as Map))
            .toList()
          ..sort((a, b) => (a['orden'] as num).compareTo(b['orden'] as num));
    for (final message in messages) {
      if (playbackToken != _offlinePointToken) return null;
      await _deliverResponse(
        GuideResponse(
          replyText: message['texto'] as String,
          primaryAnimation: UkumariAnimation.fromContentCue(
            message['animacion'] as String? ?? 'explicar',
          ),
          followUpSuggestions: const [],
          source: GuideResponseSource.localKnowledge,
          topicTitle: point['nombre'] as String,
        ),
      );
    }
    if (playbackToken != _offlinePointToken) return null;
    final rawQuiz = point['pregunta'];
    if (rawQuiz is! Map) return null;
    final quiz = Map<String, dynamic>.from(rawQuiz);
    final originalOptions = (quiz['opciones'] as List<dynamic>).cast<String>();
    final order = List<int>.generate(originalOptions.length, (index) => index)
      ..shuffle(Random());
    return OfflineQuiz(
      question: quiz['texto'] as String,
      options: order.map((index) => originalOptions[index]).toList(),
      correctIndex: order.indexOf(quiz['correcta'] as int),
      successAnimation: UkumariAnimation.fromContentCue(
        quiz['animacion_acierto'] as String? ?? 'celebrar',
      ),
      failureAnimation: UkumariAnimation.fromContentCue(
        quiz['animacion_fallo'] as String? ?? 'pensar',
      ),
    );
  }

  Future<void> cancelOfflinePoint() async {
    ++_offlinePointToken;
    ++_activeSpeechToken;
    _gestureTransitionTimer?.cancel();
    await arStagePort.stopNeuralAudioTrack();
    await speechPort.stopSpeaking();
    _phase = GuideSessionPhase.readyIdle;
    notifyListeners();
  }

  Future<void> answerOfflineQuiz(OfflineQuiz quiz, int selectedIndex) async {
    final correct = selectedIndex == quiz.correctIndex;
    await _deliverResponse(
      GuideResponse(
        replyText: correct
            ? '¡Muy bien! La respuesta es ${quiz.options[quiz.correctIndex]}.'
            : 'Casi. La respuesta correcta es ${quiz.options[quiz.correctIndex]}.',
        primaryAnimation: correct
            ? quiz.successAnimation
            : quiz.failureAnimation,
        followUpSuggestions: const [],
        source: GuideResponseSource.localKnowledge,
      ),
    );
  }

  /// Submits a clicked question and triggers neural voice narration + organic gestures.
  Future<void> submitQuestion(String rawQuestion) async {
    final question = rawQuestion.trim();
    if (question.isEmpty) return;

    await arStagePort.stopNeuralAudioTrack();
    await speechPort.stopSpeaking();
    _gestureTransitionTimer?.cancel();

    _phase = GuideSessionPhase.thinkingAnswer;
    await _setStageAnimation(UkumariAnimation.idle, loopOverride: true);
    notifyListeners();

    final response = await advisorPort.askQuestion(question);
    await _deliverResponse(response);
  }

  /// Allows manually previewing any animation bundled in Ukumari's GLB.
  Future<void> triggerManualAnimation(UkumariAnimation animation) async {
    if (_phase == GuideSessionPhase.speakingResponse) return;
    _gestureTransitionTimer?.cancel();
    await _setStageAnimation(animation, loopOverride: animation.loopsByDefault);
    notifyListeners();
    if (!animation.loopsByDefault) {
      _gestureTransitionTimer = Timer(
        Duration(milliseconds: (animation.durationSeconds * 1000).round()),
        () {
          if (_phase == GuideSessionPhase.readyIdle &&
              _currentAnimation == animation) {
            unawaited(_setStageAnimation(UkumariAnimation.idle));
            notifyListeners();
          }
        },
      );
    }
  }

  /// Toggles voice narration mute state.
  Future<void> toggleMuteVoice() async {
    _isVoiceMuted = !_isVoiceMuted;
    if (_isVoiceMuted) {
      await arStagePort.stopNeuralAudioTrack();
      await speechPort.stopSpeaking();
      await arStagePort.setLipSyncAmplitude(0.0);
      if (_phase == GuideSessionPhase.speakingResponse) {
        _phase = GuideSessionPhase.readyIdle;
        await _setStageAnimation(UkumariAnimation.idle, loopOverride: true);
      }
    }
    notifyListeners();
  }

  /// Adjusts Ukumari's 3D scale on the AR floor plane (`0.45` to `1.25`).
  Future<void> updateCharacterScale(double newScale) async {
    _characterScale = newScale.clamp(0.40, 1.25);
    await arStagePort.setCharacterScale(_characterScale);
    notifyListeners();
  }

  /// Resets Ukumari's position and scale on the AR floor reticle.
  Future<void> resetArPlacement() async {
    _characterScale = 0.40;
    await arStagePort.resetPlacement();
    notifyListeners();
  }

  /// Re-anchors Ukumari on the floor directly in front of the user's phone orientation.
  Future<void> reanchorCharacterInAr() async {
    await arStagePort.reanchorCharacterToView();
    notifyListeners();
  }

  /// Configures or clears the optional Gemini API key at runtime.
  void updateCloudApiKey(String? apiKey) {
    advisorPort.configureApiKey(apiKey);
    notifyListeners();
  }

  Future<void> _deliverResponse(GuideResponse response) async {
    final token = ++_activeSpeechToken;
    _gestureTransitionTimer?.cancel();

    _subtitleText = response.replyText;
    _followUpSuggestions = response.followUpSuggestions;
    _lastResponseSource = response.source;
    _phase = GuideSessionPhase.speakingResponse;

    final primary = response.primaryAnimation;
    await _setStageAnimation(primary, loopOverride: primary.loopsByDefault);
    notifyListeners();

    // Transition smoothly into 03_Hablar while Ukumari continues speaking
    if (primary != UkumariAnimation.talk) {
      final transitionDelayMs = ((primary.durationSeconds * 0.75) * 1000)
          .round();
      _gestureTransitionTimer = Timer(
        Duration(milliseconds: transitionDelayMs),
        () {
          if (_activeSpeechToken == token &&
              _phase == GuideSessionPhase.speakingResponse) {
            unawaited(
              _setStageAnimation(UkumariAnimation.talk, loopOverride: true),
            );
            notifyListeners();
          }
        },
      );
    }

    if (!_isVoiceMuted) {
      var playedNeural = false;
      final audioKey = response.audioAssetKey;
      if (audioKey != null) {
        playedNeural = await arStagePort.playNeuralAudioTrack(audioKey);
      }
      if (!playedNeural && _activeSpeechToken == token && !_isVoiceMuted) {
        await speechPort.speak(response.replyText);
      }
    } else {
      final readingMs = (response.replyText.length * 48).clamp(2800, 9000);
      await Future<void>.delayed(Duration(milliseconds: readingMs));
    }

    if (_activeSpeechToken != token) return;

    _gestureTransitionTimer?.cancel();
    await arStagePort.setLipSyncAmplitude(0.0);
    _phase = GuideSessionPhase.readyIdle;
    await _setStageAnimation(UkumariAnimation.idle, loopOverride: true);
    notifyListeners();
  }

  Future<void> _setStageAnimation(
    UkumariAnimation animation, {
    bool? loopOverride,
  }) async {
    _currentAnimation = animation;
    await arStagePort.playAnimation(animation, loopOverride: loopOverride);
  }

  /// Triggers a 3D floor raycast from Flutter screen coordinates, commanding
  /// Ukumari to turn and walk to the tapped floor position.
  Future<void> onTapArScreen(double x, double y, double w, double h) async {
    await arStagePort.tapArScreen(x, y, w, h);
  }

  @override
  void dispose() {
    _disposed = true;
    ++_activeSpeechToken;
    ++_offlinePointToken;
    _gestureTransitionTimer?.cancel();
    _lipSyncSubscription?.cancel();
    speechPort.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}
