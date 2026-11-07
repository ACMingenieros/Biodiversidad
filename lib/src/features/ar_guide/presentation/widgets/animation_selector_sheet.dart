import 'package:flutter/material.dart';
import '../../domain/entities/ukumari_animation.dart';

/// Presentational bottom sheet and compact pill strip for manually testing
/// all 7 skeletal and morph-target animations inside `Ukumari_AR_Produccion.glb`.
class AnimationSelectorSheet extends StatelessWidget {
  const AnimationSelectorSheet({
    super.key,
    required this.activeAnimation,
    required this.onSelectAnimation,
  });

  final UkumariAnimation activeAnimation;
  final ValueChanged<UkumariAnimation> onSelectAnimation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1D16),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.animation_outlined,
                color: Color(0xFF34D399),
                size: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  ' Animaciones 3D de Ukumari (.glb)',
                  style: TextStyle(
                    color: Color(0xFFECFDF5),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Selecciona un clip para inspeccionar el rig esquelético y las llaves de forma (Correccion_Saludo, Boca_abierta, Parpadeo).',
            style: TextStyle(
              color: Color(0xFFA7F3D0),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UkumariAnimation.values.map((anim) {
              final isSelected = anim == activeAnimation;
              return ActionChip(
                avatar: Icon(
                  anim.icon,
                  size: 17,
                  color: isSelected
                      ? const Color(0xFF052E16)
                      : const Color(0xFF34D399),
                ),
                backgroundColor: isSelected
                    ? const Color(0xFF34D399)
                    : const Color(0xFF173025),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF6EE7B7)
                      : Colors.white24,
                ),
                label: Text(
                  '${anim.clipName} · ${anim.displayLabel}',
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF052E16)
                        : const Color(0xFFECFDF5),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                onPressed: () {
                  onSelectAnimation(anim);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
