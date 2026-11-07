import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:biodiversidad/src/features/ar_guide/application/guide_session_controller.dart';
import 'package:biodiversidad/src/features/ar_guide/domain/entities/biodiversity_topic.dart';
import 'package:biodiversidad/src/features/ar_guide/domain/entities/ukumari_animation.dart';
import 'package:biodiversidad/src/features/ar_guide/domain/ports/ar_stage_port.dart';
import 'package:biodiversidad/src/features/ar_guide/domain/ports/speech_port.dart';
import 'package:biodiversidad/src/features/ar_guide/infrastructure/adapters/hybrid_biodiversity_advisor.dart';
import 'package:biodiversidad/src/features/ar_guide/presentation/widgets/guide_speech_bubble.dart';

class _FakeSpeechPort implements SpeechPort {
  final StreamController<double> _controller =
      StreamController<double>.broadcast();
  String? lastSpokenText;

  @override
  Stream<double> get lipSyncAmplitudeStream => _controller.stream;

  @override
  bool get isSpeechRecognitionAvailable => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> speak(String text) async {
    lastSpokenText = text;
    _controller.add(0.75);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    _controller.add(0.0);
  }

  @override
  Future<void> stopSpeaking() async {
    _controller.add(0.0);
  }

  @override
  Future<bool> startListening({
    required void Function(String transcript, bool isFinal) onTranscript,
  }) async {
    onTranscript('¿Cómo llegar a la biodiversidad?', true);
    return true;
  }

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

class _FakeArStagePort implements ArStagePort {
  final List<UkumariAnimation> playedAnimations = [];
  final List<String> neuralTracksRequested = [];
  double lastLipSyncAmplitude = 0.0;
  bool simulateNeuralAudioAvailable = false;
  int reanchorCount = 0;

  @override
  Future<void> playAnimation(
    UkumariAnimation animation, {
    bool? loopOverride,
  }) async {
    playedAnimations.add(animation);
  }

  @override
  Future<void> setLipSyncAmplitude(double amplitude) async {
    lastLipSyncAmplitude = amplitude;
  }

  @override
  Future<bool> playNeuralAudioTrack(String trackKey) async {
    neuralTracksRequested.add(trackKey);
    return simulateNeuralAudioAvailable;
  }

  @override
  Future<void> stopNeuralAudioTrack() async {}

  @override
  Future<void> setCharacterScale(double scale) async {}

  @override
  Future<void> resetPlacement() async {}

  @override
  Future<void> reanchorCharacterToView() async {
    reanchorCount++;
  }

  @override
  Future<void> tapArScreen(
    double x,
    double y,
    double width,
    double height,
  ) async {}

  @override
  Future<void> setReticleVisible(bool visible) async {}
}

void main() {
  group('Biodiversidad UNSM · GuideSessionController & Advisor', () {
    test('Maps available GLB clips accurately in UkumariAnimation', () {
      expect(UkumariAnimation.idle.clipName, '01_Reposo');
      expect(UkumariAnimation.wave.clipName, '02_Saludo');
      expect(UkumariAnimation.talk.clipName, '03_Hablar');
      expect(UkumariAnimation.nod.clipName, '04_Asentir');
      expect(UkumariAnimation.goodbye.clipName, '05_Despedida');
      expect(UkumariAnimation.celebrate.clipName, '06_Celebrar');
      expect(UkumariAnimation.curious.clipName, '07_Curioso');
      expect(UkumariAnimation.walk.clipName, '08_Caminar');
      expect(UkumariAnimation.run.clipName, '09_Correr');
      expect(UkumariAnimation.sleep.clipName, '10_Dormir');
      expect(UkumariAnimation.surprise.clipName, '11_Sorpresa');
    });

    test('Bundled Ukumari GLB contains every declared animation', () async {
      final bytes = await File('assets/models/Ukumari_Meshy_Mixamo_v3.glb')
          .readAsBytes();
      final data = ByteData.sublistView(bytes);
      expect(data.getUint32(0, Endian.little), 0x46546c67);
      final jsonLength = data.getUint32(12, Endian.little);
      final document = jsonDecode(
        utf8.decode(bytes.sublist(20, 20 + jsonLength)),
      ) as Map<String, dynamic>;
      final clips = (document['animations'] as List<dynamic>)
          .map((animation) => (animation as Map<String, dynamic>)['name'])
          .toSet();
      expect(
        clips,
        containsAll(UkumariAnimation.values.map((value) => value.clipName)),
      );
      expect(document['skins'], hasLength(1));
      expect(document['meshes'], hasLength(1));
    });

    test('Answers "¿Cómo llegar a la biodiversidad?" and triggers neural track + active movement', () async {
      final advisor = HybridBiodiversityAdvisor();
      final speech = _FakeSpeechPort();
      final stage = _FakeArStagePort();

      final controller = GuideSessionController(
        advisorPort: advisor,
        speechPort: speech,
        arStagePort: stage,
      );

      await controller.initialize();
      await controller.submitQuestion('¿Cómo llegar a la biodiversidad?');

      expect(stage.neuralTracksRequested, contains('como_llegar'));
      expect(speech.lastSpokenText, contains('17.3'));
      expect(speech.lastSpokenText, contains('Tarapoto'));
      expect(stage.playedAnimations.last, UkumariAnimation.idle);
      expect(controller.currentAnimation, UkumariAnimation.idle);
    });

    test('Answers "¿Qué hay en la biodiversidad?" with Zona A & Zona B species and neural track', () async {
      final advisor = HybridBiodiversityAdvisor();
      final speech = _FakeSpeechPort();
      final stage = _FakeArStagePort();

      final controller = GuideSessionController(
        advisorPort: advisor,
        speechPort: speech,
        arStagePort: stage,
      );

      await controller.initialize();
      final topic = BiodiversityTopic.defaultCatalog[1];
      await controller.selectTopic(topic);

      expect(controller.selectedTopic?.id, 'que_hay');
      expect(stage.neuralTracksRequested, contains('que_hay'));
      expect(speech.lastSpokenText, contains('Zona A'));
      expect(speech.lastSpokenText, contains('Zona B'));
      expect(speech.lastSpokenText, contains('cóndor amazónico'));
      expect(speech.lastSpokenText, contains('tigrillo'));
      expect(stage.playedAnimations.last, UkumariAnimation.idle);
    });

    test('Re-anchors Ukumari to the floor in AR view when requested', () async {
      final advisor = HybridBiodiversityAdvisor();
      final speech = _FakeSpeechPort();
      final stage = _FakeArStagePort();

      final controller = GuideSessionController(
        advisorPort: advisor,
        speechPort: speech,
        arStagePort: stage,
      );

      await controller.initialize();
      await controller.reanchorCharacterInAr();

      expect(stage.reanchorCount, 1);
    });

    test(
      'Tour advances through arrival, wildlife and farewell, then restarts',
      () async {
        final speech = _FakeSpeechPort();
        final stage = _FakeArStagePort();
        final controller = GuideSessionController(
          advisorPort: HybridBiodiversityAdvisor(),
          speechPort: speech,
          arStagePort: stage,
        );

        await controller.initialize();
        await controller.playWelcomeGreeting();
        expect(controller.tourSceneTitle, 'Bienvenida');
        await controller.nextTourScene();
        expect(controller.tourSceneTitle, 'Cómo llegar');
        expect(speech.lastSpokenText, contains('kilómetro 17.3'));
        await controller.nextTourScene();
        expect(controller.tourSceneTitle, 'Qué encontrarás');
        expect(speech.lastSpokenText, contains('Zona A'));
        await controller.nextTourScene();
        expect(controller.isLastTourScene, isTrue);
        expect(stage.playedAnimations, contains(UkumariAnimation.goodbye));
        await controller.replayTourScene();
        expect(speech.lastSpokenText, contains('Hasta la próxima'));
        await controller.nextTourScene();
        expect(controller.tourSceneTitle, 'Bienvenida');
      },
    );

    testWidgets(
      'GuideSpeechBubble header never overflows on narrow 300px phones while speaking',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: GuideSpeechBubble(
                    subtitleText:
                        '¡Hola! Soy Ukumari, tu guía de Biodiversidad UNSM.',
                    phase: GuideSessionPhase.speakingResponse,
                    questions: const [
                      '¿Cómo llegar a la biodiversidad?',
                      '¿Qué hay en la biodiversidad?',
                    ],
                    onQuestionTapped: (_) {},
                    onReplayScene: () {},
                    onNextScene: () {},
                    sceneTitle: 'Bienvenida',
                    isLastScene: false,
                    onOpenMapModal: () {},
                    onReanchorAr: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('📍 ¡Ven aquí!'), findsOneWidget);
      },
    );

    testWidgets(
      'GuideSpeechBubble collapses to sleek floating pill on tap and expands back',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: GuideSpeechBubble(
                    subtitleText:
                        '¡Hola! Soy Ukumari, tu guía de Biodiversidad UNSM.',
                    phase: GuideSessionPhase.readyIdle,
                    questions: const [
                      '¿Cómo llegar a la biodiversidad?',
                      '¿Qué hay en la biodiversidad?',
                    ],
                    onQuestionTapped: (_) {},
                    onReplayScene: () {},
                    onNextScene: () {},
                    sceneTitle: 'Bienvenida',
                    isLastScene: false,
                    onOpenMapModal: () {},
                    onReanchorAr: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('¿Cómo llegar a la biodiversidad?'), findsOneWidget);

        // Tap the collapse icon in the header
        await tester.tap(find.byIcon(Icons.expand_more_rounded));
        await tester.pumpAndSettle();

        // Card is now collapsed into the sleek floating pill
        expect(
          find.text('🐻 Preguntas · Toca o desliza para abrir'),
          findsOneWidget,
        );
        expect(find.text('¿Cómo llegar a la biodiversidad?'), findsNothing);

        // Tap the pill to expand back
        await tester.tap(find.text('🐻 Preguntas · Toca o desliza para abrir'));
        await tester.pumpAndSettle();

        // Fully expanded again
        expect(find.text('¿Cómo llegar a la biodiversidad?'), findsOneWidget);
      },
    );
  });
}
