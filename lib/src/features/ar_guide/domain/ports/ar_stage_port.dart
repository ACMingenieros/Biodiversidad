import '../entities/ukumari_animation.dart';

/// Output port abstracting the 3D AR WebGL renderer hosting `Ukumari_AR_Produccion.glb`.
abstract interface class ArStagePort {
  /// Crossfades smoothly to [animation] inside the 3D stage.
  Future<void> playAnimation(
    UkumariAnimation animation, {
    bool? loopOverride,
  });

  /// Sets the dynamic morph target weight for `Boca_abierta` (`0.0` to `1.0`)
  /// without overwriting corrective shape keys (`Correccion_Saludo_D` / `Correccion_Saludo_I`).
  Future<void> setLipSyncAmplitude(double amplitude);

  /// Plays a studio neural voice audio track (`saludo_inicial`, `como_llegar`, `que_hay`)
  /// inside the WebAudio stage with real-time waveform frequency lip-sync.
  /// Returns `true` if the neural track was played, or `false` to fall back to TTS.
  Future<bool> playNeuralAudioTrack(String trackKey) async => false;

  /// Stops any active neural voice audio track in the stage.
  Future<void> stopNeuralAudioTrack() async {}

  /// Adjusts Ukumari's scale multiplier on the AR floor plane.
  Future<void> setCharacterScale(double scale);

  /// Resets Ukumari's position, rotation, and scale to the center of the AR reticle.
  Future<void> resetPlacement();

  /// Moves Ukumari across the stage's virtual floor toward the current view.
  Future<void> reanchorCharacterToView() async {}

  /// Triggers a 3D floor raycast from screen coordinates [x], [y] on a viewport of [width] x [height],
  /// commanding Ukumari to turn and walk to the tapped floor position.
  Future<void> tapArScreen(double x, double y, double width, double height) async {}

  /// Toggles visibility of the AR ground placement ring.
  Future<void> setReticleVisible(bool visible);
}
