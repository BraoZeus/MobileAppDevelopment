// EXPANDABLE TOPIC ROW — Extracted from study_screen.dart
import 'package:flutter/material.dart';
import '../models/study_plan_model.dart';
import '../providers/study_provider.dart';

class ExpandableTopicRow extends StatefulWidget {
  final StudySubject subject;
  final StudyTopic topic;
  final StudyProvider provider;
  final bool isHistory;
  final bool isDark;
  final VoidCallback onStartFocus;

  const ExpandableTopicRow({
    super.key,
    required this.subject,
    required this.topic,
    required this.provider,
    required this.isHistory,
    required this.isDark,
    required this.onStartFocus,
  });

  @override
  State<ExpandableTopicRow> createState() => _ExpandableTopicRowState();
}

class _ExpandableTopicRowState extends State<ExpandableTopicRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool isDone = widget.topic.status == TopicStatus.completed;
    final Color doneColor =
        widget.isDark ? Colors.green.shade400 : Colors.green;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _isExpanded
            ? (widget.isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.7))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: _isExpanded
            ? Border.all(
                color: widget.isDark ? Colors.white12 : Colors.grey.shade100)
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 4, vertical: _isExpanded ? 8 : 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Transform.scale(
                    scale: 0.9,
                    child: Checkbox(
                      value: isDone,
                      activeColor: doneColor,
                      shape: const CircleBorder(),
                      side: BorderSide(
                        color: widget.isDark
                            ? Colors.white24
                            : Colors.grey.shade300,
                      ),
                      onChanged: widget.isHistory
                          ? null
                          : (_) => widget.provider
                              .toggleTopicStatus(widget.subject, widget.topic),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.topic.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _isExpanded
                            ? FontWeight.bold
                            : FontWeight.normal,
                        decoration:
                            isDone ? TextDecoration.lineThrough : null,
                        color: isDone || widget.isHistory
                            ? (widget.isDark
                                ? Colors.white30
                                : Colors.grey.shade400)
                            : (widget.isDark
                                ? Colors.white
                                : const Color(0xFF2D3142)),
                      ),
                      maxLines: _isExpanded ? null : 1,
                      overflow: _isExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded,
                        color: widget.isDark
                            ? Colors.white24
                            : Colors.grey.shade400,
                        size: 18),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Padding(
                        padding:
                            const EdgeInsets.fromLTRB(48, 4, 8, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.topic.description != null &&
                                widget.topic.description!.isNotEmpty) ...[
                              Text(
                                widget.topic.description!,
                                style: TextStyle(
                                  color: widget.isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.timer_outlined,
                                        size: 13,
                                        color: widget.isDark
                                            ? Colors.white38
                                            : Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.topic.durationMinutes} min',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: widget.isDark
                                            ? Colors.white38
                                            : Colors.grey.shade500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!isDone && !widget.isHistory)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: widget.isDark
                                          ? const Color(0xFF4D5FD4)
                                          : const Color(0xFF334195),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 7),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      elevation: 0,
                                    ),
                                    onPressed: widget.onStartFocus,
                                    icon: const Icon(
                                        Icons.play_arrow_rounded,
                                        size: 16),
                                    label: const Text(
                                      'Focus',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
