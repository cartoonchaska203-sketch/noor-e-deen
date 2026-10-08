import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/security/secure_prefs.dart';

/// Local Admin CMS (Phase 6).
///
/// A PIN-protected panel for the app owner to manage:
/// - Scholar directory: add/edit custom entries, mark verified ONLY
///   after a real credential check (never invent credentials).
/// - Video topics: add/edit/remove curated YouTube search topics.
/// - Content flags: hide individual duas / wazaif by ID.
/// - Feature toggles: enable/disable Explore tiles.
///
/// All data stays on-device (shared_preferences JSON). The admin PIN
/// itself is stored in the platform keychain via [SecurePrefs].
///
/// SERVER UPGRADE PATH: to run a shared backend, replace the
/// SharedPreferences reads/writes in this class with Supabase/Firebase
/// calls (see ADMIN_GUIDE.md). The screen code does not need to change.
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  static const _kScholars = 'admin_scholars'; // JSON list
  static const _kVideos = 'admin_videos'; // JSON list
  static const _kHidden = 'admin_hidden_content'; // ["dua:dua_05", ...]
  static const _kDisabledFeatures = 'admin_disabled_features'; // ["explore_video"]

  // --- PIN (delegates to secure storage) ---
  Future<bool> get hasPin => SecurePrefs.instance.hasAdminPin();
  Future<void> setPin(String pin) => SecurePrefs.instance.setAdminPin(pin);
  Future<bool> verifyPin(String pin) =>
      SecurePrefs.instance.verifyAdminPin(pin);

  // --- Custom scholars ---
  /// Each map: {id, name, specialization, region, verified(bool)}
  Future<List<Map<String, dynamic>>> customScholars() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kScholars);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveScholars(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kScholars, jsonEncode(list));
  }

  Future<void> upsertScholar(Map<String, dynamic> entry) async {
    final list = await customScholars();
    final i = list.indexWhere((e) => e['id'] == entry['id']);
    if (i >= 0) {
      list[i] = entry;
    } else {
      list.add(entry);
    }
    await saveScholars(list);
  }

  Future<void> deleteScholar(String id) async {
    final list = await customScholars();
    list.removeWhere((e) => e['id'] == id);
    await saveScholars(list);
  }

  // --- Custom video topics ---
  /// Each map: {id, title, query}
  Future<List<Map<String, dynamic>>> customVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kVideos);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveVideos(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVideos, jsonEncode(list));
  }

  Future<void> upsertVideo(Map<String, dynamic> entry) async {
    final list = await customVideos();
    final i = list.indexWhere((e) => e['id'] == entry['id']);
    if (i >= 0) {
      list[i] = entry;
    } else {
      list.add(entry);
    }
    await saveVideos(list);
  }

  Future<void> deleteVideo(String id) async {
    final list = await customVideos();
    list.removeWhere((e) => e['id'] == id);
    await saveVideos(list);
  }

  // --- Content visibility flags ---
  /// Keys look like "dua:dua_05" or "wazifa:wz_02".
  Future<Set<String>> hiddenContent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kHidden)?.toSet() ?? {};
  }

  Future<bool> isHidden(String type, String id) async =>
      (await hiddenContent()).contains('$type:$id');

  Future<void> setHidden(String type, String id, bool hidden) async {
    final prefs = await SharedPreferences.getInstance();
    final set = prefs.getStringList(_kHidden)?.toSet() ?? <String>{};
    if (hidden) {
      set.add('$type:$id');
    } else {
      set.remove('$type:$id');
    }
    await prefs.setStringList(_kHidden, set.toList());
  }

  // --- Feature toggles ---
  /// Explore tile keys, e.g. "explore_video". Absent = enabled.
  Future<Set<String>> disabledFeatures() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kDisabledFeatures)?.toSet() ?? {};
  }

  Future<bool> isFeatureEnabled(String tileKey) async =>
      !(await disabledFeatures()).contains(tileKey);

  Future<void> setFeatureEnabled(String tileKey, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final set =
        prefs.getStringList(_kDisabledFeatures)?.toSet() ?? <String>{};
    if (enabled) {
      set.remove(tileKey);
    } else {
      set.add(tileKey);
    }
    await prefs.setStringList(_kDisabledFeatures, set.toList());
  }

  // --- Export / import (backup) ---
  Future<String> exportJson() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'version': 1,
      'scholars': prefs.getString(_kScholars),
      'videos': prefs.getString(_kVideos),
      'hidden': prefs.getStringList(_kHidden),
      'disabledFeatures': prefs.getStringList(_kDisabledFeatures),
    };
    return jsonEncode(data);
  }

  /// Returns the number of restored sections, or throws on bad input.
  Future<int> importJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw const FormatException('Not an object');
    if (decoded['version'] != 1) throw const FormatException('Bad version');
    final prefs = await SharedPreferences.getInstance();
    var count = 0;
    if (decoded['scholars'] is String) {
      await prefs.setString(_kScholars, decoded['scholars'] as String);
      count++;
    }
    if (decoded['videos'] is String) {
      await prefs.setString(_kVideos, decoded['videos'] as String);
      count++;
    }
    if (decoded['hidden'] is List) {
      await prefs.setStringList(
          _kHidden, (decoded['hidden'] as List).cast<String>());
      count++;
    }
    if (decoded['disabledFeatures'] is List) {
      await prefs.setStringList(_kDisabledFeatures,
          (decoded['disabledFeatures'] as List).cast<String>());
      count++;
    }
    return count;
  }
}
