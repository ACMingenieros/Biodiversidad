import 'package:flutter/material.dart';

/// Biodiversidad's branded entry point before camera permission and AR begin.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  static const _dark = Color(0xFF083D1C);
  static const _green = Color(0xFF0E632F);
  static const _cream = Color(0xFFEFECE1);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _dark,
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF176437), _dark, Color(0xFF052611)],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 44,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _cream,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Image.asset(
                        'assets/images/logo_biodiversidad_unsm.png',
                        width: 185,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: Container(
                      width: 248,
                      height: 248,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFF8FC792), _green, _dark],
                          stops: [0, .68, 1],
                        ),
                        border: Border.all(color: _cream, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 30),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/ukumari_preview.png',
                          fit: BoxFit.contain,
                          semanticLabel: 'Ukumari con vestimenta y plumas',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Conoce a Ukumari',
                    style: TextStyle(
                      color: _cream,
                      fontSize: 34,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tu guía de Biodiversidad UNSM te espera en realidad aumentada. Descubre la ruta, escucha sus historias y explora con él.',
                    style: TextStyle(color: _cream, fontSize: 15, height: 1.45),
                  ),
                  const SizedBox(height: 22),
                  const _Feature(
                    icon: Icons.view_in_ar_rounded,
                    text: 'Colócalo en un lugar de tu espacio',
                  ),
                  const SizedBox(height: 10),
                  const _Feature(
                    icon: Icons.record_voice_over_rounded,
                    text: 'Escucha y observa sus movimientos',
                  ),
                  const SizedBox(height: 10),
                  const _Feature(
                    icon: Icons.qr_code_scanner_rounded,
                    text: 'Escanea los QR de la ruta',
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text(
                        'Iniciar experiencia AR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _cream,
                        foregroundColor: _green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'La cámara se activa al iniciar la experiencia',
                      style: TextStyle(color: Color(0xFFC8D8CA), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: WelcomeScreen._cream, size: 19),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: WelcomeScreen._cream, fontSize: 13),
        ),
      ),
    ],
  );
}
