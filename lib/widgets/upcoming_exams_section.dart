// UPCOMING EXAMS SECTION
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/study_plan_model.dart';
import '../providers/study_provider.dart';

class UpcomingExamsSection extends StatelessWidget {
  final List<StudySubject> activeSubjects;
  final bool isDark;
  final StudyProvider provider;
  final void Function(String message, {bool isError}) onShowSnack;

  const UpcomingExamsSection({
    super.key,
    required this.activeSubjects,
    required this.isDark,
    required this.provider,
    required this.onShowSnack,
  });

  @override
  Widget build(BuildContext context) {
    final exams = activeSubjects.where((s) => s.examDate != null).toList()
      ..sort((a, b) => a.examDate!.compareTo(b.examDate!));
    if (exams.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
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
            children: [
              Row(
                children: [
                  Icon(Icons.event_note_rounded,
                      color: isDark
                          ? const Color(0xFF8FA8F8)
                          : const Color(0xFF334195),
                      size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming Exams',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...exams.map((exam) {
                final month = DateFormat('MMM').format(exam.examDate!).toUpperCase();
                final day = DateFormat('dd').format(exam.examDate!);
                final days = exam.examDate!.difference(DateTime.now()).inDays;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Date badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334195).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(month,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334195))),
                            Text(day,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF334195))),
                            Text(DateFormat('h:mm a').format(exam.examDate!),
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334195))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam.examName ?? exam.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF2D3142),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.timer_outlined,
                                    size: 13,
                                    color: Colors.red.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  days <= 0
                                      ? 'Today!'
                                      : '$days days remaining',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.red.shade400,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),// Actions menu
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                            size: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        onSelected: (value) async {
                          if (value == 'edit_date') {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: exam.examDate!,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2035),
                            );
                            if (picked == null || !context.mounted) return;
                            final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(exam.examDate!));
                            if (time == null) return;
                            
                            provider.updateExamDate(exam.id, DateTime(picked.year, picked.month, picked.day, time.hour, time.minute));
                            onShowSnack('Exam time updated.');
                          } else if (value == 'edit_name') {
                              final controller = TextEditingController(text: exam.examName ?? exam.name);
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Edit Exam Name'),
                                  content: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(hintText: 'Enter new name'),
                                    autofocus: true,
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () {
                                        provider.updateExamName(exam.id, controller.text.trim());
                                        Navigator.pop(context);
                                        onShowSnack('Exam name updated.');
                                      },
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              );
                          } else if (value == 'delete') {
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
                              provider.deleteSubject(exam.id);
                              onShowSnack('Plan deleted.');
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit_name',
                            child: Row(children: [
                              Icon(Icons.edit_outlined,
                                  size: 16,
                                  color: isDark
                                      ? const Color(0xFF8FA8F8)
                                      : const Color(0xFF334195)),
                              const SizedBox(width: 10),
                              const Text('Edit Name'),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'edit_date',
                            child: Row(children: [
                              Icon(Icons.edit_calendar_rounded,
                                  size: 16,
                                  color: isDark
                                      ? const Color(0xFF8FA8F8)
                                      : const Color(0xFF334195)),
                              const SizedBox(width: 10),
                              const Text('Edit Exam Date'),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red.shade400),
                              const SizedBox(width: 10),
                              Text('Delete Plan',
                                  style: TextStyle(
                                      color: Colors.red.shade400)),
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
