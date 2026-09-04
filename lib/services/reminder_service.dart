import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class ReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });
}

class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  static const _notificationId = 1001;
  static const _enabledKey = 'study_reminder_enabled';
  static const _hourKey = 'study_reminder_hour';
  static const _minuteKey = 'study_reminder_minute';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _notifications.initialize(settings: settings);

    tz_data.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } catch (error) {
      debugPrint('Could not determine the local timezone: $error');
    }

    _initialized = true;

    final saved = await getSettings();
    if (saved.enabled) {
      await _schedule(saved.hour, saved.minute);
    }
  }

  Future<ReminderSettings> getSettings() async {
    final preferences = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled: preferences.getBool(_enabledKey) ?? false,
      hour: preferences.getInt(_hourKey) ?? 9,
      minute: preferences.getInt(_minuteKey) ?? 0,
    );
  }

  Future<bool> save({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return false;
    if (!_initialized) await initialize();

    if (enabled && !await _requestPermission()) return false;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, enabled);
    await preferences.setInt(_hourKey, hour);
    await preferences.setInt(_minuteKey, minute);

    if (enabled) {
      await _schedule(hour, minute);
    } else {
      await _notifications.cancel(id: _notificationId);
    }
    return true;
  }

  Future<bool> _requestPermission() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }

    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  Future<void> _schedule(int hour, int minute) async {
    await _notifications.cancel(id: _notificationId);

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    await _notifications.zonedSchedule(
      id: _notificationId,
      title: 'Time to practise data engineering',
      body: 'Keep your interview skills sharp with a quick study session.',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_study_reminder',
          'Daily study reminder',
          channelDescription: 'Daily reminders to practise interview questions',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
