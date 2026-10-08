import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/models.dart';

/// Loads bundled Hadith collections (fawazahmed0/hadith-api editions,
/// see assets/DATA_SOURCES.md).
///
/// Collections load lazily (each ~5 MB JSON) with a loading state in UI.
class HadithRepository {
  HadithRepository._();
  static final HadithRepository instance = HadithRepository._();

  final Map<String, _Collection> _cache = {};

  static const _collections = {
    'bukhari': ('assets/data/hadith/bukhari_eng.json', 'Sahih al-Bukhari'),
    'muslim': ('assets/data/hadith/muslim_eng.json', 'Sahih Muslim'),
  };

  Future<List<String>> availableCollections() async {
    final out = <String>[];
    for (final id in _collections.keys) {
      try {
        await _load(id);
        out.add(id);
      } catch (_) {
        // Asset missing — collection simply not offered.
      }
    }
    return out;
  }

  String collectionName(String id) => _collections[id]?.$2 ?? id;

  Future<_Collection> _load(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;
    final spec = _collections[id];
    if (spec == null) throw StateError('Unknown collection $id');
    final raw = await rootBundle.loadString(spec.$1);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final meta = decoded['metadata'] as Map<String, dynamic>;
    final sections = (meta['sections'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(int.parse(k), v as String),
    );
    final hadiths = (decoded['hadiths'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final col = _Collection(
      id: id,
      name: spec.$2,
      sections: sections,
      hadiths: hadiths,
    );
    _cache[id] = col;
    return col;
  }

  /// Book list: (bookNumber, bookName, hadithCount).
  Future<List<({int number, String name, int count})>> books(
      String collectionId) async {
    final col = await _load(collectionId);
    final counts = <int, int>{};
    for (final h in col.hadiths) {
      final ref = h['reference'] as Map<String, dynamic>;
      final b = (ref['book'] as num).toInt();
      counts[b] = (counts[b] ?? 0) + 1;
    }
    return [
      for (final n in col.sections.keys.toList()..sort())
        (
          number: n,
          name: col.sections[n] ?? 'Book $n',
          count: counts[n] ?? 0,
        ),
    ];
  }

  Future<List<HadithEntry>> hadithsInBook(
      String collectionId, int bookNumber) async {
    final col = await _load(collectionId);
    final out = <HadithEntry>[];
    for (final h in col.hadiths) {
      final ref = h['reference'] as Map<String, dynamic>;
      if ((ref['book'] as num).toInt() != bookNumber) continue;
      out.add(_toEntry(col, h));
    }
    out.sort((a, b) => a.hadithNumber.compareTo(b.hadithNumber));
    return out;
  }

  Future<List<HadithEntry>> search(String collectionId, String query) async {
    final q = query.trim().toLowerCase();
    if (q.length < 3) return [];
    final col = await _load(collectionId);
    final out = <HadithEntry>[];
    for (final h in col.hadiths) {
      final text = (h['text'] as String).toLowerCase();
      if (text.contains(q)) {
        out.add(_toEntry(col, h));
        if (out.length >= 100) break;
      }
    }
    return out;
  }

  /// Deterministic "hadith of the day".
  Future<HadithEntry> hadithOfTheDay(DateTime date) async {
    final col = await _load('bukhari');
    final dayIndex = date.difference(DateTime(date.year, 1, 1)).inDays;
    final h = col.hadiths[dayIndex % col.hadiths.length];
    return _toEntry(col, h);
  }

  HadithEntry _toEntry(_Collection col, Map<String, dynamic> h) {
    final ref = h['reference'] as Map<String, dynamic>;
    final bookNumber = (ref['book'] as num).toInt();
    final grades = ((h['grades'] as List?) ?? [])
        .map((g) => (g as Map<String, dynamic>)['grade']?.toString() ?? '')
        .where((g) => g.isNotEmpty)
        .toList();
    return HadithEntry(
      collection: col.id,
      collectionName: col.name,
      bookNumber: bookNumber,
      bookName: col.sections[bookNumber] ?? 'Book $bookNumber',
      hadithNumber: (h['hadithnumber'] as num).toInt(),
      text: h['text'] as String,
      grades: grades,
    );
  }
}

class _Collection {
  _Collection({
    required this.id,
    required this.name,
    required this.sections,
    required this.hadiths,
  });

  final String id;
  final String name;
  final Map<int, String> sections;
  final List<Map<String, dynamic>> hadiths;
}
