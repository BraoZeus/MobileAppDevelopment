import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationDropdown extends StatelessWidget {
  const NotificationDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor = isDark ? const Color(0xFF8FA8F8) : const Color(0xFF334195);
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.only(top: topPadding, right: 16),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            constraints: const BoxConstraints(maxHeight: 450),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1F2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Center(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        color: brandColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                Flexible(
                  child: _NotificationList(isDark: isDark, brandColor: brandColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final bool isDark;
  final Color brandColor;

  const _NotificationList({required this.isDark, required this.brandColor});

  Color _typeColor(String type) {
    switch (type) {
      case 'test':
        return Colors.purple;
      case 'assignment':
        return Colors.redAccent;
      case 'study_plan':
        return const Color(0xFF334195);
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'test':
        return Icons.quiz_rounded;
      case 'assignment':
        return Icons.assignment_rounded;
      case 'study_plan':
        return Icons.menu_book_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'test':
        return 'Exam';
      case 'assignment':
        return 'Assignment';
      case 'study_plan':
        return 'Study Session';
      default:
        return 'Event';
    }
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.isNegative) {
      final absDiff = diff.abs();
      if (absDiff.inMinutes < 60) return '${absDiff.inMinutes}m ago';
      if (absDiff.inHours < 24) return '${absDiff.inHours}h ago';
      return '${absDiff.inDays}d ago';
    }

    if (diff.inMinutes < 60) return 'in ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'in ${diff.inHours}h';
    return 'in ${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('calendar_events')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, calendarSnap) {
        // Also fetch study plans for the current user
        if (currentUser == null) {
          return _buildList(context, calendarSnap.data?.docs ?? [], []);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('study_plans')
              .snapshots(),
          builder: (context, studySnap) {
            if (calendarSnap.connectionState == ConnectionState.waiting &&
                studySnap.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: brandColor),
              );
            }

            final calendarDocs = calendarSnap.data?.docs ?? [];
            final studyDocs = studySnap.data?.docs ?? [];

            return _buildList(context, calendarDocs, studyDocs);
          },
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<QueryDocumentSnapshot> calendarDocs,
      List<QueryDocumentSnapshot> studyDocs) {
    // Convert all docs into a unified notification list
    final List<Map<String, dynamic>> notifications = [];

    for (var doc in calendarDocs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['date'] == null) continue;
      final DateTime eventDate = (data['date'] as Timestamp).toDate();
      notifications.add({
        'title': data['title'] ?? 'Untitled',
        'description': data['description'] ?? '',
        'type': data['type'] ?? 'assignment',
        'date': eventDate,
      });
    }

    for (var doc in studyDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final String title = data['name'] ?? 'Study Plan';
      
      if (data['startDate'] != null) {
        final DateTime sessionDate = DateTime.parse(data['startDate']);
        notifications.add({
          'title': 'Start: $title',
          'description': 'Study plan start date',
          'type': 'study_plan',
          'date': sessionDate,
        });
      }

      if (data['examDate'] != null) {
        final DateTime examDate = DateTime.parse(data['examDate']);
        notifications.add({
          'title': 'Exam: $title',
          'description': 'Exam for $title',
          'type': 'test',
          'date': examDate,
        });
      }
    }

    // Sort by date (nearest first)
    notifications.sort((a, b) {
      final aDiff = (a['date'] as DateTime).difference(DateTime.now()).abs();
      final bDiff = (b['date'] as DateTime).difference(DateTime.now()).abs();
      return aDiff.compareTo(bDiff);
    });

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_rounded,
              size: 64,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Events and reminders will appear here',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white30 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final item = notifications[index];
        final DateTime date = item['date'];
        final String type = item['type'];
        final Color color = _typeColor(type);
        final bool isPast = date.isBefore(DateTime.now());

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                // Coloured side strip
                Container(
                  width: 5,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(isDark ? 40 : 25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_typeIcon(type), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : const Color(0xFF2D3142),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _typeLabel(type),
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Time badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.grey.withAlpha(isDark ? 40 : 25)
                        : color.withAlpha(isDark ? 40 : 25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _timeAgo(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPast
                          ? (isDark ? Colors.white38 : Colors.grey)
                          : color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
