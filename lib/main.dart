import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/features/ar_guide/application/guide_session_controller.dart';
import 'src/features/ar_guide/infrastructure/adapters/flutter_speech_adapter.dart';
import 'src/features/ar_guide/infrastructure/adapters/hybrid_biodiversity_advisor.dart';
import 'src/features/ar_guide/infrastructure/adapters/sceneview_ar_stage_adapter.dart';
import 'src/features/ar_guide/presentation/containers/ar_guide_screen_container.dart';
import 'src/features/ar_guide/presentation/widgets/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const UkumariArApplication());
}

/// Root widget for the BIODIVERSIDAD — UNSM Augmented Reality Guide.
class UkumariArApplication extends StatefulWidget {
  const UkumariArApplication({super.key});

  @override
  State<UkumariArApplication> createState() => _UkumariArApplicationState();
}

class _UkumariArApplicationState extends State<UkumariArApplication> {
  GuideSessionController? _sessionController;
  SceneViewArStageAdapter? _stageAdapter;

  void _startExperience() {
    const envGeminiKey = String.fromEnvironment('GEMINI_API_KEY');
    final stage = SceneViewArStageAdapter();
    final controller = GuideSessionController(
      advisorPort: HybridBiodiversityAdvisor(
        initialApiKey: envGeminiKey.isEmpty ? null : envGeminiKey,
      ),
      speechPort: FlutterSpeechAdapter(),
      arStagePort: stage,
    );
    setState(() {
      _sessionController = controller;
      _stageAdapter = stage;
    });
  }

  void _closeExperience() {
    setState(() {
      _sessionController = null;
      _stageAdapter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biodiversidad UNSM · Ukumari AR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0E632F),
          primary: const Color(0xFF0E632F),
          surface: const Color(0xFFEFECE1),
        ),
        scaffoldBackgroundColor: const Color(0xFF083D1C),
      ),
      home: _sessionController != null
          ? ArGuideScreenContainer(
              key: ValueKey(_sessionController),
              sessionController: _sessionController!,
              stageAdapter: _stageAdapter!,
              onExit: _closeExperience,
            )
          : WelcomeScreen(onStart: _startExperience),
    );
  }
}
