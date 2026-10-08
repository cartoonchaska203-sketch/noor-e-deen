/// Prayer & reminder notification service (Phase 4: real implementation in
/// [LocalNotificationService], see local_notification_service.dart).
///
/// Capabilities:
///   * Exact-time prayer alarms (Fajr..Isha) with Adhan tone.
///   * Daily repeating reminders (ayah / hadith / dua of the day, custom).
///   * Per-prayer enable/disable, quiet-hours respect, one-shot instant alerts.
///
/// On platforms where the plugin cannot run (e.g. some desktop builds),
/// [DisabledNotificationService] is wired in instead: every call is a
/// documented no-op, so no UI button can promise something that does not work.
abstract class NotificationService {
  Future<void> init();

  /// True when the platform backend initialized successfully.
  Future<bool> get isSupported;

  /// Ask the OS for notification (+ exact-alarm where applicable) permission.
  Future<bool> requestPermission();

  /// Schedule (or re-schedule) one prayer alarm.
  Future<void> schedulePrayerAlarm({
    required String prayerId,
    required DateTime time,
    required String title,
    required String body,
  });

  Future<void> cancelPrayerAlarm(String prayerId);

  /// Daily repeating reminder at [hour]:[minute] local time.
  Future<void> scheduleDailyReminder({
    required String id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  });

  Future<void> cancelReminder(String id);

  /// Fire-and-forget heads-up notification right now.
  Future<void> showInstant({
    required String title,
    required String body,
  });

  Future<void> cancelAll();
}

/// Fallback implementation: honestly disabled.
class DisabledNotificationService implements NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> get isSupported async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedulePrayerAlarm({
    required String prayerId,
    required DateTime time,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelPrayerAlarm(String prayerId) async {}

  @override
  Future<void> scheduleDailyReminder({
    required String id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<void> cancelReminder(String id) async {}

  @override
  Future<void> showInstant({
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelAll() async {}
}
