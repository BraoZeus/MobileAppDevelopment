import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/project_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  /// Schedules a notification to fire at a specific date and time in the future.
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_well_channel',
          'Academic Reminders',
          channelDescription: 'Notifications for assignments, tests, and study plans',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleForProject(Project project) async {
    // Cancel existing
    await cancelForProject(project.id);
    
    if (project.alert1Day) {
      await scheduleNotification(
        id: project.id.hashCode,
        title: 'Project Due Soon',
        body: '${project.title} is due tomorrow.',
        scheduledDate: project.dueDate.subtract(const Duration(days: 1)),
      );
    }
    if (project.alertMorning) {
      await scheduleNotification(
        id: project.id.hashCode + 1,
        title: 'Project Due Today',
        body: '${project.title} is due today.',
        scheduledDate: DateTime(project.dueDate.year, project.dueDate.month, project.dueDate.day, 8, 0),
      );
    }
  }

  static Future<void> cancelForProject(String id) async {
    await _notificationsPlugin.cancel(id.hashCode);
    await _notificationsPlugin.cancel(id.hashCode + 1);
  }

  static Future<void> showMilestone(Project project, String subtaskTitle) async {
    await _notificationsPlugin.show(
      subtaskTitle.hashCode,
      'Milestone Completed!',
      'You completed "$subtaskTitle" for ${project.title}. Keep it up!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_well_channel',
          'Academic Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
