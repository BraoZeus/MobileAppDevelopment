import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';
import '../services/ai_planner_service.dart';
import '../models/study_plan_model.dart';
import 'focus_screen.dart'; // <-- Added the import for the Focus Screen!

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAILoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateSessionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateSessionSheet(
        onSubmit: (subject, topics, examDate) {
          _processStudyPlanGeneration(subject, topics, examDate);
        },
      ),
    );
  }

  Future<void> _processStudyPlanGeneration(String subject, List<String> topics, DateTime? examDate) async {
    setState(() => _isAILoading = true);

    try {
      final plannerService = AIPlannerService();
      GeneratedStudyPlan generatedPlan;

      if (topics.isEmpty) {
        generatedPlan = await plannerService.generateAutoSyllabus(subject: subject, examDate: examDate);
      } else {
        generatedPlan = await plannerService.generateTargetedPlan(subject: subject, userTopics: topics, examDate: examDate);
      }

      List<StudyTopic> localTopics = generatedPlan.tasks.map((task) {
        return StudyTopic(
            title: '${task.taskName} - ${task.description}',
            durationMinutes: task.durationMinutes
        );
      }).toList();

      final newSubject = StudySubject(
        name: generatedPlan.topic.isNotEmpty ? generatedPlan.topic : subject,
        topics: localTopics,
        examDate: examDate,
        isExpanded: true,
      );

      if (mounted) {
        context.read<StudyProvider>().addSubject(newSubject);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(topics.isEmpty ? 'Auto-generated syllabus for "$subject"' : 'Targeted plan created for "$subject"'),
              backgroundColor: Colors.green.shade600
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Generation Error'),
            content: Text(e.toString()),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAILoading = false);
    }
  }

  void _editSubject(StudySubject subject) {
    TextEditingController controller = TextEditingController(text: subject.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Subject Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334195)),
            onPressed: () {
              context.read<StudyProvider>().updateSubjectName(subject.id, controller.text.trim());
              Navigator.pop(context);
              _showSuccess('Plan updated successfully');
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- UPDATED: Route to Focus Screen ---
  void _startFocusSession(StudySubject subject, StudyTopic topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FocusScreen(subject: subject, topic: topic),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studyProvider = context.watch<StudyProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F0FA), Color(0xFFF3E8FA), Color(0xFFE0F7FA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: _buildHeader(),
              ),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF334195),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF334195),
                tabs: const [Tab(text: 'Active Plans'), Tab(text: 'History')],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveTab(studyProvider),
                    _buildHistoryTab(studyProvider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTab(StudyProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isAILoading) ...[
            const Center(child: CircularProgressIndicator(color: Color(0xFF334195))),
            const SizedBox(height: 8),
            const Center(child: Text("AI is generating your syllabus...", style: TextStyle(color: Color(0xFF334195), fontWeight: FontWeight.bold))),
            const SizedBox(height: 24),
          ],
          if (provider.activeSubjects.isEmpty && !_isAILoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Tap + to create a session.', style: TextStyle(color: Colors.grey)))),
          ...provider.activeSubjects.map((subject) => _buildSubjectGlassCard(subject, provider)).toList(),
          const SizedBox(height: 32),
          _buildUpcomingExamsSection(provider.activeSubjects),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(StudyProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider.historySubjects.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Completed sessions will appear here.', style: TextStyle(color: Colors.grey)))),
          ...provider.historySubjects.map((subject) => _buildSubjectGlassCard(subject, provider, isHistory: true)).toList(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: const Padding(padding: EdgeInsets.all(8.0), child: CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'))),
      title: const Text('Study Well', style: TextStyle(color: Color(0xFF334195), fontWeight: FontWeight.w800, fontSize: 20)),
      centerTitle: true,
      actions: [IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF2D3142)), onPressed: () {})],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Study Planner', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
            TextButton.icon(
              onPressed: _isAILoading ? null : _openCreateSessionSheet,
              icon: const Icon(Icons.add, size: 18, color: Color(0xFF334195)),
              label: const Text('+ Create Session', style: TextStyle(color: Color(0xFF334195), fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 4),
        const Text('Organize your subjects and track readiness.', style: TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    );
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSubjectGlassCard(StudySubject subject, StudyProvider provider, {bool isHistory = false}) {
    int percentage = (subject.readiness * 100).toInt();
    Color readinessColor = isHistory ? Colors.grey : (percentage > 70 ? Colors.green : (percentage > 40 ? Colors.orange : Colors.red));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => setState(() => subject.isExpanded = !subject.isExpanded),
        child: _buildGlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: isHistory ? Colors.grey : const Color(0xFF334195), shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(subject.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isHistory ? Colors.grey.shade700 : const Color(0xFF2D3142)), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  Text('$percentage%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: readinessColor)),

                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    onSelected: (value) {
                      if (value == 'edit') _editSubject(subject);
                      if (value == 'delete') {
                        provider.deleteSubject(subject.id);
                        _showSuccess('Session deleted.');
                      }
                    },
                    itemBuilder: (context) => [
                      if (!isHistory) const PopupMenuItem(value: 'edit', child: Text('Edit Plan Name')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Session', style: TextStyle(color: Colors.red))),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(height: 6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(3))),
                  LayoutBuilder(
                    builder: (context, constraints) => Container(
                      height: 6,
                      width: constraints.maxWidth * subject.readiness,
                      decoration: BoxDecoration(color: readinessColor, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text('READINESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1)),
              ),
              if (subject.isExpanded) ...[
                const SizedBox(height: 16),
                ...subject.topics.map((topic) => _buildInteractiveTopicRow(subject, topic, provider, isHistory)).toList(),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveTopicRow(StudySubject subject, StudyTopic topic, StudyProvider provider, bool isHistory) {
    bool isDone = topic.status == TopicStatus.completed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: isDone,
            activeColor: Colors.green,
            shape: const CircleBorder(),
            onChanged: isHistory ? null : (val) => provider.toggleTopicStatus(subject, topic),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    topic.title,
                    style: TextStyle(
                      fontSize: 14,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone || isHistory ? Colors.grey : const Color(0xFF2D3142),
                    )
                ),
                Text('${topic.durationMinutes} mins allocated', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          if (!isDone && !isHistory)
            IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Color(0xFF334195), size: 30),
              onPressed: () => _startFocusSession(subject, topic), // <-- UPDATED to pass subject & topic!
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingExamsSection(List<StudySubject> activeSubjects) {
    final exams = activeSubjects.where((s) => s.examDate != null).toList();
    if (exams.isEmpty) return const SizedBox.shrink();

    exams.sort((a, b) => a.examDate!.compareTo(b.examDate!));

    return _buildGlassContainer(
      padding: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [Icon(Icons.event_note_rounded, color: Color(0xFF334195)), SizedBox(width: 8), Text('Upcoming Exams', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)))]),
            const SizedBox(height: 20),
            ...exams.map((exam) => _buildExamRow(exam)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExamRow(StudySubject exam) {
    final month = DateFormat('MMM').format(exam.examDate!).toUpperCase();
    final day = DateFormat('dd').format(exam.examDate!);
    final daysRemaining = exam.examDate!.difference(DateTime.now()).inDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF334195).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Text(month, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334195))),
              Text(day, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF334195)))
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exam.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.timer_outlined, size: 14, color: Colors.red.shade600),
                  const SizedBox(width: 4),
                  Text(daysRemaining <= 0 ? 'Due Today!' : '$daysRemaining days remaining', style: TextStyle(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.bold))
                ]),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ============================================================================
// --- CREATE SESSION SLIDING SHEET (POLISHED) ---
// ============================================================================
class CreateSessionSheet extends StatefulWidget {
  final Function(String subject, List<String> topics, DateTime? examDate) onSubmit;
  const CreateSessionSheet({super.key, required this.onSubmit});

  @override
  State<CreateSessionSheet> createState() => _CreateSessionSheetState();
}

class _CreateSessionSheetState extends State<CreateSessionSheet> {
  final TextEditingController _subjectController = TextEditingController();
  final List<TextEditingController> _topicControllers = [TextEditingController()];
  bool _hasExam = false;
  DateTime? _selectedDate;

  void _addTopicField() => setState(() => _topicControllers.add(TextEditingController()));

  void _removeTopicField(int index) {
    setState(() {
      if (_topicControllers.length > 1) {
        _topicControllers[index].dispose();
        _topicControllers.removeAt(index);
      }
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF334195), onPrimary: Colors.white, onSurface: Color(0xFF2D3142)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) setState(() => _selectedDate = picked);
  }

  void _submit() {
    String subject = _subjectController.text.trim();
    List<String> topics = _topicControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a subject name.')));
      return;
    }
    if (_hasExam && _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an exam date.')));
      return;
    }

    Navigator.pop(context);
    widget.onSubmit(subject, topics, _hasExam ? _selectedDate : null);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    for (var controller in _topicControllers) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuart,
      child: Container(
        decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),
              const Text('New Study Session', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2D3142))),
              const SizedBox(height: 24),

              // --- SUBJECT NAME ---
              const Text('Subject Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  hintText: 'e.g., System Architecture',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334195), width: 1.5)),
                ),
              ),
              const SizedBox(height: 24),

              // --- TOPICS SECTION ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Topics to Cover', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  TextButton.icon(
                    onPressed: _addTopicField,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Add Topic'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF334195), padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  )
                ],
              ),

              // --- UPGRADED AI HINT ---
              Container(
                margin: const EdgeInsets.only(bottom: 16.0, top: 4.0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade100)
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Colors.purple.shade400),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Leave topics blank to let AI auto-generate a full syllabus.', style: TextStyle(fontSize: 13, color: Colors.purple.shade700, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),

              ...List.generate(_topicControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _topicControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Optional: Enter specific topic',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334195))),
                          ),
                        ),
                      ),
                      if (_topicControllers.length > 1)
                        IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), onPressed: () => _removeTopicField(index)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // --- EXAM TOGGLE ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: const [Icon(Icons.calendar_month_rounded, color: Color(0xFF334195)), SizedBox(width: 12), Text('Is this for an exam?', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142)))]),
                        Switch(value: _hasExam, activeColor: const Color(0xFF334195), onChanged: (value) { setState(() => _hasExam = value); if (!value) _selectedDate = null; }),
                      ],
                    ),
                    if (_hasExam) ...[
                      const Divider(),
                      InkWell(
                        onTap: () => _pickDate(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_selectedDate == null ? 'Select Exam Date' : 'Target: ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}', style: TextStyle(color: _selectedDate == null ? Colors.grey : const Color(0xFF334195), fontWeight: FontWeight.bold)),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- UPGRADED SUBMIT BUTTON ---
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [Color(0xFF334195), Color(0xFF5B69BD)]),
                    boxShadow: [BoxShadow(color: const Color(0xFF334195).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  onPressed: _submit,
                  child: const Text('Generate AI Study Plan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}