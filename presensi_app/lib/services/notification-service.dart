import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  }

  static Future<void> scheduleNotification(
    int id,
    int hour,
    int minute,
    String message,
  ) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      "Pengingat Absen",
      message, // Pesan bisa disesuaikan (masuk/pulang)
      _convertTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'absen_channel',
          'Pengingat Absen',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _convertTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static Future<void> scheduleDailyReminders() async {
    await scheduleNotification(1, 6, 45, "Jangan lupa absen masuk!");
    await scheduleNotification(2, 6, 50, "Jangan lupa absen masuk!");
    await scheduleNotification(3, 6, 55, "Jangan lupa absen masuk!");
    await scheduleNotification(4, 14, 15, "Jangan lupa absen pulang!");
    await scheduleNotification(4, 14, 20, "Jangan lupa absen pulang!");
    await scheduleNotification(4, 14, 25, "Jangan lupa absen pulang!");
  }
}
