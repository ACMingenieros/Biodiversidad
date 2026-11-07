import 'package:flutter/material.dart';

/// Animations exported from the Mixamo-rigged Ukumari GLB.
enum UkumariAnimation {
  idle(
    clipName: '01_Reposo',
    displayLabel: 'Reposo',
    description: 'Respiración sutil de torso y cuello',
    durationSeconds: 2.0,
    loopsByDefault: true,
    icon: Icons.spa_outlined,
  ),
  wave(
    clipName: '02_Saludo',
    displayLabel: 'Saludo',
    description: 'Saluda con una mano',
    durationSeconds: 4.13,
    loopsByDefault: false,
    icon: Icons.waving_hand_outlined,
  ),
  talk(
    clipName: '03_Hablar',
    displayLabel: 'Hablar',
    description: 'Gesticula mientras conversa',
    durationSeconds: 5.2,
    loopsByDefault: true,
    icon: Icons.record_voice_over_outlined,
  ),
  nod(
    clipName: '04_Asentir',
    displayLabel: 'Gesto',
    description: 'Gesto corporal personalizado de Mixamo',
    durationSeconds: 2.03,
    loopsByDefault: false,
    icon: Icons.check_circle_outline,
  ),
  goodbye(
    clipName: '05_Despedida',
    displayLabel: 'Despedida',
    description: 'Saludo de despedida de una sola pasada',
    durationSeconds: 4.13,
    loopsByDefault: false,
    icon: Icons.front_hand_outlined,
  ),
  celebrate(
    clipName: '06_Celebrar',
    displayLabel: 'Celebrar',
    description: 'Da un salto de celebración',
    durationSeconds: 1.9,
    loopsByDefault: false,
    icon: Icons.celebration_outlined,
  ),
  curious(
    clipName: '07_Curioso',
    displayLabel: 'Curioso',
    description: 'Gesto corporal de atención',
    durationSeconds: 2.03,
    loopsByDefault: false,
    icon: Icons.psychology_alt_outlined,
  ),
  walk(
    clipName: '08_Caminar',
    displayLabel: 'Caminar',
    description: 'Caminata Mixamo en bucle',
    durationSeconds: 1.07,
    loopsByDefault: true,
    icon: Icons.directions_walk_outlined,
  ),
  run(
    clipName: '09_Correr',
    displayLabel: 'Correr',
    description: 'Carrera breve en bucle',
    durationSeconds: 0.67,
    loopsByDefault: true,
    icon: Icons.directions_run,
  ),
  sleep(
    clipName: '10_Dormir',
    displayLabel: 'Descansar',
    description: 'Se sienta y se queda dormido',
    durationSeconds: 17.33,
    loopsByDefault: false,
    icon: Icons.bedtime_outlined,
  ),
  surprise(
    clipName: '11_Sorpresa',
    displayLabel: 'Sorpresa',
    description: 'Salto expresivo con brazos y piernas abiertos',
    durationSeconds: 2.53,
    loopsByDefault: false,
    icon: Icons.auto_awesome,
  );

  const UkumariAnimation({
    required this.clipName,
    required this.displayLabel,
    required this.description,
    required this.durationSeconds,
    required this.loopsByDefault,
    required this.icon,
  });

  /// Exact animation clip name inside `Ukumari_Meshy_Mixamo_v3.glb`.
  final String clipName;
  final String displayLabel;
  final String description;
  final double durationSeconds;
  final bool loopsByDefault;
  final IconData icon;

  /// Resolves a [UkumariAnimation] from its GLB clip, enum name, or label.
  static UkumariAnimation fromClipOrName(String rawValue) {
    final normalized = rawValue.trim().toLowerCase();
    for (final anim in UkumariAnimation.values) {
      if (anim.clipName.toLowerCase() == normalized ||
          anim.name.toLowerCase() == normalized ||
          anim.displayLabel.toLowerCase() == normalized) {
        return anim;
      }
    }
    return UkumariAnimation.talk;
  }

  /// Maps the offline QR content cues to clips present in the bundled GLB.
  static UkumariAnimation fromContentCue(String cue) => switch (cue) {
    'saludar' => UkumariAnimation.wave,
    'explicar' => UkumariAnimation.talk,
    'sorprendido' => UkumariAnimation.surprise,
    'serio_amable' => UkumariAnimation.nod,
    'despedirse' => UkumariAnimation.goodbye,
    'celebrar' => UkumariAnimation.celebrate,
    'pensar' => UkumariAnimation.curious,
    _ => UkumariAnimation.talk,
  };
}
