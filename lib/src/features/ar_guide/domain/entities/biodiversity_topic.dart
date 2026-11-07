import 'package:flutter/material.dart';
import 'ukumari_animation.dart';

/// Immutable domain entity representing an official interactive question
/// presented by Ukumari for BIODIVERSIDAD — UNSM.
class BiodiversityTopic {
  const BiodiversityTopic({
    required this.id,
    required this.title,
    required this.shortLabel,
    required this.scientificContext,
    required this.narrationScript,
    required this.primaryAnimation,
    required this.followUpQuestions,
    required this.icon,
    this.audioAssetKey,
  });

  final String id;
  final String title;
  final String shortLabel;
  final String scientificContext;
  final String narrationScript;
  final UkumariAnimation primaryAnimation;
  final List<String> followUpQuestions;
  final IconData icon;
  final String? audioAssetKey;

  /// Official questions for the Ruta Biodiversidad — UNSM (Tarapoto, San Martín).
  static const List<BiodiversityTopic> defaultCatalog = [
    BiodiversityTopic(
      id: 'como_llegar',
      audioAssetKey: 'como_llegar',
      title: '¿Cómo llegar a la biodiversidad?',
      shortLabel: '¿Cómo llegar a la biodiversidad?',
      scientificContext: 'Km 17.3 Carretera Tarapoto–Yurimaguas · 960 m s. n. m.',
      narrationScript:
          '¡Llegar a la Ruta de Biodiversidad de la UNSM es muy fácil! Estamos en la región San Martín, Perú, código postal 22200, en el kilómetro 17.3 de la carretera Tarapoto–Yurimaguas, muy cerca de Tarapoto. Nos encontrarás a unos 960 metros de altura, en pleno bosque nublado de la Cordillera Escalera.',
      primaryAnimation: UkumariAnimation.wave,
      followUpQuestions: [
        '¿Cómo llegar a la biodiversidad?',
        '¿Qué hay en la biodiversidad?',
      ],
      icon: Icons.location_on_outlined,
    ),
    BiodiversityTopic(
      id: 'que_hay',
      audioAssetKey: 'que_hay',
      title: '¿Qué hay en la biodiversidad?',
      shortLabel: '¿Qué hay en la biodiversidad?',
      scientificContext: 'Ruta Biodiversidad UNSM · Zona A y Zona B',
      narrationScript:
          '¡En la Ruta Biodiversidad UNSM de Tarapoto tenemos dos grandes zonas llenas de vida! En la Zona A conocerás al cóndor amazónico, el recinto de loros, las tortugas motelos de patas rojas y los añujes hembras. En la Zona B verás al tigrillo, los monos machines negros, el paujil y la pucacunga, el picuro marrón, las motelos de patas amarillas y los añujes machos. ¡Y también tenemos piscina natural, senderos de caminata, zona de descanso, alojamiento y miradores para fotos!',
      primaryAnimation: UkumariAnimation.celebrate,
      followUpQuestions: [
        '¿Cómo llegar a la biodiversidad?',
        '¿Qué hay en la biodiversidad?',
      ],
      icon: Icons.park_outlined,
    ),
  ];
}
