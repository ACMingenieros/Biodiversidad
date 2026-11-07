import 'package:flutter/material.dart';

/// Presentational modal dialog allowing the user to configure an optional
/// Gemini API key for open-ended cloud AI biodiversity responses.
class AiConfigDialog extends StatefulWidget {
  const AiConfigDialog({
    super.key,
    required this.hasExistingKey,
    required this.onSaveKey,
  });

  final bool hasExistingKey;
  final ValueChanged<String?> onSaveKey;

  @override
  State<AiConfigDialog> createState() => _AiConfigDialogState();
}

class _AiConfigDialogState extends State<AiConfigDialog> {
  final TextEditingController _keyController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0E2119),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF34D399), width: 0.8),
      ),
      title: const Row(
        children: [
          Icon(Icons.auto_awesome_outlined, color: Color(0xFF34D399)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Motor IA de Biodiversidad',
              style: TextStyle(
                color: Color(0xFFECFDF5),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ukumari incluye una base de conocimiento científica integrada que funciona sin conexión. Opcionalmente puedes ingresar una clave de Gemini API (gemini-2.5-flash) para respuestas generativas abiertas.',
            style: TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _keyController,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: widget.hasExistingKey
                  ? 'Clave activa (escribe otra para reemplazar)'
                  : 'AIzaSy...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF07120D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (widget.hasExistingKey)
          TextButton(
            onPressed: () {
              widget.onSaveKey(null);
              Navigator.of(context).pop();
            },
            child: const Text(
              'Usar modo local',
              style: TextStyle(color: Color(0xFFFBBF24)),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: const Color(0xFF052E16),
          ),
          onPressed: () {
            widget.onSaveKey(_keyController.text);
            Navigator.of(context).pop();
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
