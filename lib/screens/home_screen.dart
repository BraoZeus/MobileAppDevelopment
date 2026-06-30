import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/study_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/project_provider.dart';
import '../models/buddy_level_model.dart';
import '../services/api_services.dart';
import '../utils/app_router.dart';
import 'profile_screen.dart';
import 'preferences_screen.dart';
import 'gamification_screen.dart';
import 'notification_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {// Static session-level cache so the quote never re-fetches on tab switch
  static String? _cachedQuote;
  static DateTime? _cachedTime;

  String _quote = _cachedQuote ?? 'Loading inspiration...';
  DateTime _networkTime = _cachedTime ?? DateTime.now();
  bool _isLoadingApis = _cachedQuote == null; // already loaded → skip spinner
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _loadHomeApis();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Check for pending level-up after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLevelUp());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeApis() async {
    // Return immediately if we already fetched this session
    if (_cachedQuote != null) return;

    final quote = await ExternalApis.getDailyQuote();
    final time = await ExternalApis.getTrueNetworkTime();
    if (mounted) {
      _cachedQuote = quote;
      _cachedTime = time;
      setState(() {
        _quote = quote;
        _networkTime = time;
        _isLoadingApis = false;
      });
      final profile = context.read<ProfileProvider>().profile;
      final name = profile.displayName.isNotEmpty ? profile.displayName : 'Scholar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, $name! 👋', style: const TextStyle(fontWeight: FontWeight.bold)),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _checkLevelUp() {
    final profileProvider = context.read<ProfileProvider>();
    if (profileProvider.pendingLevelUp != null) {
      final level = profileProvider.pendingLevelUp!;
      profileProvider.consumeLevelUp();
      _showLevelUpDialog(level);
    }
  }

  void _showLevelUpDialog(BuddyLevel level) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(level.badge, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              const Text('Level Up!',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF334195))),
              const SizedBox(height: 8),
              Text(
                'Your buddy is now a\n${level.title} ${level.badge}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                level.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF334195),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Awesome! 🎉',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studyProvider = context.watch<StudyProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final navProvider = context.watch<NavigationProvider>();
    final projectProvider = context.watch<ProjectProvider>();

    final buddy = profileProvider.profile.buddyLevel;
    final progressPercentage = (studyProvider.overallProgress * 100).toInt();
    final nextExam = studyProvider.nextUpcomingExam;

    final activeProjects = projectProvider.projects.where((p) => p.progress < 1.0).toList();
    activeProjects.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final nextProject = activeProjects.isNotEmpty ? activeProjects.first : null;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    // Check for level-up on every rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLevelUp());

    final xp = profileProvider.profile.xp;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF111318), Color(0xFF1A1D2E), Color(0xFF111827)]
                : const [Color(0xFFE8F0FA), Color(0xFFF3E8FA), Color(0xFFE0F7FA)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [// HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset('lib/assets/StudyWellLogo.png', height: 28, width: 28),
                              const SizedBox(width: 8),
                              Text(
                                'Study Well',
                                style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xFF2D3142)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.notifications_none_rounded,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF2D3142)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const NotificationDropdown(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Avatar → Dropdown Menu
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            switch (value) {
                              case 'profile':
                                Navigator.push(
                                    context, AppRouter.fade(const ProfileScreen()));
                                break;
                              case 'preferences':
                                Navigator.push(context,
                                    AppRouter.fade(const PreferencesScreen()));
                                break;
                              case 'signout':
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: isDark
                                        ? const Color(0xFF1C1F2A)
                                        : Colors.white,
                                    title: const Text('Sign Out'),
                                    content: const Text(
                                        'Are you sure you want to sign out?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Sign Out',
                                            style: TextStyle(
                                                color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  if (!context.mounted) return;
                                  Navigator.of(context, rootNavigator: true)
                                      .popUntil((route) => route.isFirst);
                                  await FirebaseAuth.instance.signOut();
                                }
                                break;
                            }
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          color: isDark
                              ? const Color(0xFF1C1F2A)
                              : Colors.white,
                          offset: const Offset(0, 50),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline_rounded,
                                      size: 20,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF2D3142)),
                                  const SizedBox(width: 12),
                                  Text('Edit Profile',
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF2D3142))),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'preferences',
                              child: Row(
                                children: [
                                  Icon(Icons.tune_rounded,
                                      size: 20,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF2D3142)),
                                  const SizedBox(width: 12),
                                  Text('App Preferences',
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF2D3142))),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'signout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout_rounded,
                                      size: 20, color: Colors.redAccent),
                                  SizedBox(width: 12),
                                  Text('Sign Out',
                                      style:
                                          TextStyle(color: Colors.redAccent)),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF252840)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 8)
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(profileProvider.profile.avatarEmoji,
                                style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),// QUOTE BANNER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF2D3A8C), const Color(0xFF1E2760)]
                          : [const Color(0xFF334195), const Color(0xFF5B69BD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF334195).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _isLoadingApis
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : Text(
                          _quote,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                ),
                const SizedBox(height: 28),// STUDY BUDDY CARD
                Text('Your Study Buddy',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF2D3142))),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, AppRouter.slide(const GamificationScreen()));
                  },
                  child: _buildGlassCard(
                    isDark: isDark,
                    child: Row(
                      children: [
                        // Pulsing avatar
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF252840)
                                  : const Color(0xFFEEF2FF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF334195)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(profileProvider.profile.avatarEmoji,
                                style: const TextStyle(fontSize: 38)),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(buddy.badge,
                                      style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 6),
                                  Text(
                                    buddy.title,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF2D3142),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF334195)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Lv ${buddy.level}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF334195),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: buddy.progressAt(xp),
                                  minHeight: 7,
                                  backgroundColor: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.06),
                                  valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFF334195)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('$xp XP',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                      )),
                                  Text(
                                    buddy.xpToNext(xp) != null
                                        ? '${buddy.xpToNext(xp)} XP to ${kBuddyLevels[buddy.level].title}'
                                        : '🔥 Max Level!',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),// GLOBAL READINESS
                Text('Global Readiness',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF2D3142))),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => navProvider.setTab(2, scrollToTop: true),
                  child: _buildGlassCard(
                    isDark: isDark,
                    child: Row(
                      children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 80,
                            width: 80,
                            child: CircularProgressIndicator(
                              value: studyProvider.overallProgress,
                              strokeWidth: 8,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.06),
                              color: cs.primary,
                            ),
                          ),
                          Text('$progressPercentage%',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF2D3142))),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studyProvider.activeSubjects.isEmpty
                                  ? 'No active plans'
                                  : 'Keep it up! 💪',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF2D3142)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${studyProvider.activeSubjects.length} Active Session${studyProvider.activeSubjects.length == 1 ? '' : 's'}  ·  ${profileProvider.profile.totalTopicsCompleted} Topics Done',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: 28),// NEXT MAJOR DEADLINE
                Text('Next Major Deadline',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF2D3142))),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: nextExam != null
                      ? GestureDetector(
                          onTap: () => navProvider.setTab(2, scrollToExams: true),
                          child: _buildGlassCard(
                            key: const ValueKey('exam'),
                            isDark: isDark,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.red.shade900.withValues(alpha: 0.4)
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(Icons.timer_outlined,
                                      color: isDark
                                          ? Colors.red.shade300
                                          : Colors.red,
                                      size: 30),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nextExam.name,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.red.shade300
                                                : Colors.red),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Due: ${DateFormat('MMM dd, yyyy h:mm a').format(nextExam.examDate!)}',
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.red.shade400
                                                : Colors.red.shade700,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${nextExam.examDate!.difference(_networkTime).inDays} days remaining',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? Colors.red.shade300
                                                : Colors.red,
                                            fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () => navProvider.setTab(2),
                          child: _buildGlassCard(
                            key: const ValueKey('no_exam'),
                            isDark: isDark,
                            child: Column(
                              children: [
                                Icon(Icons.event_available_rounded,
                                    size: 48,
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text('No upcoming exams!',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF2D3142),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text("You're all caught up.",
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 28),
                // ACTIVE PROJECTS
                Text('Active Projects',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF2D3142))),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => navProvider.setTab(1),
                  child: _buildGlassCard(
                    isDark: isDark,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF4D5FD4).withValues(alpha: 0.2)
                                : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.folder_open_rounded,
                              color: isDark ? const Color(0xFF8FA8F8) : const Color(0xFF334195),
                              size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeProjects.isEmpty
                                    ? 'No active projects'
                                    : 'Keep building! 🚀',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF2D3142)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${activeProjects.length} Active Project${activeProjects.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // NEXT PROJECT DEADLINE
                Text('Next Project Deadline',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF2D3142))),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: nextProject != null
                      ? GestureDetector(
                          onTap: () => navProvider.setTab(1),
                          child: _buildGlassCard(
                            key: const ValueKey('project'),
                            isDark: isDark,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.orange.shade900.withValues(alpha: 0.4)
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(Icons.assignment_late_outlined,
                                      color: isDark
                                          ? Colors.orange.shade300
                                          : Colors.orange,
                                      size: 30),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nextProject.title,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.orange.shade300
                                                : Colors.orange),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Due: ${DateFormat('MMM dd, yyyy').format(nextProject.dueDate)}',
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.orange.shade400
                                                : Colors.orange.shade700,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${nextProject.dueDate.difference(_networkTime).inDays} days remaining',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? Colors.orange.shade300
                                                : Colors.orange,
                                            fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () => navProvider.setTab(1),
                          child: _buildGlassCard(
                            key: const ValueKey('no_project'),
                            isDark: isDark,
                            child: Column(
                              children: [
                                Icon(Icons.task_alt_rounded,
                                    size: 48,
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text('No upcoming projects!',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF2D3142),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text("You're all caught up.",
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, required bool isDark, Key? key}) {
    return ClipRRect(
      key: key,
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
