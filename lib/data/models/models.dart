/// Data models for Phase 2 religious content.
///
/// All text in these models comes from verified bundled datasets
/// (see assets/DATA_SOURCES.md). Nothing here is generated.
library;
/// Metadata for one surah.
class SurahMeta {
  const SurahMeta({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.versesCount,
    required this.revelation,
    required this.meaning,
  });

  final int id;
  final String name;
  final String arabicName;
  final int versesCount;
  final String revelation; // 'makkah' | 'madinah'
  final String meaning;

  factory SurahMeta.fromJson(Map<String, dynamic> j) => SurahMeta(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        arabicName: j['arabic'] as String,
        versesCount: (j['verses'] as num).toInt(),
        revelation: j['revelation'] as String,
        meaning: j['meaning'] as String,
      );
}

/// One ayah with its translations.
class Ayah {
  const Ayah({
    required this.surah,
    required this.number,
    required this.arabic,
    required this.urdu,
    required this.english,
  });

  final int surah;
  final int number;
  final String arabic;
  final String urdu;
  final String english;

  String get ref => '$surah:$number';
}

/// One hadith entry with full source metadata.
class HadithEntry {
  const HadithEntry({
    required this.collection,
    required this.collectionName,
    required this.bookNumber,
    required this.bookName,
    required this.hadithNumber,
    required this.text,
    required this.grades,
  });

  final String collection; // e.g. 'bukhari'
  final String collectionName; // e.g. 'Sahih al-Bukhari'
  final int bookNumber;
  final String bookName;
  final int hadithNumber;
  final String text;
  final List<String> grades;

  /// Human-readable source line, always shown with the hadith.
  String get sourceLine {
    final grade = grades.isEmpty
        ? 'Grade not listed in this edition'
        : 'Grade: ${grades.join(', ')}';
    return '$collectionName · Book $bookNumber ($bookName) · Hadith $hadithNumber · $grade';
  }
}

/// One dua with its source.
class Dua {
  const Dua({
    required this.id,
    required this.category,
    required this.title,
    required this.arabic,
    this.transliteration,
    this.urdu,
    this.english,
    required this.source,
  });

  final String id;
  final String category;
  final String title;
  final String arabic;
  final String? transliteration;
  final String? urdu;
  final String? english;
  final String source;

  factory Dua.fromJson(Map<String, dynamic> j) => Dua(
        id: j['id'] as String,
        category: j['category'] as String,
        title: j['title'] as String,
        arabic: j['arabic'] as String,
        transliteration: j['transliteration'] as String?,
        urdu: j['urdu'] as String?,
        english: j['english'] as String?,
        source: j['source'] as String,
      );
}

/// One dhikr item inside an adhkar set.
class DhikrItem {
  const DhikrItem({
    required this.arabic,
    this.transliteration,
    this.urdu,
    this.english,
    required this.reps,
    required this.source,
  });

  final String arabic;
  final String? transliteration;
  final String? urdu;
  final String? english;
  final int reps;
  final String source;

  factory DhikrItem.fromJson(Map<String, dynamic> j) => DhikrItem(
        arabic: j['arabic'] as String,
        transliteration: j['transliteration'] as String?,
        urdu: j['urdu'] as String?,
        english: j['english'] as String?,
        reps: (j['reps'] as num).toInt(),
        source: j['source'] as String,
      );
}

/// One wazifa. Type marks provenance:
/// 'quran'  — a Quranic verse (reading it is worship; no extra claim),
/// 'hadith' — a dhikr/verse with a virtue stated ONLY with its hadith ref,
/// 'general'— permissible devotional practice, no specific virtue claimed.
class Wazifa {
  const Wazifa({
    required this.id,
    required this.title,
    required this.type,
    this.arabic,
    required this.reference,
    this.reps,
    this.note,
  });

  final String id;
  final String title;
  final String type;
  final String? arabic;
  final String reference;
  final int? reps;
  final String? note;

  factory Wazifa.fromJson(Map<String, dynamic> j) => Wazifa(
        id: j['id'] as String,
        title: j['title'] as String,
        type: j['type'] as String,
        arabic: j['arabic'] as String?,
        reference: j['reference'] as String,
        reps: (j['reps'] as num?)?.toInt(),
        note: j['note'] as String?,
      );
}

/// A tasbeeh session record for history/streaks.
class TasbeehRecord {
  const TasbeehRecord({
    required this.date, // yyyy-MM-dd
    required this.dhikr,
    required this.count,
  });

  final String date;
  final String dhikr;
  final int count;
}
