# Ukumari AR — Interactive Biodiversity Guide (`ukumari_ar_app`)

Production-grade Flutter Augmented Reality mobile application featuring **Ukumari**, the Andean Spectacled Bear (*Tremarctos ornatus*). Built with **Clean / Hexagonal / Screaming Architecture** and the **Container-Presentational Pattern**.

---

## Architecture Overview

```text
lib/
├── main.dart                                      # Hexagonal Composition Root (Dependency Injection)
└── src/
    └── features/
        └── ar_guide/                              # Screaming Architecture feature slice
            ├── domain/
            │   ├── entities/
            │   │   ├── ukumari_animation.dart     # 7 GLB clips (01_Reposo .. 07_Curioso)
            │   │   ├── biodiversity_topic.dart    # 6 interactive Andean biodiversity topics
            │   │   └── guide_response.dart        # Immutable advisor response value object
            │   └── ports/
            │       ├── ar_stage_port.dart         # Output port for 3D WebGL stage
            │       ├── biodiversity_advisor_port.dart # Output port for Q&A and topic explanations
            │       └── speech_port.dart           # Output port for TTS + 30Hz lip-sync + STT
            ├── application/
            │   └── guide_session_controller.dart  # State machine coordinating voice, lip-sync & gestures
            ├── infrastructure/
            │   └── adapters/
            │       ├── hybrid_biodiversity_advisor.dart # Gemini 2.5 Flash REST + offline Spanish engine
            │       ├── flutter_speech_adapter.dart      # flutter_tts + speech_to_text + Boca_abierta envelope
            │       └── webview_ar_stage_adapter.dart    # Chunked Base64 GLB loader & JS bridge
            └── presentation/
                ├── containers/
                │   └── ar_guide_screen_container.dart   # Smart container (Camera, Permissions, Lifecycle)
                └── widgets/
                    ├── ar_camera_background.dart        # Live CameraPreview + Virtual Andean Forest fallback
                    ├── ukumari_ar_stage_view.dart       # Transparent Three.js WebGL stage
                    ├── topic_selector_bar.dart          # 6 Biodiversity topic chips
                    ├── guide_speech_bubble.dart         # Subtitle card + follow-up suggestion pills
                    ├── question_input_bar.dart          # Push-to-talk mic + text input bar
                    ├── animation_selector_sheet.dart    # Manual inspector for all 7 GLB animations
                    └── ai_config_dialog.dart            # Runtime Gemini API key configuration
```

---

## 3D Asset & Morph Target Contract (`Ukumari_AR_Produccion.glb`)

Located at `assets/models/Ukumari_AR_Produccion.glb`:

### Skeletal + Morph Animation Clips (24 FPS)
| Enum | Clip Name in `.glb` | Duration | Default Mode | Purpose |
|------|---------------------|----------|--------------|---------|
| `UkumariAnimation.idle` | `01_Reposo` | 5.0 s | Loop | Natural breathing, subtle weight shift, idle blink |
| `UkumariAnimation.wave` | `02_Saludo` | 6.0 s | One-shot | Friendly right-paw greeting |
| `UkumariAnimation.talk` | `03_Hablar` | 6.0 s | Loop | Explanatory arm gestures while speaking |
| `UkumariAnimation.nod` | `04_Asentir` | 4.0 s | One-shot | Attentive head nod confirming user questions |
| `UkumariAnimation.goodbye` | `05_Despedida` | 6.0 s | One-shot | Warm farewell wave |
| `UkumariAnimation.celebrate` | `06_Celebrar` | 5.0 s | One-shot | Joyful celebration of conservation & seed dispersal |
| `UkumariAnimation.curious` | `07_Curioso` | 5.0 s | Loop | Listening / thinking posture during voice & Q&A |

### Shape Keys (Morph Targets on `Ukumari_Mesh`)
- `Correccion_Saludo_D` & `Correccion_Saludo_I`: Corrective Pose Space Deformation (PSD) shape keys driven automatically by the `.glb` animation `weights` channel to keep shoulder/underarm topology clean during raised-arm gestures. Never overwritten by code.
- `Boca_abierta`: Modulated in real time after `mixer.update(dt)` by the 30Hz `lipSyncAmplitudeStream` while Ukumari speaks.
- `Parpadeo`: Driven by the animation clip tracks plus a procedural blink cycle every ~4.6 seconds.

---

## How to Run the Flutter Mobile App

1. Ensure the Flutter SDK (`>=3.2.0`) is installed and a physical Android or iOS device is connected.
2. Fetch packages and generate any missing platform scaffolding if needed:
   ```bash
   cd ukumari_ar_app
   flutter create . --platforms=android,ios
   flutter pub get
   ```
3. Run on your connected phone:
   ```bash
   flutter run
   ```
   *(Optional)* To pass a Gemini API key at build time:
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
   ```
   You can also configure or clear the API key at any time inside the app by tapping the ✨ icon in the top bar.
