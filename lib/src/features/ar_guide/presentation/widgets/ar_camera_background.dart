import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Presentational widget that renders either the live device camera feed
/// for Augmented Reality or a clean BIODIVERSIDAD — UNSM forest backdrop.
class ArCameraBackground extends StatelessWidget {
  const ArCameraBackground({
    super.key,
    required this.cameraController,
    required this.isCameraEnabled,
  });

  final CameraController? cameraController;
  final bool isCameraEnabled;

  @override
  Widget build(BuildContext context) {
    final controller = cameraController;
    final hasLivePreview = isCameraEnabled &&
        controller != null &&
        controller.value.isInitialized;

    if (hasLivePreview) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? 1080,
            height: controller.value.previewSize?.width ?? 1920,
            child: CameraPreview(controller),
          ),
        ),
      );
    }

    // BIODIVERSIDAD — UNSM Forest Green backdrop when camera is off
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.25),
          radius: 1.15,
          colors: [
            Color(0xFF147A3B),
            Color(0xFF0E632F),
            Color(0xFF083D1C),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}
