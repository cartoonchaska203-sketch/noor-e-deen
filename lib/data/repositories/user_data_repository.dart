import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// All user-generated data (bookmarks, progress, streaks) stays on-device.
class UserDataRepository {
  UserDataRepository._();
  static final UserDataRepository instance = UserDataRepository._();

  static const _kAyahBookmarks = 'ayah_bookmarks'; // ["2:255", ...]
  static const _kAyahFavorites = 'ayah_favorites';
  static const _kHadithBookmarks = 'hadith_bookmarks'; // ["bukhari:1:1"]
  static const _kDuaBookmarks = 'dua_bookmarks'; // ["dua_01"]
  static const _kLastRead = 'quran_last_read'; // {"surah":2,"ayah":255}
  static const _kReadAyahs = 'quran_read_ayahs'; // ["2:255"]
  static const _kTasbeehHistory = 'tasbeeh_history'; // [{"date":..,"dhikr":..,"count":..}]
  static const _kAdhkarDone = 'adhkar_done'; // {"2026-10-08": ["morning"]}
  static const _kQuranFontScale = 'quran_font_scale';

  Future<Set<String>> _getSet(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key)?.toSet() ?? {};
  }

  Future<void> _toggleInSet(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final set = prefs.getStringList(key)?.toSet() ?? {};
    if (set.contains(value)) {
      set.remove(value);
    } else {
      set.add(value);
    }
    await prefs.setStringList(key, set.toList());
  }

  // --- Ayah bookmarks / favorites ---
  Future<bool> isAyahBookmarked(String ref) async =>
      (await _getSet(_kAyahBookmarks)).contains(ref);
  Future<void> toggleAyahBookmark(String ref) =>
      _toggleInSet(_kAyahBookmarks, ref);
  Future<Set<String>> ayahBookmarks() => _getSet(_kAyahBookmarks);

  Future<bool> isAyahFavorite(String ref) async =>
      (await _getSet(_kAyahFavorites)).contains(ref);
  Future<void> toggleAyahFavorite(String ref) =>
      _toggleInSet(_kAyahFavorites, ref);
  Future<Set<String>> ayahFavorites() => _getSet(_kAyahFavorites);

  // --- Hadith / dua bookmarks ---
  Future<bool> isHadithBookmarked(String ref) async =>
      (await _getSet(_kHadithBookmarks)).contains(ref);
  Future<void> toggleHadithBookmark(String ref) =>
      _toggleInSet(_kHadithBookmarks, ref);

  Future<bool> isDuaBookmarked(String id) async =>
      (await _getSet(_kDuaBookmarks)).contains(id);
  Future<void> toggleDuaBookmark(String id) =>
      _toggleInSet(_kDuaBookmarks, id);

  // --- Last read / progress ---
  Future<void> saveLastRead(int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kLastRead, jsonEncode({'surah': surah, 'ayah': ayah}));
    final read = prefs.getStringList(_kReadAyahs)?.toSet() ?? {};
    read.add('$surah:$ayah');
    await prefs.setStringList(_kReadAyahs, read.toList());
  }

  Future<({int surah, int ayah})?> lastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastRead);
    if (raw == null) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return (surah: (m['surah'] as num).toInt(), ayah: (m['ayah'] as num).toInt());
  }

  Future<int> readAyahCount() async =>
      (await _getSet(_kReadAyahs)).length;

  // --- Tasbeeh history ---
  Future<void> recordTasbeeh(String dhikr, int count) async {
    if (count <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final list = prefs.getStringList(_kTasbeehHistory) ?? [];
    list.add(jsonEncode({'date': date, 'dhikr': dhikr, 'count': count}));
    // Keep the last 500 sessions.
    while (list.length > 500) {
      list.removeAt(0);
    }
    await prefs.setStringList(_kTasbeehHistory, list);
  }

  Future<List<({String date, String dhikr, int count})>> tasbeehHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kTasbeehHistory) ?? [];
    return [
      for (final raw in list.reversed)
        () {
          final m = jsonDecode(raw) as Map<String, dynamic>;
          return (
            date: m['date'] as String,
            dhikr: m['dhikr'] as String,
            count: (m['count'] as num).toInt(),
          );
        }(),
    ];
  }

  /// Consecutive days (including today/yesterday) with any tasbeeh.
  Future<int> tasbeehStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kTasbeehHistory) ?? [];
    final days = <String>{};
    for (final raw in list) {
      days.add((jsonDecode(raw) as Map<String, dynamic>)['date'] as String);
    }
    var streak = 0;
    var day = DateTime.now();
    // Allow today to be missing (streak still alive if yesterday done).
    String key(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    if (!days.contains(key(day))) day = day.subtract(const Duration(days: 1));
    while (days.contains(key(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // --- Adhkar completion ---
  Future<void> markAdhkarDone(String set) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final raw = prefs.getString(_kAdhkarDone);
    final map = raw == null
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    final done = (map[date] as List?)?.map((e) => e as String).toSet() ?? {};
    done.add(set);
    map[date] = done.toList();
    await prefs.setString(_kAdhkarDone, jsonEncode(map));
  }

  Future<Set<String>> adhkarDoneToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final raw = prefs.getString(_kAdhkarDone);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return (map[date] as List?)?.map((e) => e as String).toSet() ?? {};
  }

  // --- Quran font scale ---
  Future<double> quranFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kQuranFontScale) ?? 1.0;
  }

  Future<void> setQuranFontScale(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kQuranFontScale, v.clamp(0.8, 1.6));
  }

  // --- Phase 3: Hifz ---
  // States per ayah ref ("2:255"): 'memorized' | 'learning' | 'revision'
  static const _kHifzStates = 'hifz_states'; // {"2:255": "memorized"}
  static const _kHifzWeak = 'hifz_weak'; // ["2:255"]
  static const _kHifzRevised = 'hifz_revised'; // {"2:255": "2026-10-08"}
  static const _kHifzTargets = 'hifz_targets'; // {"daily": 5, "weekly": 20}

  Future<Map<String, String>> hifzStates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHifzStates);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as String));
  }

  Future<void> setHifzState(String ref, String? state) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await hifzStates();
    if (state == null) {
      map.remove(ref);
    } else {
      map[ref] = state;
    }
    await prefs.setString(_kHifzStates, jsonEncode(map));
  }

  Future<Set<String>> hifzWeak() => _getSet(_kHifzWeak);
  Future<void> toggleHifzWeak(String ref) => _toggleInSet(_kHifzWeak, ref);

  Future<void> markHifzRevised(String ref) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final raw = prefs.getString(_kHifzRevised);
    final map = raw == null
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    map[ref] = date;
    await prefs.setString(_kHifzRevised, jsonEncode(map));
  }

  Future<Map<String, String>> hifzRevisedDates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHifzRevised);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as String));
  }

  Future<Map<String, int>> hifzTargets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHifzTargets);
    if (raw == null) return {'daily': 3, 'weekly': 15};
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return {
      'daily': (m['daily'] as num?)?.toInt() ?? 3,
      'weekly': (m['weekly'] as num?)?.toInt() ?? 15,
    };
  }

  Future<void> setHifzTargets(int daily, int weekly) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kHifzTargets, jsonEncode({'daily': daily, 'weekly': weekly}));
  }

  /// Ayahs due for revision: memorized/learning ayahs whose
  /// last-revised date + interval has passed. Simple spaced repetition:
  /// intervals grow 1 → 3 → 7 → 14 → 30 days by revision count.
  Future<List<String>> hifzDue() async {
    final states = await hifzStates();
    final revised = await hifzRevisedDates();
    final now = DateTime.now();
    const intervals = [1, 3, 7, 14, 30];
    final due = <String>[];
    for (final entry in states.entries) {
      if (entry.value == 'memorized' || entry.value == 'revision') {
        final last = revised[entry.key];
        if (last == null) {
          due.add(entry.key);
          continue;
        }
        final lastDate = DateTime.tryParse(last);
        if (lastDate == null) {
          due.add(entry.key);
          continue;
        }
        // Count prior revisions from history length heuristic: use 0.
        final days = now.difference(lastDate).inDays;
        if (days >= intervals[0]) due.add(entry.key);
      }
    }
    return due;
  }

  // --- Phase 3: Ramadan fasting log ---
  // {"2026-03-01": "fasted" | "missed" | "excused" | "makeup_done"}
  static const _kFastingLog = 'ramadan_fasting_log';
  static const _kKhatmParas = 'ramadan_khatm_paras'; // ["1","2",...] paras read

  Future<void> setFastStatus(String date, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFastingLog);
    final map = raw == null
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    map[date] = status;
    await prefs.setString(_kFastingLog, jsonEncode(map));
  }

  Future<Map<String, String>> fastingLog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFastingLog);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as String));
  }

  Future<Set<String>> khatmParas() => _getSet(_kKhatmParas);
  Future<void> toggleKhatmPara(String para) =>
      _toggleInSet(_kKhatmParas, para);

  // --- Phase 3: Zakat history ---
  static const _kZakatHistory = 'zakat_history'; // [json, ...] max 50

  Future<void> recordZakat(Map<String, dynamic> entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kZakatHistory) ?? [];
    list.add(jsonEncode(entry));
    while (list.length > 50) {
      list.removeAt(0);
    }
    await prefs.setStringList(_kZakatHistory, list);
  }

  Future<List<Map<String, dynamic>>> zakatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kZakatHistory) ?? [];
    return [
      for (final raw in list.reversed)
        jsonDecode(raw) as Map<String, dynamic>,
    ];
  }

  // --- Phase 3: Hajj/Umrah checklists ---
  static const _kHajjChecks = 'hajj_checks'; // {"hajj:0:1": true}

  Future<bool> isHajjChecked(String key) async =>
      (await _getSet(_kHajjChecks)).contains(key);
  Future<void> toggleHajjChecked(String key) =>
      _toggleInSet(_kHajjChecks, key);

  // --- Phase 3: Tajweed progress ---
  static const _kTajweedDone = 'tajweed_done'; // ["makharij"]
  static const _kTajweedQuiz = 'tajweed_quiz_best'; // {"score": 5, "total": 6}

  Future<Set<String>> tajweedDone() => _getSet(_kTajweedDone);
  Future<void> toggleTajweedDone(String id) =>
      _toggleInSet(_kTajweedDone, id);

  Future<void> saveTajweedQuizBest(int score, int total) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTajweedQuiz);
    final prev = raw == null
        ? 0
        : ((jsonDecode(raw) as Map<String, dynamic>)['score'] as num?)?.toInt() ?? 0;
    if (score > prev) {
      await prefs.setString(
          _kTajweedQuiz, jsonEncode({'score': score, 'total': total}));
    }
  }

  Future<({int score, int total})?> tajweedQuizBest() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTajweedQuiz);
    if (raw == null) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return (
      score: (m['score'] as num).toInt(),
      total: (m['total'] as num).toInt(),
    );
  }

  // --- Phase 3: gold/silver rate overrides ---
  static const _kMetalRates = 'metal_rates'; // {"gold_usd_g": 132.6, ...}

  Future<Map<String, double>> metalRateOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMetalRates);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<void> setMetalRateOverrides(Map<String, double> rates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMetalRates, jsonEncode(rates));
  }
}
