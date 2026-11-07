import 'dart:async';
import 'dart:typed_data';

import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:webview_flutter/webview_flutter.dart';

import '../../domain/entities/ukumari_animation.dart';
import '../../domain/ports/ar_stage_port.dart';
import 'webview_ar_stage_adapter.dart';

/// Uses the same native AR renderer and movement as the BioInnova tigrillo.
class SceneViewArStageAdapter implements ArStagePort {
  SceneViewArStageAdapter({WebViewArStageAdapter? audioAdapter})
    : _audioAdapter = audioAdapter ?? WebViewArStageAdapter();

  static const modelAssetPath = 'assets/models/Ukumari_Meshy_Mixamo_v3.glb';

  final WebViewArStageAdapter _audioAdapter;
  ARSessionManager? _session;
  ARObjectManager? _objects;
  ARAnchorManager? _anchors;
  ARNode? _bear;
  ARPlaneAnchor? _anchor;
  bool _placing = false;
  double _characterScale = 0.5;

  bool get hasPlacedModel => _bear != null;
  bool get isAttached => _session != null;
  WebViewController? get audioWebViewController =>
      _audioAdapter.webViewController;

  void Function()? onModelPlaced;
  void Function(bool placed)? onPlacementChanged;
  void Function()? onModelTapped;
  void Function(String message)? onStatus;

  Future<WebViewController> initializeAudioStage() =>
      _audioAdapter.initializeAudioStage();

  // The native AR view requests Google Play Services for AR when it starts.
  Future<String> ensureArCoreInstalled() async => 'installed';

  void onArViewCreated(
    ARSessionManager session,
    ARObjectManager objects,
    ARAnchorManager anchors,
  ) {
    _session = session;
    _objects = objects;
    _anchors = anchors;
    session.onInitialize(
      showFeaturePoints: false,
      showPlanes: false,
      showWorldOrigin: false,
      handleTaps: true,
      handlePans: false,
      handleRotation: false,
    );
    objects.onInitialize();
    session.onPlaneOrPointTap = (hits) => unawaited(onSurfaceTapped(hits));
    objects.onNodeTap = (names) {
      if (names.contains(_bear?.name)) onModelTapped?.call();
    };
  }

  Future<void> onSurfaceTapped(List<ARHitTestResult> hits) async {
    if (_placing) return;
    final hit = hits
        .where(
          (item) =>
              item.type == ARHitTestResultType.plane ||
              item.type == ARHitTestResultType.instant,
        )
        .firstOrNull;
    final bear = _bear;
    final objects = _objects;
    if (bear != null && objects != null) {
      final moved = hit == null
          ? await objects.callTowardCamera(bear)
          : await objects.moveTo(bear, hit.worldTransform);
      if (moved != true && hit != null) await objects.callTowardCamera(bear);
      return;
    }
    if (hit == null) {
      onStatus?.call('Apunta a una zona libre y toca la pantalla.');
      return;
    }
    final anchors = _anchors;
    if (anchors == null || objects == null) return;
    _placing = true;
    try {
      final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
      if (await anchors.addAnchor(anchor) != true) {
        onStatus?.call('Mueve el teléfono lentamente y vuelve a tocar.');
        return;
      }
      final node = ARNode(
        type: NodeType.assetGLB,
        uri: modelAssetPath,
        name: 'ukumari',
        scale: vm.Vector3.all(_characterScale),
        position: vm.Vector3.zero(),
        rotation: vm.Vector4(0, 1, 0, 0),
      );
      if (await objects.addNode(node, planeAnchor: anchor) != true) {
        await anchors.removeAnchor(anchor);
        onStatus?.call('No se pudo cargar a Ukumari. Toca de nuevo.');
        return;
      }
      _anchor = anchor;
      _bear = node;
      await objects.getAnimations(node);
      await objects.setRoamingEnabled(node, false);
      onPlacementChanged?.call(true);
      await Future<void>.delayed(const Duration(milliseconds: 950));
      if (_bear != node) return;
      onModelPlaced?.call();
    } finally {
      _placing = false;
    }
  }

  Future<Uint8List> capturePhoto() async =>
      (await _session?.captureFramedPhoto()) ??
      (throw StateError('La cámara AR aún no está lista'));

  Future<String> savePhoto(Uint8List bytes) async =>
      (await _session?.savePhoto(bytes)) ??
      (throw StateError('La cámara AR aún no está lista'));

  Future<void> sharePhoto(String uri) async => _session?.sharePhoto(uri);

  @override
  Future<void> playAnimation(
    UkumariAnimation animation, {
    bool? loopOverride,
  }) async {
    final bear = _bear;
    if (bear == null) return;
    await _objects?.playAnimation(
      bear,
      animation.clipName,
      loop: loopOverride ?? animation.loopsByDefault,
    );
  }

  @override
  Future<void> setLipSyncAmplitude(double amplitude) async {}

  @override
  Future<bool> playNeuralAudioTrack(String trackKey) =>
      _audioAdapter.playNeuralAudioTrack(trackKey);

  @override
  Future<void> stopNeuralAudioTrack() => _audioAdapter.stopNeuralAudioTrack();

  @override
  Future<void> setCharacterScale(double scale) async {
    _characterScale = scale.clamp(0.3, 1.25);
    _bear?.scale = vm.Vector3.all(_characterScale);
  }

  @override
  Future<void> resetPlacement() async {
    final bear = _bear;
    final anchor = _anchor;
    if (bear != null) await _objects?.removeNode(bear);
    if (anchor != null) await _anchors?.removeAnchor(anchor);
    _bear = null;
    _anchor = null;
    _characterScale = 0.5;
    onPlacementChanged?.call(false);
  }

  @override
  Future<void> reanchorCharacterToView() async {
    final bear = _bear;
    if (bear != null) await _objects?.callTowardCamera(bear);
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

  void dispose() {
    _audioAdapter.dispose();
    unawaited(_session?.dispose());
    _session = null;
  }
}
