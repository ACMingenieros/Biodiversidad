import 'package:flutter/material.dart';
import '../../application/guide_session_controller.dart';

/// Presentational bottom input bar with microphone push-to-talk, free-form
/// question text field, and send button.
class QuestionInputBar extends StatefulWidget {
  const QuestionInputBar({
    super.key,
    required this.phase,
    required this.onSubmitted,
    required this.onMicPressed,
  });

  final GuideSessionPhase phase;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onMicPressed;

  @override
  State<QuestionInputBar> createState() => _QuestionInputBarState();
}

class _QuestionInputBarState extends State<QuestionInputBar> {
  final TextEditingController _textController = TextEditingController();

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    FocusScope.of(context).unfocus();
    widget.onSubmitted(text);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.phase == GuideSessionPhase.listeningUserVoice;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Row(
        children: [
          // Microphone button
          GestureDetector(
            onTap: widget.onMicPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
                boxShadow: [
                  BoxShadow(
                    color: (isListening
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981))
                        .withValues(alpha: 0.45),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Icon(
                isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
                color: const Color(0xFF052E16),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Question text input
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1913).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(
                        color: Color(0xFFECFDF5),
                        fontSize: 13.5,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: const InputDecoration(
                        hintText: 'Pregúntale a Ukumari sobre los Andes...',
                        hintStyle: TextStyle(
                          color: Color(0xFF6EE7B7),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _handleSend,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF34D399),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
