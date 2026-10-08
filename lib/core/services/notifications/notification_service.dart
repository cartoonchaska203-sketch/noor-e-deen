/// Prayer & reminder notification service — Phase 4 integration point.
///
/// WHAT IT WILL DO (Phase 4):
///   * Schedule exact-time prayer notifications (Fajr..Isha) with Adhan sound.
///   * Per-prayer enable/disable, silent-mode behaviour, custom reminders.
///
/// REQUIRED TO ACTIVATE:
///   1. Add dependency: `flutter_local_notifications: ^18.0.0` (+ `timezone`).
///   2. Android: request `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` permission
///      in AndroidManifest.xml (Android 12+ needs user grant in settings).
///   3. Android: create a notification channel "prayer_alarms" (importance max).
///   4. iOS: request notification permission at runtime; add background modes
///      if Adhan audio must play while the app is killed.
///   5. Bundle an Adhan audio asset (licensed recitation) under assets/audio/.
///
/// Until then [DisabledNotificationService] is wired in: every call is a
/// documented no-op, so no UI button can promise something that does not work.
abstract class NotificationService {
  Future<void> init();
  Future<bool> get isSupported;
  Future<void> schedulePrayerAlarm({
    required String prayerId,
    required DateTime time,
  });
  Future<void> cancelPrayerAlarm(String prayerId);
  Future<void> cancelAll();
}

/// Phase 1 implementation: honestly disabled.
class DisabledNotificationService implements NotificationService {
  @override
  Future<void> init() async {
    // Intentionally empty until Phase 4.
  }

  @override
  Future<bool> get isSupported async => false;

  @override
  Future<void> schedulePrayerAlarm({
    required String prayerId,
    required DateTime time,
  }) async {
    // No-op: prayer alarms arrive in Phase 4.
  }

  @override
  Future<void> cancelPrayerAlarm(String prayerId) async {
    // No-op.
  }

  @override
  Future<void> cancelAll() async {
    // No-op.
  }
}
