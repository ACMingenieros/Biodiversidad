import 'package:flutter/material.dart';
import '../../domain/entities/biodiversity_topic.dart';

/// Presentational horizontal chip carousel allowing the user to trigger
/// any of the six curated Andean biodiversity topics.
class TopicSelectorBar extends StatelessWidget {
  const TopicSelectorBar({
    super.key,
    required this.topics,
    required this.selectedTopic,
    required this.onTopicSelected,
  });

  final List<BiodiversityTopic> topics;
  final BiodiversityTopic? selectedTopic;
  final ValueChanged<BiodiversityTopic> onTopicSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: topics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final topic = topics[index];
          final isSelected = selectedTopic?.id == topic.id;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onTopicSelected(topic),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : const Color(0xFF0E1F18).withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6EE7B7)
                        : Colors.white.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      topic.icon,
                      size: 16,
                      color: isSelected
                          ? const Color(0xFF052E16)
                          : const Color(0xFF6EE7B7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      topic.shortLabel,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF052E16)
                            : const Color(0xFFECFDF5),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
