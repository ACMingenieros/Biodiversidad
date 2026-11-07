import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../domain/entities/ukumari_animation.dart';
import '../../domain/ports/ar_stage_port.dart';

/// Adapter implementing [ArStagePort] over a transparent WebGL `WebViewController`.
///
/// Streams the bundled Mixamo GLB, studio neural audio tracks, and Android IMU
/// orientation into the Three.js stage with a fixed virtual floor origin.
class WebViewArStageAdapter implements ArStagePort {
  WebViewArStageAdapter({
    this.stageAssetPath = 'assets/ar_stage/stage.html',
    this.glbAssetPath = 'assets/models/Ukumari_Meshy_Mixamo_v3.glb',
  });

  final String stageAssetPath;
  final String glbAssetPath;

  static const EventChannel _arSensorChannel = EventChannel(
    'biodiversidad.unsm/ar_sensors',
  );

  static const Map<String, String> _neuralAudioAssets = {
    'saludo_inicial': 'assets/audio/saludo_inicial.mp3',
    'como_llegar': 'assets/audio/como_llegar.mp3',
    'que_hay': 'assets/audio/que_hay.mp3',
  };

  WebViewController? _webViewController;
  VoidCallback? _onModelReadyCallback;
  StreamSubscription<dynamic>? _sensorSubscription;
  Completer<bool>? _activeNeuralAudioCompleter;
  Timer? _neuralAudioSafetyTimer;
  bool _isDomReady = false;
  bool _hasInjectedAudio = false;

  /// Exposes the underlying [WebViewController] for the presentational widget.
  WebViewController? get webViewController => _webViewController;

  /// Initializes the transparent WebGL stage, configures Android WebAudio
  /// autoplay without gesture blocks, and starts the 60Hz IMU sensor stream.
  Future<WebViewController> initializeStage({
    required VoidCallback onModelReady,
  }) async {
    _onModelReadyCallback = onModelReady;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'UkumariBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleBridgeMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            _isDomReady = true;
            await _injectNeuralAudioIntoStage();
            await _injectGlbBinaryIntoStage();
            _startImuSensorBridge();
          },
        ),
      );

    final platformController = controller.platform;
    if (platformController is AndroidWebViewController) {
      await platformController.setMediaPlaybackRequiresUserGesture(false);
    }

    final stageHtml = await rootBundle.loadString(stageAssetPath);
    await controller.loadHtmlString(
      stageHtml,
      baseUrl: 'https://ukumari.local/',
    );
    _webViewController = controller;
    return controller;
  }

  /// Initializes a tiny audio-only WebView for the pre-recorded narration.
  /// The 3D model and camera are rendered by the native ARCore scene.
  Future<WebViewController> initializeAudioStage() async {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'UkumariBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleBridgeMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            _isDomReady = true;
            await _injectNeuralAudioIntoStage();
          },
        ),
      );

    final platformController = controller.platform;
    if (platformController is AndroidWebViewController) {
      await platformController.setMediaPlaybackRequiresUserGesture(false);
    }

    final audioHtml = await rootBundle.loadString(
      'assets/ar_stage/audio_stage.html',
    );
    await controller.loadHtmlString(
      audioHtml,
      baseUrl: 'https://ukumari.local/',
    );
    _webViewController = controller;
    return controller;
  }

  void _startImuSensorBridge() {
    _sensorSubscription?.cancel();
    try {
      _sensorSubscription = _arSensorChannel.receiveBroadcastStream().listen((
        dynamic event,
      ) {
        final controller = _webViewController;
        if (controller == null || !_isDomReady) return;
        if (event is List && event.length >= 6) {
          final pitch = (event[0] as num).toDouble().toStringAsFixed(4);
          final yaw = (event[1] as num).toDouble().toStringAsFixed(4);
          final roll = (event[2] as num).toDouble().toStringAsFixed(4);
          final ax = (event[3] as num).toDouble().toStringAsFixed(3);
          final ay = (event[4] as num).toDouble().toStringAsFixed(3);
          final az = (event[5] as num).toDouble().toStringAsFixed(3);
          controller.runJavaScript(
            'window.ukumariStage && window.ukumariStage.updateDevicePose($pitch, $yaw, $roll, $ax, $ay, $az);',
          );
        }
      }, onError: (_) {});
    } catch (_) {
      // Sensor stream falls back to HTML5 DeviceOrientation inside stage.html.
    }
  }

  void _handleBridgeMessage(String rawMessage) {
    try {
      final decoded = jsonDecode(rawMessage) as Map<String, dynamic>;
      final event = decoded['event'] as String?;
      if (event == 'model_ready') {
        _onModelReadyCallback?.call();
      } else if (event == 'neural_audio_completed') {
        _completeNeuralAudio(true);
      } else if (event == 'neural_audio_unavailable') {
        _completeNeuralAudio(false);
      }
    } catch (_) {
      if (rawMessage.contains('model_ready')) {
        _onModelReadyCallback?.call();
      } else if (rawMessage.contains('neural_audio_completed')) {
        _completeNeuralAudio(true);
      }
    }
  }

  void _completeNeuralAudio(bool played) {
    _neuralAudioSafetyTimer?.cancel();
    _neuralAudioSafetyTimer = null;
    final completer = _activeNeuralAudioCompleter;
    _activeNeuralAudioCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(played);
    }
  }

  Future<void> _injectNeuralAudioIntoStage() async {
    final controller = _webViewController;
    if (controller == null || !_isDomReady) return;

    for (final entry in _neuralAudioAssets.entries) {
      try {
        final byteData = await rootBundle.load(entry.value);
        final bytes = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        final b64 = base64Encode(bytes);
        await controller.runJavaScript(
          'window.ukumariStage && window.ukumariStage.registerNeuralAudio("${entry.key}", "$b64");',
        );
      } catch (_) {}
    }
    _hasInjectedAudio = true;
  }

  /// Reads `Ukumari_AR_Produccion.glb` from Flutter's asset bundle and transfers
  /// it in safe 512 KB Base64 chunks into the Three.js `GLTFLoader`.
  Future<void> _injectGlbBinaryIntoStage() async {
    final controller = _webViewController;
    if (controller == null || !_isDomReady) return;

    final byteData = await rootBundle.load(glbAssetPath);
    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    final base64Full = base64Encode(bytes);

    await controller.runJavaScript('window.ukumariStage.beginGlbTransfer();');

    const chunkSize = 524288; // 512 KB per chunk
    for (var offset = 0; offset < base64Full.length; offset += chunkSize) {
      final end = (offset + chunkSize < base64Full.length)
          ? offset + chunkSize
          : base64Full.length;
      final chunk = base64Full.substring(offset, end);
      await controller.runJavaScript(
        'window.ukumariStage.appendGlbChunk("$chunk");',
      );
    }

    await controller.runJavaScript('window.ukumariStage.finishGlbTransfer();');
  }

  @override
  Future<bool> playNeuralAudioTrack(String trackKey) async {
    final controller = _webViewController;
    if (controller == null ||
        !_isDomReady ||
        !_hasInjectedAudio ||
        !_neuralAudioAssets.containsKey(trackKey)) {
      return false;
    }

    await stopNeuralAudioTrack();

    final completer = Completer<bool>();
    _activeNeuralAudioCompleter = completer;

    final timeoutSeconds = switch (trackKey) {
      'saludo_inicial' => 13,
      'como_llegar' => 23,
      'que_hay' => 32,
      _ => 25,
    };

    _neuralAudioSafetyTimer = Timer(Duration(seconds: timeoutSeconds), () {
      _completeNeuralAudio(true);
    });

    await controller.runJavaScript(
      'window.ukumariStage && window.ukumariStage.playNeuralAudio("$trackKey");',
    );

    return completer.future;
  }

  @override
  Future<void> stopNeuralAudioTrack() async {
    final controller = _webViewController;
    _completeNeuralAudio(true);
    if (controller == null || !_isDomReady) return;
    await controller.runJavaScript(
      'window.ukumariStage && window.ukumariStage.stopNeuralAudio();',
    );
  }

  @override
  Future<void> playAnimation(
    UkumariAnimation animation, {
    bool? loopOverride,
  }) async {
    final controller = _webViewController;
    if (controller == null || !_isDomReady) return;
    final shouldLoop = loopOverride ?? animation.loopsByDefault;
    await controller.runJavaScript(
      'window.ukumariStage && window.ukumariStage.playAnimation("${animation.clipName}", $shouldLoop);',
    );
  }

  @override
  Future<void> setLipSyncAmplitude(double amplitude) async {
    final controller = _webViewController;
    if (controller == null || !_isDomReady) return;
    final clamped = amplitude.clamp(0.0, 1.0).toStringAsFixed(3);
    await controller.runJavaScript(
      'window.ukumariStage && window.ukumariStage.setLipSync($clamped);',
    );
  }

  @override
  Future<void> setCharacterScale(double scale) async {
    final controller = _webViewController;
    if (controller == null || !_isDomReady) return;
    final clamped = scale.clamp(0.45, 1.25).toStringAsFixed(2);
    await controller.runJavaScript(
      'window.ukumariStage && window.ukumariStage.setScale($clamped);',
    );
  }

  @override
  Future<void> resetPlacement() async {
    final controller = _webViewController;
    if (controller == null || !_isDomReady) return;
    await controller.runJavaScript(
      'window.ukumariStage && window.ukumariStage.resetPlacement();',
    );
  }

  @override
  Future<void> reanchorCharacterToView() async {
    final controller = _webViewController;
    if (controller == null || !_isDomReady) return;
    await controller.runJavaScript(
      'window.ukumariStage && window.ukumariStage.reanchorToCurrentView();',
    );
  }

  @override
  Future<void> tapArScreen(
    double x,
    double y,
    double width,
    double height,
  ) async {
    final controller = _webViewController;
    if (controller == null || !_isDomReady) return;
    await controller.runJavaScript(
      'window.ukumariStage && window.ukumariStage.handleScreenTap($x, $y, $width, $height);',
    );
  }

  @override
  Future<void> setReticleVisible(bool visible) async {
    final controller = _webViewController;
    if (controller == null || !_isDomReady) return;
    await controller.runJavaScript(
      'window.ukumariStage && window.ukumariStage.setReticleVisible($visible);',
    );
  }

  void dispose() {
    _sensorSubscription?.cancel();
    _neuralAudioSafetyTimer?.cancel();
  }
}
