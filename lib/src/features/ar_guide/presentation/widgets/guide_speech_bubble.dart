import 'package:flutter/material.dart';

import '../../application/guide_session_controller.dart';

/// Presentational compact card displaying Ukumari's spoken answer and the
/// official clickable questions using the BIODIVERSIDAD — UNSM brand palette
/// (`#0E632F` Forest Green and `#EFECE1` Warm Cream).
///
/// Supports collapsing into an ultra-compact floating pill (via downward swipe
/// or tap) so the user can enjoy a 100% unobstructed AR camera view of Ukumari.
class GuideSpeechBubble extends StatefulWidget {
  const GuideSpeechBubble({
    super.key,
    required this.subtitleText,
    required this.phase,
    required this.questions,
    required this.onQuestionTapped,
    required this.onReplayScene,
    required this.onNextScene,
    required this.sceneTitle,
    required this.isLastScene,
    required this.onOpenMapModal,
    this.onReanchorAr,
    this.initialCollapsed = false,
  });

  final String subtitleText;
  final GuideSessionPhase phase;
  final List<String> questions;
  final ValueChanged<String> onQuestionTapped;
  final VoidCallback onReplayScene;
  final VoidCallback onNextScene;
  final String sceneTitle;
  final bool isLastScene;
  final VoidCallback onOpenMapModal;
  final VoidCallback? onReanchorAr;
  final bool initialCollapsed;

  static const Color brandGreen = Color(0xFF0E632F);
  static const Color brandDarkGreen = Color(0xFF083D1C);
  static const Color brandCream = Color(0xFFEFECE1);
  static const Color brandCreamBorder = Color(0xFFD8D3C2);

  @override
  State<GuideSpeechBubble> createState() => _GuideSpeechBubbleState();
}

class _GuideSpeechBubbleState extends State<GuideSpeechBubble> {
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.initialCollapsed;
  }

  @override
  void didUpdateWidget(covariant GuideSpeechBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.initialCollapsed && widget.initialCollapsed) {
      _isCollapsed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSpeaking = widget.phase == GuideSessionPhase.speakingResponse;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity;
        if (velocity != null) {
          if (velocity > 250) {
            setState(() => _isCollapsed = true);
          } else if (velocity < -250) {
            setState(() => _isCollapsed = false);
          }
        }
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        child: _isCollapsed
            ? _buildCollapsedPill(isSpeaking)
            : _buildExpandedCard(isSpeaking),
      ),
    );
  }

  Widget _buildCollapsedPill(bool isSpeaking) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: GuideSpeechBubble.brandCream.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isSpeaking
              ? GuideSpeechBubble.brandGreen
              : GuideSpeechBubble.brandCreamBorder,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _isCollapsed = false),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: GuideSpeechBubble.brandGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.expand_less_rounded,
                  size: 15,
                  color: GuideSpeechBubble.brandCream,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '🐻 Preguntas · Toca o desliza para abrir',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: GuideSpeechBubble.brandDarkGreen,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (widget.onReanchorAr != null) ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  tooltip: '¡Ven aquí!',
                  icon: const Icon(
                    Icons.directions_walk_rounded,
                    size: 18,
                    color: GuideSpeechBubble.brandGreen,
                  ),
                  onPressed: widget.onReanchorAr,
                ),
                const SizedBox(width: 2),
              ],
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Repetir narración',
                icon: const Icon(
                  Icons.replay_rounded,
                  size: 18,
                  color: GuideSpeechBubble.brandGreen,
                ),
                onPressed: widget.onReplayScene,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedCard(bool isSpeaking) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
      decoration: BoxDecoration(
        color: GuideSpeechBubble.brandCream.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSpeaking
              ? GuideSpeechBubble.brandGreen
              : GuideSpeechBubble.brandCreamBorder,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle bar
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _isCollapsed = true),
              child: Container(
                width: 38,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: GuideSpeechBubble.brandGreen.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          // Header strip inside speech card (overflow-proof on all screen widths)
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: GuideSpeechBubble.brandGreen,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSpeaking
                              ? Icons.graphic_eq_rounded
                              : Icons.waving_hand_rounded,
                          size: 12,
                          color: GuideSpeechBubble.brandCream,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isSpeaking
                                ? 'Ukumari hablando...'
                                : 'Ukumari · Guía UNSM',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: GuideSpeechBubble.brandCream,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (widget.onReanchorAr != null) ...[
                Material(
                  color: GuideSpeechBubble.brandGreen,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: widget.onReanchorAr,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_walk_rounded,
                            size: 12,
                            color: GuideSpeechBubble.brandCream,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '📍 ¡Ven aquí!',
                            style: TextStyle(
                              color: GuideSpeechBubble.brandCream,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
              ],
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: widget.onReplayScene,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.replay_rounded,
                    size: 16,
                    color: GuideSpeechBubble.brandGreen,
                  ),
                ),
              ),
              const SizedBox(width: 1),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() => _isCollapsed = true),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: GuideSpeechBubble.brandGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Slim scrollable response text so it never crowds Ukumari in AR
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 64),
            child: SingleChildScrollView(
              child: Text(
                widget.subtitleText,
                style: const TextStyle(
                  color: GuideSpeechBubble.brandDarkGreen,
                  fontSize: 12.8,
                  height: 1.30,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Text(
                  widget.sceneTitle,
                  style: const TextStyle(
                    color: GuideSpeechBubble.brandDarkGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: widget.onNextScene,
                icon: Icon(
                  widget.isLastScene ? Icons.restart_alt : Icons.chevron_right,
                ),
                label: Text(widget.isLastScene ? 'Inicio' : 'Siguiente'),
                style: TextButton.styleFrom(
                  foregroundColor: GuideSpeechBubble.brandGreen,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),

          // Clickable Questions ONLY
          ...widget.questions.map((question) {
            final isLocationQuestion = question.toLowerCase().contains(
              'llegar',
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: GuideSpeechBubble.brandGreen,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => widget.onQuestionTapped(question),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLocationQuestion
                              ? Icons.location_on_rounded
                              : Icons.park_rounded,
                          color: GuideSpeechBubble.brandCream,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            question,
                            style: const TextStyle(
                              color: GuideSpeechBubble.brandCream,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.touch_app_rounded,
                          color: GuideSpeechBubble.brandCream,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
