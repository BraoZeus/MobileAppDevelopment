// STUDY SCREEN — Study buddy AppBar, real profile, improved layout
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/navigation_provider.dart';
import '../services/ai_planner_service.dart';
import '../models/study_plan_model.dart';
import '../utils/app_router.dart';
import '../widgets/subject_card.dart';
import '../widgets/create_session_sheet.dart';
import '../widgets/upcoming_exams_section.dart';
import '../widgets/profile_sheet.dart';
import 'focus_screen.dart';
import 'notification_screen.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAILoading = false;
  final GlobalKey _examsSectionKey = GlobalKey();
  final GlobalKey _readinessSectionKey = GlobalKey();

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
  // BOTTOM SHEETS & NAVIGATION
  void _openCreateSessionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateSessionSheet(
        onSubmit: (subject, topics, startDate, examDate) {
          _processStudyPlanGeneration(subject, topics, startDate, examDate);
        },
      ),
    );
  }

  void _showStudyBuddySheet() {
    showProfileSheet(context);
  }

  void _startFocusSession(StudySubject subject, StudyTopic topic) {
    Navigator.push(
      context,
      AppRouter.slide(FocusScreen(subject: subject, topic: topic)),
    );
  }
  // AI PLAN GENERATION
  Future<void> _processStudyPlanGeneration(
    String subject,
    List<String> topics,
    DateTime startDate,
    DateTime? examDate,
  ) async {
    setState(() => _isAILoading = true);
    try {
      final plannerService = AIPlannerService();
      final GeneratedStudyPlan generatedPlan = topics.isEmpty
          ? await plannerService.generateAutoSyllabus(
              subject: subject, examDate: examDate)
          : await plannerService.generateTargetedPlan(
              subject: subject,
              userTopics: topics,
              examDate: examDate);

      final localTopics = generatedPlan.tasks
          .map((t) => StudyTopic(
                title: t.taskName,
                description: t.description,
                durationMinutes: t.durationMinutes,
              ))
          .toList();

      final newSubject = StudySubject(
        name: generatedPlan.topic.isNotEmpty ? generatedPlan.topic : subject,
        topics: localTopics,
        startDate: startDate,
        examDate: examDate,
        isExpanded: true,
      );

      if (mounted) {
        context.read<StudyProvider>().addSubject(newSubject);
        _showSnack(topics.isEmpty
            ? 'Auto-generated syllabus for "$subject"'
            : 'Targeted plan created for "$subject"');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Generation Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'))
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAILoading = false);
    }
  }

  void _editSubject(StudySubject subject) {
    final controller = TextEditingController(text: subject.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Subject Name'),
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
              context
                  .read<StudyProvider>()
                  .updateSubjectName(subject.id, controller.text.trim());
              Navigator.pop(context);
              _showSnack('Plan updated successfully');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.redAccent : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  // BUILD
  @override
  Widget build(BuildContext context) {
    final studyProvider = context.watch<StudyProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final navProvider = context.watch<NavigationProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final shouldScrollToTop = navProvider.scrollToTop;
    final shouldScrollToExams = navProvider.scrollToExams;

    if (shouldScrollToExams || shouldScrollToTop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_tabController.index != 0) {
          _tabController.animateTo(0);
        }
        
        // Add a slight delay to allow the tab to mount if we just switched to it.
        Future.delayed(const Duration(milliseconds: 100), () {
          if (shouldScrollToTop && _readinessSectionKey.currentContext != null) {
            Scrollable.ensureVisible(
              _readinessSectionKey.currentContext!,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
            );
          } else if (shouldScrollToExams && _examsSectionKey.currentContext != null) {
            Scrollable.ensureVisible(
              _examsSectionKey.currentContext!,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
            );
          }
        });
      });
      if (navProvider.scrollToExams) navProvider.consumeScrollToExams();
      if (navProvider.scrollToTop) navProvider.consumeScrollToTop();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: InkWell(
            onTap: _showStudyBuddySheet,
            customBorder: const CircleBorder(),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                profileProvider.profile.avatarEmoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
        ),
        title: Text('Study Well',
            style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded,
                color: theme.appBarTheme.iconTheme?.color),
            onPressed: () {
               showDialog(
                 context: context,
                 builder: (_) => const NotificationDropdown(),
               );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF111318),
                    Color(0xFF1A1D2E),
                    Color(0xFF111827),
                  ]
                : const [
                    Color(0xFFE8F0FA),
                    Color(0xFFF3E8FA),
                    Color(0xFFE0F7FA),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [// Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Study Planner',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF2D3142),
                          ),
                        ),
                        Text(
                          'Track subjects & build readiness',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    // Create plan FAB-style button
                    AnimatedOpacity(
                      opacity: _isAILoading ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Material(
                        color: isDark
                            ? const Color(0xFF4D5FD4)
                            : const Color(0xFF334195),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap:
                              _isAILoading ? null : _openCreateSessionSheet,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.add_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'New Plan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),// Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: isDark
                      ? const Color(0xFF8FA8F8)
                      : const Color(0xFF334195),
                  unselectedLabelColor:
                      isDark ? Colors.white38 : Colors.grey,
                  indicator: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF252840)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Active Plans'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
              const SizedBox(height: 8),// Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveTab(studyProvider, isDark),
                    _buildHistoryTab(studyProvider, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // TAB CONTENT
  Widget _buildActiveTab(StudyProvider provider, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        key: _readinessSectionKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Loading card
          if (_isAILoading)
            _buildAILoadingCard(isDark),

          // Empty state
          if (provider.activeSubjects.isEmpty && !_isAILoading)
            _buildEmptyState(isDark),

          // Subject cards
          ...provider.activeSubjects.map(
              (s) => SubjectCard(
                    subject: s,
                    provider: provider,
                    isDark: isDark,
                    onEdit: _editSubject,
                    onShowSnack: _showSnack,
                    onStartFocus: _startFocusSession,
                    onSetState: setState,
                  )),

          // Upcoming exams
          if (provider.activeSubjects.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              key: _examsSectionKey,
              child: UpcomingExamsSection(
                activeSubjects: provider.activeSubjects,
                isDark: isDark,
                provider: provider,
                onShowSnack: _showSnack,
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(StudyProvider provider, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider.historySubjects.isEmpty)
            _buildEmptyState(isDark,
                message: 'Completed plans will appear here.',
                icon: Icons.history_rounded),
          ...provider.historySubjects.map(
              (s) => SubjectCard(
                    subject: s,
                    provider: provider,
                    isDark: isDark,
                    isHistory: true,
                    onEdit: _editSubject,
                    onShowSnack: _showSnack,
                    onStartFocus: _startFocusSession,
                    onSetState: setState,
                  )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  // CARDS & WIDGETS
  Widget _buildAILoadingCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF252840), const Color(0xFF1E2550)]
              : [const Color(0xFFEEF2FF), const Color(0xFFE8EDFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334195).withValues(alpha: 0.4)
              : const Color(0xFF334195).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                color: Color(0xFF334195), strokeWidth: 2.5),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generating AI Study Plan…',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFF8FA8F8)
                      : const Color(0xFF334195),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'This may take a few seconds',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark,
      {String message = 'Tap "New Plan" to create your first study plan.',
      IconData icon = Icons.menu_book_outlined}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(icon, size: 64,
                color: isDark ? Colors.white12 : Colors.grey.shade200),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade400,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// The SubjectCard, ExpandableTopicRow, and CreateSessionSheet widgets
// have been extracted to:
//   lib/widgets/subject_card.dart
//   lib/widgets/expandable_topic_row.dart
//   lib/widgets/create_session_sheet.dart
// EOF
