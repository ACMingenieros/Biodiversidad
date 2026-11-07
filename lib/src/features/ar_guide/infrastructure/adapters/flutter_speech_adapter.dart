import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../domain/ports/speech_port.dart';

/// Adapter implementing [SpeechPort] using `flutter_tts` and `speech_to_text`.
///
/// Configures a friendly, high-pitched (`pitch: 1.42`) and natural Spanish voice
/// for Ukumari while emitting a real-time 30Hz syllable envelope on
/// [lipSyncAmplitudeStream] to drive the `Boca_abierta` morph target.
class FlutterSpeechAdapter implements SpeechPort {
  FlutterSpeechAdapter({
    FlutterTts? tts,
    stt.SpeechToText? speechToText,
  })  : _tts = tts ?? FlutterTts(),
        _speechToText = speechToText ?? stt.SpeechToText();

  final FlutterTts _tts;
  final stt.SpeechToText _speechToText;
  final StreamController<double> _lipSyncController =
      StreamController<double>.broadcast();

  Timer? _envelopeTimer;
  Completer<void>? _activeSpeechCompleter;
  bool _sttAvailable = false;
  String _activeSpokenText = '';
  int _activeCharCursor = 0;
  double _elapsedTicks = 0;

  @override
  Stream<double> get lipSyncAmplitudeStream => _lipSyncController.stream;

  @override
  bool get isSpeechRecognitionAvailable => _sttAvailable;

  @override
  Future<void> initialize() async {
    try {
      await _configureHighPitchedNaturalSpanishVoice();
      await _tts.setSpeechRate(0.50);
      await _tts.setPitch(1.42);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);

      _tts.setProgressHandler((String text, int start, int end, String word) {
        _activeCharCursor = start;
      });

      _tts.setCompletionHandler(() {
        _stopLipSyncEnvelope();
        _completeActiveSpeech();
      });

      _tts.setCancelHandler(() {
        _stopLipSyncEnvelope();
        _completeActiveSpeech();
      });

      _tts.setErrorHandler((dynamic _) {
        _stopLipSyncEnvelope();
        _completeActiveSpeech();
      });
    } catch (_) {
      // Continue gracefully if platform TTS encounters limits.
    }

    try {
      _sttAvailable = await _speechToText.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
    } catch (_) {
      _sttAvailable = false;
    }
  }

  Future<void> _configureHighPitchedNaturalSpanishVoice() async {
    const preferredLocales = [
      'es-PE',
      'es-US',
      'es-419',
      'es-CO',
      'es-MX',
      'es-ES',
      'es',
    ];
    for (final locale in preferredLocales) {
      try {
        final available = await _tts.isLanguageAvailable(locale);
        if (available == true || available == 1) {
          await _tts.setLanguage(locale);
          break;
        }
      } catch (_) {
        // Try next Spanish locale.
      }
    }

    // Inspect available voices to select a clean, natural Spanish voice profile
    // that sounds expressive and natural at a high pitch (1.42).
    try {
      final rawVoices = await _tts.getVoices;
      if (rawVoices is List) {
        Map<String, String>? bestVoice;
        var bestScore = -1;

        for (final entry in rawVoices) {
          if (entry is Map) {
            final name = (entry['name'] ?? '').toString();
            final locale = (entry['locale'] ?? '').toString();
            final lowerLocale = locale.toLowerCase();
            final lowerName = name.toLowerCase();

            if (!lowerLocale.startsWith('es')) continue;

            var score = 10;
            if (lowerLocale.contains('pe') ||
                lowerLocale.contains('us') ||
                lowerLocale.contains('419') ||
                lowerLocale.contains('co') ||
                lowerLocale.contains('mx')) {
              score += 25;
            }
            if (lowerName.contains('natural') ||
                lowerName.contains('wavenet') ||
                lowerName.contains('network')) {
              score += 20;
            }
            if (lowerName.contains('female') ||
                lowerName.contains('sfb') ||
                lowerName.contains('sfg') ||
                lowerName.contains('eea') ||
                lowerName.contains('loc')) {
              score += 30;
            }

            if (score > bestScore && name.isNotEmpty && locale.isNotEmpty) {
              bestScore = score;
              bestVoice = {'name': name, 'locale': locale};
            }
          }
        }

        if (bestVoice != null) {
          await _tts.setVoice(bestVoice);
        }
      }
    } catch (_) {
      // Keep default Spanish locale voice if voice enumeration is unsupported.
    }
  }

  @override
  Future<void> speak(String text) async {
    await stopSpeaking();
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _activeSpokenText = trimmed;
    _activeCharCursor = 0;
    final completer = Completer<void>();
    _activeSpeechCompleter = completer;

    _startLipSyncEnvelope();

    try {
      await _tts.setPitch(1.42);
      await _tts.setSpeechRate(0.50);
      await _tts.speak(trimmed);
    } catch (_) {
      final fallbackMs = (trimmed.length * 52).clamp(2200, 8500);
      await Future<void>.delayed(Duration(milliseconds: fallbackMs));
    } finally {
      _stopLipSyncEnvelope();
      _completeActiveSpeech();
    }

    return completer.future;
  }

  @override
  Future<void> stopSpeaking() async {
    _stopLipSyncEnvelope();
    try {
      await _tts.stop();
    } catch (_) {}
    _completeActiveSpeech();
  }

  @override
  Future<bool> startListening({
    required void Function(String transcript, bool isFinal) onTranscript,
  }) async {
    if (!_sttAvailable) {
      try {
        _sttAvailable = await _speechToText.initialize();
      } catch (_) {
        _sttAvailable = false;
      }
    }
    if (!_sttAvailable) return false;

    await stopSpeaking();
    try {
      await _speechToText.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: 'es_PE',
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
        ),
        onResult: (result) {
          onTranscript(result.recognizedWords, result.finalResult);
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (_) {}
  }

  void _startLipSyncEnvelope() {
    _envelopeTimer?.cancel();
    _elapsedTicks = 0;
    _envelopeTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      _elapsedTicks += 0.033;
      final weight = _computeSyllableEnvelope(_elapsedTicks);
      if (!_lipSyncController.isClosed) {
        _lipSyncController.add(weight);
      }
    });
  }

  double _computeSyllableEnvelope(double t) {
    final primaryWave = (math.sin(t * 34.5) * 0.5 + 0.5);
    final secondaryWave = (math.sin(t * 72.0 + 0.9) * 0.5 + 0.5);
    final phrasePause = math.sin(t * 4.2) > -0.68 ? 1.0 : 0.12;

    double vowelBoost = 0.85;
    if (_activeSpokenText.isNotEmpty) {
      final index = _activeCharCursor.clamp(0, _activeSpokenText.length - 1);
      final ch = _activeSpokenText[index].toLowerCase();
      if (ch == '.' || ch == ',' || ch == ';' || ch == ':') {
        vowelBoost = 0.1;
      } else if ('aáeéoó'.contains(ch)) {
        vowelBoost = 1.0;
      } else if ('iíuú'.contains(ch)) {
        vowelBoost = 0.65;
      }
    }

    final raw =
        (primaryWave * 0.65 + secondaryWave * 0.35) * phrasePause * vowelBoost;
    return raw.clamp(0.0, 0.95);
  }

  void _stopLipSyncEnvelope() {
    _envelopeTimer?.cancel();
    _envelopeTimer = null;
    if (!_lipSyncController.isClosed) {
      _lipSyncController.add(0.0);
    }
  }

  void _completeActiveSpeech() {
    final completer = _activeSpeechCompleter;
    _activeSpeechCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  @override
  Future<void> dispose() async {
    _stopLipSyncEnvelope();
    await stopSpeaking();
    await stopListening();
    await _lipSyncController.close();
  }
}
