import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/study_provider.dart';
import '../services/api_services.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _quote = "Loading inspiration...";
  DateTime _networkTime = DateTime.now();
  bool _isLoadingApis = true;

  @override
  void initState() {
    super.initState();
    _loadHomeApis();
  }

  Future<void> _loadHomeApis() async {
    final quote = await ExternalApis.getDailyQuote();
    final time = await ExternalApis.getTrueNetworkTime();
    if (mounted) {
      setState(() {
        _quote = quote;
        _networkTime = time;
        _isLoadingApis = false;
      });
    }
  }

  // --- REUSABLE GLASS CONTAINER ---
  Widget _buildGlassContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8))
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studyProvider = context.watch<StudyProvider>();
    final nextExam = studyProvider.nextUpcomingExam;
    int progressPercentage = (studyProvider.overallProgress * 100).toInt();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER SECTION ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // FIX 1: Wrap the text column in Expanded to prevent UI overflow
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Welcome back,', style: TextStyle(fontSize: 16, color: Colors.black54)),
                          Text(
                            'Ready to study?',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2D3142)),
                            overflow: TextOverflow.ellipsis, // Ensures text truncates neatly if screen is very small
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        // LOGOUT BUTTON
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              shape: BoxShape.circle
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                            onPressed: () async {
                              // 1. Log out of Firebase Auth (The StudyProvider will detect this and wipe its own RAM automatically!)
                              await FirebaseAuth.instance.signOut();

                              // 2. Pop all screens off the stack so the StreamBuilder takes over properly
                              if (context.mounted) {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              shape: BoxShape.circle
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF2D3142)),
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Replace your existing CircleAvatar block with this:
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(22), // Makes the ripple effect circular
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            // Using current user's photo if available, fallback to the placeholder
                            backgroundImage: NetworkImage(
                                FirebaseAuth.instance.currentUser?.photoURL ?? 'https://i.pravatar.cc/150?img=11'
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- MOTIVATION API WIDGET ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF334195), Color(0xFF5B69BD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: const Color(0xFF334195).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: _isLoadingApis
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : Text(
                    _quote,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                // --- OVERALL PROGRESS TRACKER ---
                const Text('Global Readiness', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                const SizedBox(height: 12),
                _buildGlassContainer(
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 80, width: 80,
                            child: CircularProgressIndicator(
                                value: studyProvider.overallProgress,
                                strokeWidth: 8,
                                backgroundColor: Colors.white.withValues(alpha: 0.5),
                                color: const Color(0xFF334195)
                            ),
                          ),
                          Text('$progressPercentage%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                studyProvider.activeSubjects.isEmpty ? 'No active plans' : 'Keep it up!',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))
                            ),
                            const SizedBox(height: 4),
                            Text(
                                '${studyProvider.activeSubjects.length} Active Sessions',
                                style: const TextStyle(color: Colors.black54)
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- UPCOMING EXAM COUNTDOWN ---
                const Text('Next Major Deadline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                const SizedBox(height: 12),

                if (nextExam != null) ...[
                  _buildGlassContainer(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.timer_outlined, color: Colors.red, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nextExam.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                              const SizedBox(height: 4),
                              Text('Due: ${DateFormat('MMM dd, yyyy').format(nextExam.examDate!)}', style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                  '${nextExam.examDate!.difference(_networkTime).inDays} days remaining',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red, fontSize: 16)
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ] else ...[
                  _buildGlassContainer(
                    child: Column(
                      children: [
                        Icon(Icons.event_available_rounded, size: 48, color: Colors.grey.shade500),
                        const SizedBox(height: 12),
                        const Center(child: Text("No upcoming exams!", style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 16))),
                        const SizedBox(height: 4),
                        const Center(child: Text("You're all caught up.", style: TextStyle(color: Colors.black54, fontSize: 13))),
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}