/// Output port abstracting Text-to-Speech (TTS) narration with real-time
/// mouth amplitude envelopes (`Boca_abierta`) and Speech-to-Text (STT) input.
abstract interface class SpeechPort {
  /// Initializes TTS and STT engines.
  Future<void> initialize();

  /// Speaks [text] in Spanish and emits normalized jaw aperture values `[0.0, 1.0]`
  /// on [lipSyncAmplitudeStream] until narration finishes.
  Future<void> speak(String text);

  /// Immediately stops any ongoing TTS narration and resets mouth aperture to 0.
  Future<void> stopSpeaking();

  /// Stream of normalized mouth opening weights (`0.0` closed to `1.0` open)
  /// used to drive the `Boca_abierta` morph target on `Ukumari_Mesh`.
  Stream<double> get lipSyncAmplitudeStream;

  /// Whether the speech recognition engine is available on the current device.
  bool get isSpeechRecognitionAvailable;

  /// Starts listening to the user's microphone in Spanish and streams partial
  /// and final transcripts to [onTranscript].
  Future<bool> startListening({
    required void Function(String transcript, bool isFinal) onTranscript,
  });

  /// Stops an active microphone recognition session.
  Future<void> stopListening();

  /// Releases audio and recognition timers/resources.
  Future<void> dispose();
}
