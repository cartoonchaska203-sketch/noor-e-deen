import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/models.dart';

/// Loads the bundled Quran datasets (Tanzil-derived Uthmani Arabic +
/// Junagarhi Urdu + Khattab English, see assets/DATA_SOURCES.md).
///
/// Everything is bundled for full offline use. Data loads lazily per
/// edition and is cached in memory.
class QuranRepository {
  QuranRepository._();
  static final QuranRepository instance = QuranRepository._();

  List<SurahMeta>? _surahs;
  final Map<String, Map<String, Map<String, String>>> _editions = {};

  static const _paths = {
    'ara': 'assets/data/quran/quran_ara.json',
    'urd': 'assets/data/quran/quran_urd.json',
    'eng': 'assets/data/quran/quran_eng.json',
  };

  Future<List<SurahMeta>> surahs() async {
    if (_surahs != null) return _surahs!;
    final raw = await rootBundle.loadString('assets/data/quran/surahs.json');
    final list = jsonDecode(raw) as List;
    _surahs = list
        .map((e) => SurahMeta.fromJson(e as Map<String, dynamic>))
        .toList();
    return _surahs!;
  }

  Future<Map<String, Map<String, String>>> _edition(String code) async {
    final cached = _editions[code];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_paths[code]!);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final surahs = decoded['surahs'] as Map<String, dynamic>;
    final result = <String, Map<String, String>>{};
    for (final entry in surahs.entries) {
      final ayahs = entry.value as Map<String, dynamic>;
      result[entry.key] = {
        for (final a in ayahs.entries) a.key: a.value as String,
      };
    }
    _editions[code] = result;
    return result;
  }

  /// Ayahs of one surah with all three texts merged.
  Future<List<Ayah>> ayahs(int surahId) async {
    final results = await Future.wait([
      _edition('ara'),
      _edition('urd'),
      _edition('eng'),
    ]);
    final key = surahId.toString();
    final ara = results[0][key] ?? {};
    final urd = results[1][key] ?? {};
    final eng = results[2][key] ?? {};
    final numbers = ara.keys
        .map(int.parse)
        .toList()
      ..sort();
    return [
      for (final n in numbers)
        Ayah(
          surah: surahId,
          number: n,
          arabic: ara[n.toString()] ?? '',
          urdu: urd[n.toString()] ?? '',
          english: eng[n.toString()] ?? '',
        ),
    ];
  }

  /// Search across Arabic + English (+ Urdu) text. Loads editions into
  /// memory on first use (~5 MB total — fine on modern devices).
  Future<List<Ayah>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];
    final results = await Future.wait([
      _edition('ara'),
      _edition('urd'),
      _edition('eng'),
    ]);
    final ara = results[0], urd = results[1], eng = results[2];
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(q);
    final matches = <Ayah>[];
    for (final sKey in ara.keys) {
      final sId = int.parse(sKey);
      final aMap = ara[sKey]!, uMap = urd[sKey] ?? {}, eMap = eng[sKey] ?? {};
      for (final aKey in aMap.keys) {
        final hit = isArabic
            ? aMap[aKey]!.contains(q)
            : (eMap[aKey]?.toLowerCase().contains(q.toLowerCase()) ?? false) ||
                (uMap[aKey]?.contains(q) ?? false);
        if (hit) {
          matches.add(Ayah(
            surah: sId,
            number: int.parse(aKey),
            arabic: aMap[aKey]!,
            urdu: uMap[aKey] ?? '',
            english: eMap[aKey] ?? '',
          ));
          if (matches.length >= 200) return matches;
        }
      }
    }
    return matches;
  }

  /// Deterministic "ayah of the day" from the day-of-year.
  /// Deterministic "ayah of the day" from the day-of-year.
  Future<Ayah> ayahOfTheDay(DateTime date) async {
    await surahs();
    final dayIndex = date.difference(DateTime(date.year, 1, 1)).inDays;
    // Cycle through a fixed set of well-known short surahs for the daily card.
    const picks = [112, 113, 114, 1, 108, 109, 110, 111, 94, 93];
    final surahId = picks[dayIndex % picks.length];
    final list = await ayahs(surahId);
    final ayahIndex = dayIndex % list.length;
    final a = list[ayahIndex];
    return Ayah(
      surah: surahId,
      number: a.number,
      arabic: a.arabic,
      urdu: a.urdu,
      english: a.english,
    );
  }

  /// Juz (Para) → starting surah:ayah, standard Madinah mushaf division.
  static const Map<int, List<int>> juzStarts = {
    1: [1, 1], 2: [2, 142], 3: [2, 253], 4: [3, 93], 5: [4, 24],
    6: [4, 148], 7: [5, 82], 8: [6, 111], 9: [7, 88], 10: [8, 41],
    11: [9, 93], 12: [11, 6], 13: [12, 53], 14: [15, 1], 15: [17, 1],
    16: [18, 75], 17: [21, 1], 18: [23, 1], 19: [25, 21], 20: [27, 56],
    21: [29, 46], 22: [33, 31], 23: [36, 28], 24: [39, 32], 25: [41, 47],
    26: [46, 1], 27: [51, 31], 28: [58, 1], 29: [67, 1], 30: [78, 1],
  };
}
