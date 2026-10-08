import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme choices: light, dark, and pure-black AMOLED.
enum AppThemeMode { light, dark, amoled }

/// Central, persisted application settings.
///
/// Single source of truth for theme, locale and prayer configuration.
/// Exposed to the widget tree via [AppStateScope].
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  static const _kTheme = 'theme_mode';
  static const _kLocale = 'locale_code';
  static const _kCalcMethod = 'calc_method';
  static const _kAsrMethod = 'asr_method';
  static const _kLocationMode = 'location_mode';
  static const _kManualCity = 'manual_city';
  static const _kAdjustPrefix = 'adjust_';
  static const _kNotifMaster = 'notif_master';
  static const _kNotifPrayerPrefix = 'notif_prayer_';
  static const _kNotifDailyPrefix = 'notif_daily_';
  static const _kQuietStart = 'quiet_start'; // minutes since midnight
  static const _kQuietEnd = 'quiet_end';

  static const List<String> prayerKeys = [
    'fajr',
    'sunrise',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  /// Prayers that can raise alarms (sunrise excluded).
  static const List<String> alarmPrayers = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  AppThemeMode themeMode = AppThemeMode.light;
  String localeCode = 'en';
  String calcMethod = 'muslimWorldLeague';
  String asrMethod = 'standard'; // 'standard' | 'hanafi'
  String locationMode = 'gps'; // 'gps' | 'manual'
  String manualCity = 'Manchester';
  Map<String, int> adjustments = {
    for (final k in prayerKeys) k: 0,
  };

  // --- Phase 4: notification preferences ---
  bool notifMaster = false;
  Map<String, bool> prayerAlarms = {for (final k in alarmPrayers) k: true};
  Map<String, bool> dailyReminders = {
    'ayah': true,
    'hadith': true,
    'dua': false,
  };
  int quietStart = 23 * 60; // 23:00
  int quietEnd = 4 * 60 + 30; // 04:30

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      themeMode = AppThemeMode.values.firstWhere(
        (e) => e.name == prefs.getString(_kTheme),
        orElse: () => AppThemeMode.light,
      );
      localeCode = prefs.getString(_kLocale) ?? 'en';
      calcMethod = prefs.getString(_kCalcMethod) ?? 'muslimWorldLeague';
      asrMethod = prefs.getString(_kAsrMethod) ?? 'standard';
      locationMode = prefs.getString(_kLocationMode) ?? 'gps';
      manualCity = prefs.getString(_kManualCity) ?? 'Manchester';
      for (final k in prayerKeys) {
        adjustments[k] = prefs.getInt('$_kAdjustPrefix$k') ?? 0;
      }
      notifMaster = prefs.getBool(_kNotifMaster) ?? false;
      for (final k in alarmPrayers) {
        prayerAlarms[k] = prefs.getBool('$_kNotifPrayerPrefix$k') ?? true;
      }
      for (final k in dailyReminders.keys) {
        dailyReminders[k] =
            prefs.getBool('$_kNotifDailyPrefix$k') ?? (k != 'dua');
      }
      quietStart = prefs.getInt(_kQuietStart) ?? 23 * 60;
      quietEnd = prefs.getInt(_kQuietEnd) ?? (4 * 60 + 30);
    } catch (_) {
      // Storage failure: keep compiled-in defaults.
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTheme, themeMode.name);
      await prefs.setString(_kLocale, localeCode);
      await prefs.setString(_kCalcMethod, calcMethod);
      await prefs.setString(_kAsrMethod, asrMethod);
      await prefs.setString(_kLocationMode, locationMode);
      await prefs.setString(_kManualCity, manualCity);
      for (final k in prayerKeys) {
        await prefs.setInt('$_kAdjustPrefix$k', adjustments[k] ?? 0);
      }
      await prefs.setBool(_kNotifMaster, notifMaster);
      for (final e in prayerAlarms.entries) {
        await prefs.setBool('$_kNotifPrayerPrefix${e.key}', e.value);
      }
      for (final e in dailyReminders.entries) {
        await prefs.setBool('$_kNotifDailyPrefix${e.key}', e.value);
      }
      await prefs.setInt(_kQuietStart, quietStart);
      await prefs.setInt(_kQuietEnd, quietEnd);
    } catch (_) {
      // Non-fatal: settings simply won't survive a restart.
    }
  }

  void setThemeMode(AppThemeMode mode) {
    if (themeMode == mode) return;
    themeMode = mode;
    notifyListeners();
    _persist();
  }

  void setLocaleCode(String code) {
    if (localeCode == code) return;
    localeCode = code;
    notifyListeners();
    _persist();
  }

  void setCalcMethod(String id) {
    if (calcMethod == id) return;
    calcMethod = id;
    notifyListeners();
    _persist();
  }

  void setAsrMethod(String id) {
    if (asrMethod == id) return;
    asrMethod = id;
    notifyListeners();
    _persist();
  }

  void setLocationMode(String mode) {
    if (locationMode == mode) return;
    locationMode = mode;
    notifyListeners();
    _persist();
  }

  void setManualCity(String city) {
    if (manualCity == city) return;
    manualCity = city;
    notifyListeners();
    _persist();
  }

  void setAdjustment(String prayerKey, int minutes) {
    adjustments[prayerKey] = minutes.clamp(-30, 30);
    notifyListeners();
    _persist();
  }

  // --- Phase 4: notification preference mutators ---
  void setNotifMaster(bool v) {
    notifMaster = v;
    notifyListeners();
    _persist();
  }

  bool isPrayerAlarmEnabled(String prayerId) =>
      notifMaster && (prayerAlarms[prayerId] ?? false);

  void setPrayerAlarm(String prayerId, bool v) {
    prayerAlarms[prayerId] = v;
    notifyListeners();
    _persist();
  }

  void setDailyReminder(String id, bool v) {
    dailyReminders[id] = v;
    notifyListeners();
    _persist();
  }

  void setQuietHours(int startMinutes, int endMinutes) {
    quietStart = startMinutes;
    quietEnd = endMinutes;
    notifyListeners();
    _persist();
  }

  /// True when [time] falls inside the user's quiet window.
  /// Handles overnight windows (e.g. 23:00–04:30).
  bool isQuietTime(DateTime time) {
    final m = time.hour * 60 + time.minute;
    if (quietStart <= quietEnd) {
      return m >= quietStart && m < quietEnd;
    }
    return m >= quietStart || m < quietEnd;
  }
}

/// InheritedNotifier that makes [AppState] available below [NoorApp].
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree');
    return scope!.notifier!;
  }
}
