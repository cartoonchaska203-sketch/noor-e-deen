import 'package:flutter/material.dart';

import '../../core/services/app_services.dart';
import '../../core/services/notifications/prayer_alarm_scheduler.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/common_widgets.dart';
import '../../l10n/strings.dart';

/// Notification settings (Phase 4): master toggle, per-prayer alarms,
/// daily reminders, quiet hours. Everything persists via AppState.
///
/// Note shown honestly: prayer alarms always fire when enabled (even in
/// quiet hours) — quiet hours mute reminders only.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _supported = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await AppServices.notifications.isSupported;
    if (!mounted) return;
    setState(() {
      _supported = ok;
      _checking = false;
    });
  }

  Future<void> _toggleMaster(bool v) async {
    final state = AppState.instance;
    if (v) {
      final granted =
          await AppServices.notifications.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, 'notif_perm_denied'))),
        );
      }
      state.setNotifMaster(true);
      await PrayerAlarmScheduler.reschedule(
          notifications: AppServices.notifications);
      await _applyDailyReminders();
    } else {
      state.setNotifMaster(false);
      await PrayerAlarmScheduler.cancelAll(
          AppServices.notifications);
      await _clearDailyReminders();
    }
    setState(() {});
  }

  Future<void> _applyDailyReminders() async {
    final state = AppState.instance;
    final n = AppServices.notifications;
    const defs = {
      'ayah': [7, 0],
      'hadith': [12, 30],
      'dua': [21, 0],
    };
    for (final e in defs.entries) {
      if (!(state.dailyReminders[e.key] ?? false)) {
        await n.cancelReminder('daily_${e.key}');
        continue;
      }
      int hour = e.value[0], minute = e.value[1];
      // Respect quiet hours: shift into the first minute after quiet end.
      final probe = DateTime(2026, 1, 1, hour, minute);
      if (state.isQuietTime(probe)) {
        hour = state.quietEnd ~/ 60;
        minute = state.quietEnd % 60;
      }
      await n.scheduleDailyReminder(
        id: 'daily_${e.key}',
        title: S.of(context, 'notif_daily_${e.key}_title'),
        body: S.of(context, 'notif_daily_${e.key}_body'),
        hour: hour,
        minute: minute,
      );
    }
  }

  Future<void> _clearDailyReminders() async {
    final n = AppServices.notifications;
    for (final k in ['ayah', 'hadith', 'dua']) {
      await n.cancelReminder('daily_$k');
    }
  }

  Future<void> _togglePrayer(String id, bool v) async {
    AppState.instance.setPrayerAlarm(id, v);
    await PrayerAlarmScheduler.reschedule(
        notifications: AppServices.notifications);
    setState(() {});
  }

  Future<void> _toggleDaily(String id, bool v) async {
    AppState.instance.setDailyReminder(id, v);
    await _applyDailyReminders();
    setState(() {});
  }

  Future<void> _pickQuiet(bool isStart) async {
    final state = AppState.instance;
    final cur = isStart ? state.quietStart : state.quietEnd;
    final t = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: cur ~/ 60, minute: cur % 60),
    );
    if (t == null) return;
    final mins = t.hour * 60 + t.minute;
    if (isStart) {
      state.setQuietHours(mins, state.quietEnd);
    } else {
      state.setQuietHours(state.quietStart, mins);
    }
    await _applyDailyReminders();
    setState(() {});
  }

  String _fmt(int mins) {
    final h = mins ~/ 60, m = mins % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'notif_title'))),
      body: _checking
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (!_supported)
                  InfoCard(
                    icon: Icons.notifications_off_outlined,
                    title: S.of(context, 'notif_unsupported_title'),
                    body: S.of(context, 'notif_unsupported_body'),
                  ),
                SwitchListTile(
                  title: Text(S.of(context, 'notif_master'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700)),
                  subtitle:
                      Text(S.of(context, 'notif_master_sub')),
                  value: state.notifMaster && _supported,
                  onChanged: _supported ? _toggleMaster : null,
                ),
                SectionTitle(S.of(context, 'notif_prayers')),
                Card(
                  child: Column(
                    children: [
                      for (final p in AppState.alarmPrayers) ...[
                        SwitchListTile(
                          dense: true,
                          title: Text(S.of(context, 'prayer_$p')),
                          value: state.prayerAlarms[p] ?? true,
                          onChanged: state.notifMaster && _supported
                              ? (v) => _togglePrayer(p, v)
                              : null,
                        ),
                        if (p != AppState.alarmPrayers.last)
                          const Divider(
                              height: 1, indent: 16, endIndent: 16),
                      ],
                    ],
                  ),
                ),
                InfoCard(
                  icon: Icons.bedtime_outlined,
                  title: S.of(context, 'notif_quiet_note_title'),
                  body: S.of(context, 'notif_quiet_note_body'),
                ),
                SectionTitle(S.of(context, 'notif_daily')),
                Card(
                  child: Column(
                    children: [
                      for (final k in ['ayah', 'hadith', 'dua']) ...[
                        SwitchListTile(
                          dense: true,
                          title: Text(
                              S.of(context, 'notif_daily_${k}_title')),
                          value:
                              state.dailyReminders[k] ?? false,
                          onChanged: state.notifMaster && _supported
                              ? (v) => _toggleDaily(k, v)
                              : null,
                        ),
                        if (k != 'dua')
                          const Divider(
                              height: 1, indent: 16, endIndent: 16),
                      ],
                    ],
                  ),
                ),
                SectionTitle(S.of(context, 'notif_quiet')),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        dense: true,
                        title:
                            Text(S.of(context, 'notif_quiet_start')),
                        trailing: TextButton(
                          onPressed: state.notifMaster && _supported
                              ? () => _pickQuiet(true)
                              : null,
                          child: Text(_fmt(state.quietStart)),
                        ),
                      ),
                      const Divider(
                          height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        dense: true,
                        title: Text(S.of(context, 'notif_quiet_end')),
                        trailing: TextButton(
                          onPressed: state.notifMaster && _supported
                              ? () => _pickQuiet(false)
                              : null,
                          child: Text(_fmt(state.quietEnd)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.notifications_active_outlined),
                  label:
                      Text(S.of(context, 'notif_test')),
                  onPressed: _supported
                      ? () => AppServices.notifications.showInstant(
                            title: S.of(context, 'notif_test_title'),
                            body: S.of(context, 'notif_test_body'),
                          )
                      : null,
                ),
              ],
            ),
    );
  }
}
