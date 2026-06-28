// CREATE SESSION SHEET — Extracted from study_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateSessionSheet extends StatefulWidget {
  final Function(String, List<String>, DateTime, DateTime?) onSubmit;
  const CreateSessionSheet({super.key, required this.onSubmit});

  @override
  State<CreateSessionSheet> createState() => _CreateSessionSheetState();
}

class _CreateSessionSheetState extends State<CreateSessionSheet> {
  final _subjectController = TextEditingController();
  final List<TextEditingController> _topicControllers = [
    TextEditingController()
  ];
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  bool _hasExam = false;
  DateTime? _selectedExamDate;

  void _addTopicField() =>
      setState(() => _topicControllers.add(TextEditingController()));

  void _removeTopicField(int index) {
    if (_topicControllers.length > 1) {
      setState(() {
        _topicControllers[index].dispose();
        _topicControllers.removeAt(index);
      });
    }
  }

  Future<void> _pickStartDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: _startTime);
    if (time == null) return;
    setState(() {
      _startDate = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
      _startTime = time;
    });
  }

  Future<void> _pickExamDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedExamDate = picked);
  }

  void _submit() {
    final subject = _subjectController.text.trim();
    final topics = _topicControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject name.')),
      );
      return;
    }
    if (_hasExam && _selectedExamDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an exam date.')),
      );
      return;
    }
    Navigator.pop(context);
    widget.onSubmit(
        subject, topics, _startDate, _hasExam ? _selectedExamDate : null);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    for (var c in _topicControllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1C1F2A) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF252840) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D3142);
    final labelColor = isDark ? Colors.white54 : Colors.black54;
    final borderColor = isDark ? const Color(0xFF3A3F5C) : Colors.grey.shade200;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('New Study Plan',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textColor)),
              const SizedBox(height: 4),
              Text('AI will build your personalised syllabus.',
                  style: TextStyle(fontSize: 13, color: labelColor)),
              const SizedBox(height: 24),

              // Subject Name
              Text('Subject Name *',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: labelColor)),
              const SizedBox(height: 8),
              TextField(
                controller: _subjectController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'e.g., System Architecture',
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFF334195), width: 2)),
                ),
              ),
              const SizedBox(height: 20),

              // Topics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Topics to Cover',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: labelColor)),
                  TextButton.icon(
                    onPressed: _addTopicField,
                    icon: const Icon(Icons.add_circle_outline, size: 15),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF334195)),
                  ),
                ],
              ),
              // AI hint
              Container(
                margin: const EdgeInsets.only(bottom: 12, top: 2),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: isDark ? 0.15 : 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 15,
                        color: isDark
                            ? Colors.purple.shade200
                            : Colors.purple.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Leave blank to let AI auto-generate a full syllabus.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.purple.shade200
                              : Colors.purple.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...List.generate(
                _topicControllers.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _topicControllers[i],
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Optional topic…',
                            filled: true,
                            fillColor: cardBg,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor)),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_topicControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.redAccent, size: 20),
                          onPressed: () => _removeTopicField(i),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Schedule & Exam pickers
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    // Start date/time
                    InkWell(
                      onTap: _pickStartDateTime,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                color: Color(0xFF334195), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Schedule Session',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor)),
                            ),
                            Text(
                              "${DateFormat('MMM dd').format(_startDate)} at ${_startTime.format(context)}",
                              style: const TextStyle(
                                  color: Color(0xFF334195),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Colors.grey, size: 18),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1, color: borderColor),
                    // Exam toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded,
                              color: Color(0xFF334195), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Is this for an exam?',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                          ),
                          Switch(
                            value: _hasExam,
                            activeThumbColor: const Color(0xFF334195),
                            onChanged: (val) {
                              setState(() {
                                _hasExam = val;
                                if (!val) _selectedExamDate = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_hasExam) ...[
                      Divider(height: 1, color: borderColor),
                      InkWell(
                        onTap: _pickExamDate,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedExamDate == null
                                      ? 'Select Exam Date'
                                      : 'Target: ${DateFormat('MMM dd, yyyy').format(_selectedExamDate!)}',
                                  style: TextStyle(
                                    color: _selectedExamDate == null
                                        ? Colors.grey
                                        : const Color(0xFF334195),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.grey, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF334195),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _submit,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Generate AI Study Plan',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
