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

  static const List<String> prayerKeys = [
    'fajr',
    'sunrise',
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
