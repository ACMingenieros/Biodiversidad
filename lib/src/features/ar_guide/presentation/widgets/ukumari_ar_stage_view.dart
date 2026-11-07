import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Presentational widget hosting the transparent Three.js WebGL stage
/// where `Ukumari_AR_Produccion.glb` is rendered over the camera feed.
class UkumariArStageView extends StatelessWidget {
  const UkumariArStageView({
    super.key,
    required this.webViewController,
    required this.isStageLoaded,
  });

  final WebViewController? webViewController;
  final bool isStageLoaded;

  @override
  Widget build(BuildContext context) {
    final controller = webViewController;
    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFEFECE1),
        ),
      );
    }

    return WebViewWidget(controller: controller);
  }
}
