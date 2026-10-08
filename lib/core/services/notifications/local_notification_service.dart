import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_service.dart';

/// Real local-notification implementation (flutter_local_notifications v22).
///
/// Channels:
///   * `prayer_alarms` — max importance, alarm category, uses the bundled
///     `adhan_placeholder` raw sound. Sound file lives at
///     `android/app/src/main/res/raw/adhan_placeholder.wav` (see
///     assets/audio/README.md for replacing with licensed adhan audio).
///   * `reminders` — default importance for daily/goal reminders.
///
/// On web and desktop this implementation reports unsupported and all
/// calls become safe no-ops (guarded by [isSupported]).
///
/// init() loads the IANA tz database and pins tz.local to the device's
/// zone (via flutter_timezone), so alarms fire on wall-clock time.
/// Prayer alarms use exactAllowWhileIdle; reminders use inexact to save
/// battery.
class LocalNotificationService implements NotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance =
      LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get _ok {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  @override
  Future<bool> get isSupported async => _ok;

  @override
  Future<void> init() async {
    if (_initialized || !_ok) return;
    // Timezone database + device zone: alarms fire on wall-clock time.
    try {
      tzdata.initializeTimeZones();
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      debugPrint('Noor-e-Deen tz init failed ($e); using UTC fallback');
    }
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      ),
    );

    const prayerChannel = AndroidNotificationChannel(
      'prayer_alarms',
      'Prayer alarms',
      description: 'Alarms for the five daily prayers',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('adhan_placeholder'),
    );
    const reminderChannel = AndroidNotificationChannel(
      'reminders',
      'Reminders',
      description: 'Daily ayah, hadith, dua and goal reminders',
      importance: Importance.defaultImportance,
    );
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(prayerChannel);
    await android?.createNotificationChannel(reminderChannel);
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ok) return false;
    await init();
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final notif =
        await android?.requestNotificationsPermission() ?? false;
    // Exact alarms: needed so prayer times fire on time even in Doze.
    await android?.requestExactAlarmsPermission();
    return notif;
  }

  NotificationDetails _prayerDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_alarms',
          'Prayer alarms',
          channelDescription: 'Alarms for the five daily prayers',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          sound: RawResourceAndroidNotificationSound('adhan_placeholder'),
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: false,
        ),
      );

  NotificationDetails _reminderDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Reminders',
          channelDescription: 'Daily ayah, hadith, dua and goal reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: false,
        ),
      );

  @override
  Future<void> schedulePrayerAlarm({
    required String prayerId,
    required DateTime time,
    required String title,
    required String body,
  }) async {
    if (!_ok) return;
    await init();
    final scheduled = tz.TZDateTime.from(time, tz.local);
    await _plugin.zonedSchedule(
      id: prayerId.hashCode & 0x7fffffff,
      scheduledDate: scheduled,
      notificationDetails: _prayerDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: title,
      body: body,
      payload: 'prayer_alarm:$prayerId',
    );
  }

  @override
  Future<void> cancelPrayerAlarm(String prayerId) async {
    if (!_ok) return;
    await _plugin.cancel(id: prayerId.hashCode & 0x7fffffff);
  }

  @override
  Future<void> scheduleDailyReminder({
    required String id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_ok) return;
    await init();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: id.hashCode & 0x7fffffff,
      scheduledDate: scheduled,
      notificationDetails: _reminderDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: 'daily_reminder',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelReminder(String id) async {
    if (!_ok) return;
    await _plugin.cancel(id: id.hashCode & 0x7fffffff);
  }

  @override
  Future<void> showInstant({
    required String title,
    required String body,
  }) async {
    if (!_ok) return;
    await init();
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: _reminderDetails(),
      payload: 'instant',
    );
  }

  @override
  Future<void> cancelAll() async {
    if (!_ok) return;
    await _plugin.cancelAll();
  }
}
