import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../application/guide_session_controller.dart';
import '../../domain/entities/ukumari_animation.dart';
import '../../infrastructure/adapters/sceneview_ar_stage_adapter.dart';
import '../../infrastructure/adapters/album_upload_service.dart';
import '../../infrastructure/adapters/offline_bear_content_catalog.dart';
import '../widgets/guide_speech_bubble.dart';

/// Smart container widget that manages hardware lifecycle (Camera, Permissions,
/// WebView 3D Stage initialization) and binds [GuideSessionController] state
/// to the clean, minimal BIODIVERSIDAD — UNSM interface.
class ArGuideScreenContainer extends StatefulWidget {
  const ArGuideScreenContainer({
    super.key,
    required this.sessionController,
    required this.stageAdapter,
    required this.onExit,
  });

  final GuideSessionController sessionController;
  final SceneViewArStageAdapter stageAdapter;
  final VoidCallback onExit;

  @override
  State<ArGuideScreenContainer> createState() => _ArGuideScreenContainerState();
}

class _BearPhotoPreview extends StatefulWidget {
  const _BearPhotoPreview({
    required this.bytes,
    required this.controller,
    required this.onClose,
  });

  final Uint8List bytes;
  final SceneViewArStageAdapter controller;
  final VoidCallback onClose;

  @override
  State<_BearPhotoPreview> createState() => _BearPhotoPreviewState();
}

class _BearPhotoPreviewState extends State<_BearPhotoPreview> {
  static const _album = AlbumUploadService();
  String? _savedUri;
  bool _working = false;
  bool _uploading = false;
  bool _uploaded = false;

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Future<String?> _saveIfNeeded() async {
    if (_savedUri != null) return _savedUri;
    try {
      final uri = await widget.controller.savePhoto(widget.bytes);
      if (mounted) setState(() => _savedUri = uri);
      return uri;
    } on PlatformException catch (error) {
      if (error.code != 'STORAGE_PERMISSION_REQUIRED') rethrow;
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        _message('Permite guardar fotos para continuar');
        return null;
      }
      final uri = await widget.controller.savePhoto(widget.bytes);
      if (mounted) setState(() => _savedUri = uri);
      return uri;
    }
  }

  Future<void> _saveOrShare({required bool share}) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final uri = await _saveIfNeeded();
      if (uri != null) {
        if (share) {
          await widget.controller.sharePhoto(uri);
        } else {
          _message('Foto guardada en Imágenes / Biodiversidad');
        }
      }
    } catch (error) {
      _message('No se pudo ${share ? 'compartir' : 'guardar'} la foto: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _upload() async {
    if (_uploading || _uploaded || _working) return;
    setState(() => _uploading = true);
    try {
      await _album.uploadPhoto(widget.bytes);
      if (mounted) {
        setState(() => _uploaded = true);
        _message('Foto añadida al álbum de Biodiversidad');
      }
    } catch (error) {
      _message('No se pudo subir la foto: $error');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _ArGuideScreenContainerState.brandDarkGreen,
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: widget.onClose,
                  tooltip: 'Cerrar foto',
                  icon: const Icon(Icons.close),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tu foto con Ukumari',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Image.memory(widget.bytes, fit: BoxFit.contain)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              children: [
                if (_album.isConfigured) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _uploading || _uploaded ? null : _upload,
                      icon: Icon(
                        _uploaded ? Icons.check : Icons.cloud_upload_outlined,
                      ),
                      label: Text(
                        _uploaded
                            ? 'Foto en el álbum'
                            : _uploading
                            ? 'Subiendo…'
                            : 'Subir al álbum',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            _ArGuideScreenContainerState.brandCream,
                        foregroundColor:
                            _ArGuideScreenContainerState.brandGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _working
                            ? null
                            : () => _saveOrShare(share: false),
                        icon: Icon(
                          _savedUri == null ? Icons.download : Icons.check,
                        ),
                        label: Text(_savedUri == null ? 'Guardar' : 'Guardada'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _working
                            ? null
                            : () => _saveOrShare(share: true),
                        icon: const Icon(Icons.share),
                        label: const Text('Compartir'),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              _ArGuideScreenContainerState.brandGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ArGuideScreenContainerState extends State<ArGuideScreenContainer>
    with WidgetsBindingObserver {
  WebViewController? _audioWebViewController;
  bool _cameraPermissionGranted = false;
  bool _arCoreReady = false;
  bool _arCoreCheckInFlight = false;
  String _arCoreStatus = 'checking';
  bool _planeDetected = false;
  bool _hasPlacedModel = false;
  bool _isScanningQr = false;
  bool _qrBusy = false;
  bool _capturingPhoto = false;
  Uint8List? _photoBytes;
  late final Future<OfflineBearContentCatalog> _offlineCatalog;
  final MobileScannerController _qrScanner = MobileScannerController(
    autoStart: false,
    formats: [BarcodeFormat.qrCode],
  );

  static const Color brandGreen = Color(0xFF0E632F);
  static const Color brandDarkGreen = Color(0xFF083D1C);
  static const Color brandCream = Color(0xFFEFECE1);

  Future<void> _takePhoto() async {
    if (_capturingPhoto ||
        _isScanningQr ||
        !_arCoreReady ||
        !widget.stageAdapter.isAttached) {
      return;
    }
    setState(() => _capturingPhoto = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      final bytes = await widget.stageAdapter.capturePhoto();
      if (mounted) setState(() => _photoBytes = bytes);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo tomar la foto: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturingPhoto = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _offlineCatalog = OfflineBearContentCatalog.load();
    widget.stageAdapter.onModelPlaced = widget.sessionController.onArStageReady;
    widget.stageAdapter.onPlacementChanged = (placed) {
      if (mounted) setState(() => _hasPlacedModel = placed);
    };
    widget.stageAdapter.onModelTapped = () => unawaited(
      widget.sessionController.triggerManualAnimation(
        UkumariAnimation.surprise,
      ),
    );
    widget.stageAdapter.onStatus = (message) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    };
    _bootstrapExperience();
  }

  Future<void> _bootstrapExperience() async {
    await widget.sessionController.initialize();
    if (!mounted) return;
    final granted = await _requestCameraPermission();
    if (!mounted) return;
    WebViewController? audioController;
    var arCoreStatus = 'unavailable';
    if (granted) {
      audioController = await widget.stageAdapter.initializeAudioStage();
      arCoreStatus = await widget.stageAdapter.ensureArCoreInstalled();
    }
    if (mounted) {
      setState(() {
        _cameraPermissionGranted = granted;
        _arCoreStatus = arCoreStatus;
        _arCoreReady = arCoreStatus == 'installed';
        _audioWebViewController = audioController;
      });
    }
  }

  Future<void> _exitExperience() async {
    await widget.sessionController.cancelOfflinePoint();
    if (mounted) widget.onExit();
  }

  Future<bool> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> _enableAr() async {
    final granted = await _requestCameraPermission();
    if (!granted) return;
    final audioController = await widget.stageAdapter.initializeAudioStage();
    final arCoreStatus = await widget.stageAdapter.ensureArCoreInstalled();
    if (mounted) {
      setState(() {
        _cameraPermissionGranted = true;
        _arCoreStatus = arCoreStatus;
        _arCoreReady = arCoreStatus == 'installed';
        _audioWebViewController = audioController;
      });
    }
  }

  Future<void> _retryArCoreSetup() async {
    if (_arCoreCheckInFlight || !mounted) return;
    _arCoreCheckInFlight = true;
    setState(() => _arCoreStatus = 'checking');
    final status = await widget.stageAdapter.ensureArCoreInstalled();
    if (mounted) {
      setState(() {
        _arCoreStatus = status;
        _arCoreReady = status == 'installed';
        _planeDetected = false;
      });
    }
    _arCoreCheckInFlight = false;
  }

  Widget _buildArCoreMessage() {
    final isUnsupported = _arCoreStatus == 'unsupported';
    final isInstalling = _arCoreStatus == 'install_requested';
    final message = switch (_arCoreStatus) {
      'unsupported' => 'Este teléfono no es compatible con ARCore. Usa otro dispositivo compatible para ver a Ukumari en realidad aumentada.',
      'install_requested' => 'Completa la instalación de Google Play Services for AR y vuelve a Biodiversidad.',
      'declined' => 'Se canceló la instalación de Google Play Services for AR. Puedes intentarlo otra vez.',
      'checking' =>
        'Comprobando si este teléfono puede iniciar la realidad aumentada…',
      _ => 'No se pudo iniciar ARCore. Revisa la conexión y que Google Play Services esté actualizado.',
    };

    return ColoredBox(
      color: brandDarkGreen,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUnsupported ? Icons.phone_android_rounded : Icons.view_in_ar,
                color: brandCream,
                size: 46,
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: brandCream,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              if (!isUnsupported && !isInstalling) ...[
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _arCoreCheckInFlight ? null : _retryArCoreSetup,
                  child: const Text('Reintentar AR'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openQrScanner() async {
    if (_isScanningQr) return;
    await widget.sessionController.cancelOfflinePoint();
    await widget.stageAdapter.resetPlacement();
    if (!mounted) return;
    setState(() {
      _isScanningQr = true;
      _planeDetected = false;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_isScanningQr) return;
    try {
      await _qrScanner.start();
    } catch (_) {
      await _closeQrScanner();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el lector QR.')),
        );
      }
    }
  }

  Future<void> _closeQrScanner() async {
    if (!_isScanningQr) return;
    await _qrScanner.stop();
    if (mounted) setState(() => _isScanningQr = false);
  }

  Future<void> _handleQrCapture(BarcodeCapture capture) async {
    if (_qrBusy || !_isScanningQr) return;
    final payload = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .where((value) => value.startsWith('BIOINNOVA:'))
        .firstOrNull;
    if (payload == null) return;
    _qrBusy = true;
    try {
      final catalog = await _offlineCatalog;
      final point = catalog.pointForQr(payload);
      if (point == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este QR no está en la ruta del oso.'),
            ),
          );
        }
        return;
      }
      await _closeQrScanner();
      if (!mounted) return;
      if (!catalog.isValidated(point)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este punto aún está en validación.')),
        );
        return;
      }
      final quiz = await widget.sessionController.playOfflinePoint(point);
      if (mounted && quiz != null) _showOfflineQuiz(quiz);
    } finally {
      _qrBusy = false;
    }
  }

  void _showOfflineQuiz(OfflineQuiz quiz) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: brandCream,
        title: const Text('Pregunta de la ruta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(quiz.question),
            const SizedBox(height: 12),
            for (var index = 0; index < quiz.options.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    unawaited(
                      widget.sessionController.answerOfflineQuiz(quiz, index),
                    );
                  },
                  child: Text(quiz.options[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPermissionMessage() {
    return ColoredBox(
      color: brandDarkGreen,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                color: brandCream,
                size: 46,
              ),
              const SizedBox(height: 14),
              const Text(
                'Ukumari necesita la cámara para buscar el piso y quedarse anclado en el lugar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: brandCream, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _enableAr,
                child: const Text('Activar cámara AR'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacementHint() {
    if (_hasPlacedModel) return const SizedBox.shrink();
    final message = !_planeDetected
        ? 'Toca la pantalla para que Ukumari aparezca frente a ti.'
        : '¡Listo! Toca la pantalla y Ukumari aparecerá.';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: brandDarkGreen.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandCream.withValues(alpha: 0.36)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: brandCream,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }

  void _openRouteMapDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: brandCream,
        insetPadding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: brandGreen, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.map_rounded, color: brandGreen),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Mapa · Ruta Biodiversidad UNSM',
                      style: TextStyle(
                        color: brandDarkGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: brandDarkGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.asset(
                    'assets/images/mapa_ruta_biodiversidad.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pellizca la imagen para hacer zoom en la Zona A y Zona B.',
                style: TextStyle(
                  color: brandGreen,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _cameraPermissionGranted &&
        !_arCoreReady) {
      _retryArCoreSetup();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _qrScanner.dispose();
    widget.stageAdapter.dispose();
    widget.sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.sessionController,
      builder: (context, _) {
        final session = widget.sessionController;

        return Scaffold(
          backgroundColor: brandDarkGreen,
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (_isScanningQr)
                MobileScanner(
                  controller: _qrScanner,
                  onDetect: _handleQrCapture,
                )
              else if (!_cameraPermissionGranted)
                _buildCameraPermissionMessage()
              else if (!_arCoreReady)
                _buildArCoreMessage()
              else
                ARView(
                  onARViewCreated: (session, objects, anchors, _) => widget
                      .stageAdapter
                      .onArViewCreated(session, objects, anchors),
                  planeDetectionConfig: PlaneDetectionConfig.horizontal,
                  permissionPromptDescription: 'Necesitamos la cámara para colocar a Ukumari en tu espacio.',
                  permissionPromptButtonText: 'Permitir cámara',
                ),

              if (_audioWebViewController case final audioController?)
                Positioned(
                  left: 0,
                  top: 0,
                  width: 1,
                  height: 1,
                  child: Opacity(
                    opacity: 0,
                    child: IgnorePointer(
                      child: WebViewWidget(controller: audioController),
                    ),
                  ),
                ),

              // Layer 3: Minimal Branded Top Bar + Bottom Clickable Questions
              if (!_capturingPhoto)
                SafeArea(
                  child: Column(
                    children: [
                      _buildBrandedTopBar(session),
                      Expanded(
                        child: _isScanningQr
                            ? const Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'Apunta al QR de la ruta',
                                    style: TextStyle(
                                      color: brandCream,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: IgnorePointer(
                                  child: _buildPlacementHint(),
                                ),
                              ),
                      ),
                      if (_isScanningQr)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: FilledButton.icon(
                            onPressed: _closeQrScanner,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Volver a Ukumari'),
                          ),
                        )
                      else
                        GuideSpeechBubble(
                          initialCollapsed: _hasPlacedModel,
                          subtitleText: session.subtitleText,
                          phase: session.phase,
                          questions: session.followUpSuggestions,
                          onQuestionTapped: session.submitQuestion,
                          onReplayScene: session.replayTourScene,
                          onNextScene: session.nextTourScene,
                          sceneTitle: session.tourSceneTitle,
                          isLastScene: session.isLastTourScene,
                          onOpenMapModal: _openRouteMapDialog,
                          onReanchorAr: _hasPlacedModel
                              ? session.reanchorCharacterInAr
                              : null,
                        ),
                    ],
                  ),
                ),
              if (_photoBytes case final photo?)
                Positioned.fill(
                  child: _BearPhotoPreview(
                    bytes: photo,
                    controller: widget.stageAdapter,
                    onClose: () => setState(() => _photoBytes = null),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrandedTopBar(GuideSessionController session) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: brandCream.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: brandGreen, width: 1.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
              tooltip: 'Volver a bienvenida',
              onPressed: _exitExperience,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: brandGreen,
                size: 21,
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo_biodiversidad_unsm.png',
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // View Route Map
            if (!_isScanningQr)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Tomar foto con Ukumari',
                onPressed: _capturingPhoto ? null : _takePhoto,
                icon: const Icon(
                  Icons.photo_camera_outlined,
                  color: brandGreen,
                  size: 21,
                ),
              ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: _isScanningQr ? 'Cerrar lector QR' : 'Escanear QR',
              onPressed: _isScanningQr ? _closeQrScanner : _openQrScanner,
              icon: Icon(
                _isScanningQr ? Icons.close_rounded : Icons.qr_code_scanner,
                color: brandGreen,
                size: 21,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Ver Mapa de la Ruta',
              onPressed: _openRouteMapDialog,
              icon: const Icon(Icons.map_outlined, color: brandGreen, size: 21),
            ),
            // Remove and place Ukumari again at a newly detected floor point.
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Volver a colocar a Ukumari',
              onPressed: session.resetArPlacement,
              icon: const Icon(
                Icons.center_focus_strong_outlined,
                color: brandGreen,
                size: 21,
              ),
            ),
            // Toggle Voice Mute
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: session.isVoiceMuted ? 'Activar voz' : 'Silenciar voz',
              onPressed: session.toggleMuteVoice,
              icon: Icon(
                session.isVoiceMuted
                    ? Icons.volume_off_outlined
                    : Icons.volume_up_outlined,
                color: brandGreen,
                size: 21,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
