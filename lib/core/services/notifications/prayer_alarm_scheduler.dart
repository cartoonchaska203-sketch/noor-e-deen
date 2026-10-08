import 'package:flutter/foundation.dart';

import '../location_service.dart';
import '../prayer_service.dart';
import '../../state/app_state.dart';
import 'notification_service.dart';

/// Schedules exact-time prayer alarms for the coming days.
///
/// Called on app start and whenever prayer settings change. Schedules
/// [daysAhead] days (default 7) so alarms survive without reopening the
/// app. Only prayers enabled in [AppState] are scheduled.
///
/// Note: prayer alarms intentionally ignore quiet hours — a prayer alarm
/// is the point of the feature (e.g. Fajr). Quiet hours apply to
/// reminders only; the settings screen states this explicitly.
class PrayerAlarmScheduler {
  PrayerAlarmScheduler._();

  static const List<String> alarmablePrayers = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  /// Display names for notifications (transliterations; kept in English
  /// because the scheduler has no BuildContext — the OS tray shows these).
  static const Map<String, String> _displayNames = {
    'fajr': 'Fajr',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };

  /// Recompute and (re)schedule all enabled prayer alarms.
  static Future<void> reschedule({
    required NotificationService notifications,
    int daysAhead = 7,
  }) async {
    try {
      if (!await notifications.isSupported) return;
      final state = AppState.instance;

      final loc = await LocationService.resolve(
        mode: state.locationMode,
        manualCityName: state.manualCity,
      );

      final now = DateTime.now();
      for (int d = 0; d < daysAhead; d++) {
        final date = DateTime(now.year, now.month, now.day)
            .add(Duration(days: d));
        final day = PrayerService.calculate(
          latitude: loc.lat,
          longitude: loc.lon,
          date: date,
          methodId: state.calcMethod,
          asrMethod: state.asrMethod,
          adjustments: state.adjustments,
        );
        for (final entry in day.entries) {
          if (!alarmablePrayers.contains(entry.id)) continue;
          if (!state.isPrayerAlarmEnabled(entry.id)) continue;
          // Stagger ids per day so re-scheduling replaces cleanly.
          final id = '${entry.id}_$d';
          final when = entry.time;
          if (when.isBefore(now)) continue;
          final name = _displayNames[entry.id] ?? entry.id;
          await notifications.schedulePrayerAlarm(
            prayerId: id,
            time: when,
            title: '$name prayer time',
            body: 'It is time for $name prayer.',
          );
        }
      }
    } catch (e) {
      debugPrint('Noor-e-Deen PrayerAlarmScheduler failed: $e');
    }
  }

  /// Cancel every prayer alarm (e.g. when the master toggle is switched off).
  static Future<void> cancelAll(
      NotificationService notifications) async {
    try {
      for (int d = 0; d < 7; d++) {
        for (final p in alarmablePrayers) {
          await notifications.cancelPrayerAlarm('${p}_$d');
        }
      }
    } catch (_) {/* ignore */}
  }
}
