import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/lesson.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _notificationId = 0;
  static const _channelId = 'next_lesson_channel';

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    // Request POST_NOTIFICATIONS permission (Android 13+)
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
  }

  static Future<void> showNextLesson(Lesson? lesson) async {
    if (lesson == null) {
      await _plugin.cancel(_notificationId);
      return;
    }

    final body = StringBuffer('${lesson.startTimeStr} — ${lesson.endTimeStr}');
    if (lesson.room.isNotEmpty) body.write(' · каб. ${lesson.room}');
    if (lesson.teacher.isNotEmpty) body.write(' · ${lesson.teacher}');

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'Следующий урок',
      channelDescription: 'Ближайший предстоящий урок на экране блокировки',
      importance: Importance.low,
      priority: Priority.low,
      autoCancel: false,
      showWhen: false,
      // Show full content on lock screen
      visibility: NotificationVisibility.public,
    );

    await _plugin.show(
      _notificationId,
      lesson.subject,
      body.toString(),
      const NotificationDetails(android: androidDetails),
    );
  }
}
