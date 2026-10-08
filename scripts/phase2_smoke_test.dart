import 'dart:convert';
import 'dart:io';

// ignore_for_file: avoid_print

/// Runtime smoke test: verifies bundled JSON parses with the same logic
/// the repositories use (without needing Flutter's asset bundle).
void main() {
  // Quran
  for (final e in ['ara', 'urd', 'eng']) {
    final d = jsonDecode(File('assets/data/quran/quran_$e.json').readAsStringSync()) as Map<String, dynamic>;
    final surahs = d['surahs'] as Map<String, dynamic>;
    assert(surahs.length == 114, '$e: ${surahs.length} surahs');
    assert((surahs['2'] as Map).length == 286, '$e surah 2');
  }
  final meta = jsonDecode(File('assets/data/quran/surahs.json').readAsStringSync()) as List;
  assert(meta.length == 114, 'metadata: ${meta.length}');
  // Spot check: Arabic 1:1 has diacritics
  final ara = jsonDecode(File('assets/data/quran/quran_ara.json').readAsStringSync())['surahs']['1']['1'] as String;
  assert(ara.contains('بِسْمِ'), 'diacritics missing: $ara');

  // Hadith
  for (final f in ['bukhari_eng', 'muslim_eng']) {
    final d = jsonDecode(File('assets/data/hadith/$f.json').readAsStringSync()) as Map<String, dynamic>;
    final hadiths = d['hadiths'] as List;
    assert(hadiths.isNotEmpty, '$f empty');
    final nonEmpty = hadiths.where((h) => (h['text'] as String).trim().isNotEmpty).length;
    print('$f: ${hadiths.length} total, $nonEmpty non-empty');
  }
  final b0 = (jsonDecode(File('assets/data/hadith/bukhari_eng.json').readAsStringSync())['hadiths'] as List)[0];
  assert((b0['text'] as String).startsWith("Narrated 'Umar bin Al-Khattab"), 'bukhari #1 mismatch');

  // Duas / adhkar / wazaif
  final duas = jsonDecode(File('assets/data/duas.json').readAsStringSync()) as List;
  assert(duas.length == 30, 'duas: ${duas.length}');
  assert(duas.every((d) => (d['source'] as String).isNotEmpty), 'dua missing source');
  assert(duas.every((d) => !(d['arabic'] as String).contains('((')), 'dua marker remains');
  final adhkar = jsonDecode(File('assets/data/adhkar.json').readAsStringSync()) as Map<String, dynamic>;
  assert(adhkar.keys.toSet().containsAll(['morning', 'evening', 'after_salah']), 'adhkar sets');
  final wazaif = jsonDecode(File('assets/data/wazaif.json').readAsStringSync()) as List;
  assert(wazaif.every((w) => (w['reference'] as String).isNotEmpty), 'wazifa missing ref');
  assert(wazaif.every((w) => ['quran', 'hadith', 'general'].contains(w['type'])), 'wazifa bad type');

  // Font
  final magic = File('assets/fonts/AmiriQuran-Regular.ttf').readAsBytesSync().sublist(0, 4);
  assert(magic[0] == 0 && magic[1] == 1, 'font magic bad');

  print('ALL PHASE 2 DATA SMOKE TESTS PASSED');
}
