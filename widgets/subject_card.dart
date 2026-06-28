// SUBJECT CARD WIDGET — Extracted from study_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/study_plan_model.dart';
import '../providers/study_provider.dart';
import 'expandable_topic_row.dart';

class SubjectCard extends StatelessWidget {
  final StudySubject subject;
  final StudyProvider provider;
  final bool isDark;
  final bool isHistory;
  final void Function(StudySubject subject) onEdit;
  final void Function(String message, {bool isError}) onShowSnack;
  final void Function(StudySubject subject, StudyTopic topic) onStartFocus;
  final void Function(VoidCallback fn) onSetState;

  const SubjectCard({
    super.key,
    required this.subject,
    required this.provider,
    required this.isDark,
    this.isHistory = false,
    required this.onEdit,
    required this.onShowSnack,
    required this.onStartFocus,
    required this.onSetState,
  });

  @override
  Widget build(BuildContext context) {
    final int pct = (subject.readiness * 100).toInt();
    final Color readinessColor = isHistory
        ? Colors.grey
        : pct > 70
            ? Colors.green
            : pct > 40
                ? Colors.orange
                : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [// Card Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 8, 0),
                  child: Row(
                    children: [
                      // Status dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: readinessColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          subject.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF2D3142),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Percentage badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: readinessColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: readinessColor,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                            size: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        onSelected: (value) async {
                          if (value == 'edit') onEdit(subject);
                          if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: isDark ? const Color(0xFF1C1F2A) : Colors.white,
                                title: const Text('Delete Plan'),
                                content: const Text('Are you sure you want to delete this study plan? This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              provider.deleteSubject(subject.id);
                              onShowSnack('Plan deleted.');
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          if (!isHistory)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                Icon(Icons.edit_outlined, size: 16),
                                SizedBox(width: 10),
                                Text('Edit Name'),
                              ]),
                            ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  size: 16, color: Colors.red.shade400),
                              const SizedBox(width: 10),
                              Text('Delete Plan',
                                  style:
                                      TextStyle(color: Colors.red.shade400)),
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),// Progress bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: subject.readiness,
                          minHeight: 7,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.06),
                          valueColor:
                              AlwaysStoppedAnimation(readinessColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${subject.topics.where((t) => t.status == TopicStatus.completed).length}/${subject.topics.length} topics done',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade500,
                            ),
                          ),
                          Text(
                            'READINESS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),// Expand/Collapse toggle
                InkWell(
                  onTap: () =>
                      onSetState(() => subject.isExpanded = !subject.isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          subject.isExpanded
                              ? 'Hide Topics'
                              : 'Show ${subject.topics.length} Topics',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF8FA8F8)
                                : const Color(0xFF334195),
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: subject.isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            Icons.expand_more_rounded,
                            color: isDark
                                ? const Color(0xFF8FA8F8)
                                : const Color(0xFF334195),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),// Topics
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: subject.isExpanded
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            children: subject.topics
                                .map((t) => ExpandableTopicRow(
                                      subject: subject,
                                      topic: t,
                                      provider: provider,
                                      isHistory: isHistory,
                                      isDark: isDark,
                                      onStartFocus: () =>
                                          onStartFocus(subject, t),
                                    ))
                                .toList(),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
