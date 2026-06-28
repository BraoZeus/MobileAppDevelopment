import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_sheet.dart';
import 'notification_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Map<DateTime, List<Map<String, dynamic>>> _calendarEvents = {};
  final Map<DateTime, List<Map<String, dynamic>>> _mergedEvents = {};

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedEvents = [];

  // Stream used to broadcast a clock tick to all active list items every single second
  final Stream<DateTime> _tickerStream = Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  ).asBroadcastStream();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchEventsFromFirebase();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // ── Colour coding by event type ──────────────────────────────────────
  Color _getEventColor(String type, {bool isDark = false}) {
    switch (type) {
      case 'assignment':
        return isDark ? Colors.redAccent.shade100 : Colors.redAccent;
      case 'test':
        return isDark ? const Color(0xFFCE93D8) : Colors.purple;
      case 'study_plan':
        return isDark ? const Color(0xFF8FA8F8) : const Color(0xFF334195);
      default:
        return Colors.grey;
    }
  }

  /// Returns the highest-priority event type for a given day.
  /// Priority: test (exam) > assignment > study_plan
  String? _getDominantType(DateTime day) {
    final events = _calendarEvents[_normalizeDate(day)];
    if (events == null || events.isEmpty) return null;

    bool hasExam = false;
    bool hasAssignment = false;
    bool hasStudyPlan = false;

    for (final e in events) {
      final type = e['type'] as String? ?? '';
      if (type == 'test') hasExam = true;
      if (type == 'assignment') hasAssignment = true;
      if (type == 'study_plan') hasStudyPlan = true;
    }

    if (hasExam) return 'test';
    if (hasAssignment) return 'assignment';
    if (hasStudyPlan) return 'study_plan';
    return null;
  }

  // Formats a precise live ticking time-remaining string
  String _formatCountdown(DateTime eventDate) {
    final now = DateTime.now();
    final difference = eventDate.difference(now);

    if (difference.isNegative) {
      return "Time's up! (Overdue)";
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    List<String> parts = [];
    if (days > 0) parts.add("${days}d");
    if (hours > 0 || days > 0) parts.add("${hours}h");
    parts.add("${minutes}m");
    parts.add("${seconds}s");

    return "Starting in: ${parts.join(' ')}";
  }

  Map<String, dynamic> _getUrgencyBadge(DateTime eventDate, String type) {
    final now = DateTime.now();
    final difference = eventDate.difference(now);

    if (difference.isNegative) {
      if (eventDate.year == now.year &&
          eventDate.month == now.month &&
          eventDate.day == now.day) {
        return {'text': 'Scheduled Today', 'color': Colors.grey};
      }
      return {'text': 'Overdue!', 'color': Colors.red.shade700};
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes;
    final days = difference.inDays;
    final isExam = type == 'test';

    if (minutes < 60) {
      return {
        'text': isExam ? 'Exam in $minutes mins!' : 'Due in $minutes mins!',
        'color': Colors.redAccent,
      };
    } else if (hours < 24) {
      return {
        'text': isExam ? 'Exam in $hours hours!' : 'Due in $hours hours',
        'color': Colors.orange.shade800,
      };
    } else if (days == 1) {
      return {
        'text': isExam ? 'Exam tomorrow!' : 'Due tomorrow!',
        'color': Colors.deepOrange,
      };
    } else {
      return {
        'text': isExam ? 'Exam in $days days' : 'Due in $days days',
        'color': const Color(0xFF334195),
      };
    }
  }

  void _addEventToMergedMap(DateTime date, Map<String, dynamic> eventItem) {
    final DateTime normalizedDate = _normalizeDate(date);
    if (_mergedEvents[normalizedDate] == null) {
      _mergedEvents[normalizedDate] = [];
    }
    _mergedEvents[normalizedDate]!.add(eventItem);
  }

  void _updateCalendarState() {
    if (!mounted) return;
    setState(() {
      _calendarEvents = Map.from(_mergedEvents);
      _selectedEvents = _calendarEvents[_normalizeDate(_selectedDay!)] ?? [];
    });
  }

  void _scheduleProximityNotification(
    Map<String, dynamic> eventItem,
    DateTime eventDate,
  ) {
    DateTime reminderTime;
    String messageBody;
    String notificationTitle;

    if (eventItem['type'] == 'test') {
      reminderTime = eventDate.subtract(const Duration(days: 2));
      notificationTitle = 'Exam in 2 Days!';
      messageBody = 'Your exam "${eventItem['title']}" is in 2 days. Time to revise!';
    } else if (eventItem['type'] == 'study_plan') {
      reminderTime = eventDate.subtract(const Duration(minutes: 30));
      notificationTitle = 'Study Time Alert!';
      messageBody = 'Your study session "${eventItem['title']}" starts in 30 minutes!';
    } else { // assignment/project
      reminderTime = eventDate.subtract(const Duration(hours: 3));
      notificationTitle = 'Submission Reminder!';
      messageBody = '"${eventItem['title']}" submission window closes in 3 hours!';
    }

    if (reminderTime.isAfter(DateTime.now())) {
      NotificationService.scheduleNotification(
        id: eventItem['id'].hashCode,
        title: notificationTitle,
        body: messageBody,
        scheduledDate: reminderTime,
      );
    }
  }

  void _fetchEventsFromFirebase() {
    FirebaseFirestore.instance.collection('calendar_events').snapshots().listen(
      (snapshot) {
        _mergedEvents.removeWhere(
          (key, value) => value.any((e) => e['source'] == 'calendar_events'),
        );

        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['date'] == null) continue;

          final DateTime eventDate = (data['date'] as Timestamp).toDate();
          final eventItem = {
            'id': doc.id,
            'title': data['title'] ?? 'Untitled Task',
            'description': data['description'] ?? '',
            'type': data['type'] ?? 'assignment',
            'date': eventDate,
            'source': 'calendar_events',
          };

          _addEventToMergedMap(eventDate, eventItem);
          _scheduleProximityNotification(eventItem, eventDate);
        }
        _updateCalendarState();
      },
    );

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('study_plans')
          .snapshots()
          .listen((snapshot) {
            _mergedEvents.removeWhere(
              (key, value) => value.any((e) => e['source'] == 'study_sessions'),
            );

            for (var doc in snapshot.docs) {
              final data = doc.data();
              final String title = data['name'] ?? 'Study Plan';
              
              // 1. Add Start Date as a Study Plan event
              if (data['startDate'] != null) {
                final DateTime startDate = DateTime.parse(data['startDate']);
                final eventItem = {
                  'id': '${doc.id}_start',
                  'title': 'Start: $title',
                  'description': 'Study plan start date',
                  'type': 'study_plan',
                  'date': startDate,
                  'source': 'study_sessions',
                };
                _addEventToMergedMap(startDate, eventItem);
                _scheduleProximityNotification(eventItem, startDate);
              }

              // 2. Add Exam Date as a Test event
              if (data['examDate'] != null) {
                final DateTime examDate = DateTime.parse(data['examDate']);
                final eventItem = {
                  'id': '${doc.id}_exam',
                  'title': 'Exam: $title',
                  'description': 'Exam for $title',
                  'type': 'test',
                  'date': examDate,
                  'source': 'study_sessions',
                };
                _addEventToMergedMap(examDate, eventItem);
                _scheduleProximityNotification(eventItem, examDate);
              }
            }
            _updateCalendarState();
          });
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _calendarEvents[_normalizeDate(day)] ?? [];
  }

  void _showAddEventBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'assignment';
    TimeOfDay selectedTime = TimeOfDay.now();

    final brandColor = isDark
        ? const Color(0xFF8FA8F8)
        : const Color(0xFF334195);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E2130) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Calendar Event',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Time picker tile
                    ListTile(
                      leading: Icon(Icons.access_time, color: brandColor),
                      title: Text(
                        "Alert/Due Time: ${selectedTime.format(context)}",
                      ),
                      trailing: Text(
                        "Change",
                        style: TextStyle(
                          color: brandColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF3A3F5C)
                              : Colors.grey.shade400,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () async {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setModalState(() => selectedTime = time);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Event Type:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF252840) : null,
                      items: const [
                        DropdownMenuItem(
                          value: 'assignment',
                          child: Text('Assignment (Red)'),
                        ),
                        DropdownMenuItem(
                          value: 'test',
                          child: Text('Test / Exam (Purple)'),
                        ),
                        DropdownMenuItem(
                          value: 'study_plan',
                          child: Text('Study Session (Blue)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () async {
                        if (titleController.text.isNotEmpty) {
                          final DateTime combinedTimestamp = DateTime(
                            _selectedDay!.year,
                            _selectedDay!.month,
                            _selectedDay!.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          await FirebaseFirestore.instance
                              .collection('calendar_events')
                              .add({
                                'title': titleController.text,
                                'description': descController.text,
                                'type': selectedType,
                                'date': Timestamp.fromDate(combinedTimestamp),
                              });
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      child: const Text('Save Event'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Day cell builder — highlights occupied days ──────────────────────
  Widget? _buildDayCell(
    DateTime day,
    DateTime focusedDay,
    bool isSelected,
    bool isToday,
    bool isDark,
  ) {
    final dominantType = _getDominantType(day);
    if (dominantType == null) return null; // No events — use default rendering

    final Color fillColor = _getEventColor(dominantType, isDark: isDark);
    final bool isCurrentlySelected = isSelected;
    final bool isCurrentDay = isToday;

    // Selected or today states override the fill styling
    if (isCurrentlySelected || isCurrentDay) return null;

    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: fillColor.withAlpha(isDark ? 60 : 40),
        shape: BoxShape.circle,
        border: Border.all(
          color: fillColor.withAlpha(isDark ? 130 : 100),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: isDark ? Colors.white : fillColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;
    final brandColor = isDark
        ? const Color(0xFF8FA8F8)
        : const Color(0xFF334195);
    final bgColor = isDark ? const Color(0xFF111318) : const Color(0xFFF8F9FA);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: InkWell(
            onTap: () {
               showProfileSheet(context);
            },
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
                profile.avatarEmoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
        ),
        title: Text(
          'Calendar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: brandColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white : brandColor),
            onPressed: () {
               showDialog(
                 context: context,
                 builder: (_) => const NotificationDropdown(),
               );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [

          // ── COLOUR LEGEND ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legendDot(Colors.purple, 'Exam', isDark),
                _legendDot(Colors.redAccent, 'Assignment', isDark),
                _legendDot(const Color(0xFF334195), 'Study Plan', isDark),
              ],
            ),
          ),

          // ── CALENDAR ───────────────────────────────────────────────
          TableCalendar(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedEvents = _getEventsForDay(selectedDay);
              });
            },
            calendarBuilders: CalendarBuilders(
              // Highlight occupied days with a coloured fill
              defaultBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, focusedDay, false, false, isDark);
              },
              outsideBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, focusedDay, false, false, isDark);
              },
              // Small coloured dots below the day number
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox();
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events.take(4).map((event) {
                      final item = event as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.0),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getEventColor(item['type'], isDark: isDark),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: brandColor.withAlpha(76),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: brandColor,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              weekendTextStyle: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              outsideTextStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.grey.shade400,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontWeight: FontWeight.w600,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: isDark ? Colors.white : const Color(0xFF2D3142),
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: brandColor),
              rightChevronIcon: Icon(Icons.chevron_right, color: brandColor),
            ),
          ),

          Divider(
            color: isDark ? const Color(0xFF2C3050) : const Color(0xFFEEEEEE),
          ),

          // ── EVENT REMINDERS LIST VIEW ───────────────────────────────
          Expanded(
            child: _selectedEvents.isEmpty
                ? Center(
                    child: Text(
                      'Clear day! No upcoming due dates or study tracks.',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = _selectedEvents[index];
                      final Color categoryColor = _getEventColor(
                        event['type'],
                        isDark: isDark,
                      );

                      final DateTime rawDate = event['date'] ?? DateTime.now();
                      final badgeInfo = _getUrgencyBadge(
                        rawDate,
                        event['type'],
                      );
                      final String timeString =
                          "${rawDate.hour.toString().padLeft(2, '0')}:${rawDate.minute.toString().padLeft(2, '0')}";

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6.0,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Row(
                            children: [
                              // Coloured side strip
                              Container(
                                width: 6,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: categoryColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                ),
                              ),
                              // Content
                              Expanded(
                                child: ListTile(
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          event['title'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF2D3142),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (badgeInfo['color'] as Color)
                                              .withAlpha(35),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: badgeInfo['color'],
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          badgeInfo['text'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: badgeInfo['color'],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: StreamBuilder<DateTime>(
                                    stream: _tickerStream,
                                    builder: (context, snapshot) {
                                      return Text(
                                        'TIME: $timeString | ${event['type'].toString().replaceAll('_', ' ').toUpperCase()}\n'
                                        '${_formatCountdown(rawDate)}\n'
                                        '${event['description']}',
                                        style: TextStyle(
                                          height: 1.3,
                                          color: isDark ? Colors.white60 : null,
                                        ),
                                      );
                                    },
                                  ),
                                  isThreeLine: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      )),
      floatingActionButton: FloatingActionButton(
        backgroundColor: brandColor,
        onPressed: _showAddEventBottomSheet,
        child: Icon(
          Icons.add,
          color: isDark ? const Color(0xFF111318) : Colors.white,
        ),
      ),
    );
  }

  /// Small legend dot + label widget for the colour key.
  Widget _legendDot(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withAlpha(isDark ? 150 : 200),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
