import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/models.dart';

/// Curated dua / adhkar / wazaif datasets.
///
/// Every item carries its source; items without a verifiable source were
/// excluded at curation time (see assets/DATA_SOURCES.md).
class ContentRepository {
  ContentRepository._();
  static final ContentRepository instance = ContentRepository._();

  List<Dua>? _duas;
  Map<String, List<DhikrItem>>? _adhkar;
  List<Wazifa>? _wazaif;

  Future<List<Dua>> duas() async {
    if (_duas != null) return _duas!;
    final raw = await rootBundle.loadString('assets/data/duas.json');
    final list = jsonDecode(raw) as List;
    _duas = list.map((e) => Dua.fromJson(e as Map<String, dynamic>)).toList();
    return _duas!;
  }

  Future<List<String>> duaCategories() async {
    final all = await duas();
    final cats = <String>{};
    for (final d in all) {
      cats.add(d.category);
    }
    const order = [
      'morning',
      'evening',
      'salah',
      'sleep',
      'waking',
      'eating',
      'travel',
      'anxiety',
      'forgiveness',
      'protection',
      'parents',
      'rizq',
      'knowledge',
      'general',
    ];
    final sorted = cats.toList()
      ..sort((a, b) {
        final ia = order.indexOf(a), ib = order.indexOf(b);
        return (ia < 0 ? 999 : ia).compareTo(ib < 0 ? 999 : ib);
      });
    return sorted;
  }

  Future<List<Dua>> duasInCategory(String category) async {
    final all = await duas();
    return all.where((d) => d.category == category).toList();
  }

  Future<List<Dua>> searchDuas(String query) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return [];
    final all = await duas();
    return all
        .where((d) =>
            d.title.toLowerCase().contains(q) ||
            d.english?.toLowerCase().contains(q) == true ||
            d.arabic.contains(query.trim()))
        .take(100)
        .toList();
  }

  Future<Dua> duaOfTheDay(DateTime date) async {
    final all = await duas();
    final dayIndex = date.difference(DateTime(date.year, 1, 1)).inDays;
    return all[dayIndex % all.length];
  }

  Future<Map<String, List<DhikrItem>>> adhkar() async {
    if (_adhkar != null) return _adhkar!;
    final raw = await rootBundle.loadString('assets/data/adhkar.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _adhkar = {
      for (final e in decoded.entries)
        e.key: (e.value as List)
            .map((x) => DhikrItem.fromJson(x as Map<String, dynamic>))
            .toList(),
    };
    return _adhkar!;
  }

  Future<List<Wazifa>> wazaif() async {
    if (_wazaif != null) return _wazaif!;
    final raw = await rootBundle.loadString('assets/data/wazaif.json');
    final list = jsonDecode(raw) as List;
    _wazaif =
        list.map((e) => Wazifa.fromJson(e as Map<String, dynamic>)).toList();
    return _wazaif!;
  }
}
