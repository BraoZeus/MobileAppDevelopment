import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/project_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Set up timezone to match the device's local timezone
    tz.initializeTimeZones();
    final String localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
    );
  }

  static Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation <AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  // Converts UUID string to a stable int for notification IDs.
  // offset 0 = 1-day-before, offset 1 = morning, offset 2 = milestone
  static int _notifId(String projectId, int offset) {
    final hex = projectId.replaceAll('-', '').substring(0, 8);
    return (int.parse(hex, radix: 16) & 0x7FFFFFFF) + offset;
  }

  // Called on project add or update — cancels old ones then reschedules
  static Future<void> scheduleForProject(Project project) async {
    await cancelForProject(project.id);
    final now = DateTime.now();

    // 1 Day Before — push notification
    if (project.alert1Day) {
      final target = project.dueDate.subtract(const Duration(days: 1));
      if (target.isAfter(now)) {
        await _schedule(
          id: _notifId(project.id, 0),
          title: '📚 Deadline Tomorrow',
          body: '"${project.title}" is due tomorrow.',
          when: target,
          channelId: 'project_deadlines',
          channelName: 'Project Deadlines',
        );
      }
    }

    // Morning of Deadline — fires at 8:00 AM on the due date
    if (project.alertMorning) {
      final target = DateTime(
        project.dueDate.year,
        project.dueDate.month,
        project.dueDate.day,
        8, 0,
      );
      if (target.isAfter(now)) {
        await _schedule(
          id: _notifId(project.id, 1),
          title: '🔔 Due Today',
          body: '"${project.title}" is due today. You\'ve got this!',
          when: target,
          channelId: 'project_deadlines',
          channelName: 'Project Deadlines',
        );
      }
    }

    // Milestone alerts fire instantly on subtask completion — see showMilestone()
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required String channelId,
    required String channelName,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Called immediately when a subtask is checked off
  static Future<void> showMilestone(Project project, String subtaskTitle) async {
    if (!project.alertMilestone) return;
    await _plugin.show(
      _notifId(project.id, 2),
      '✅ Milestone Complete',
      '"$subtaskTitle" done in ${project.title}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'project_milestones',
          'Project Milestones',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  // Called on project delete
  static Future<void> cancelForProject(String projectId) async {
    await _plugin.cancel(_notifId(projectId, 0));
    await _plugin.cancel(_notifId(projectId, 1));
    await _plugin.cancel(_notifId(projectId, 2));
  }
}