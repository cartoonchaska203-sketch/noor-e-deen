# Noor-e-Deen — Phase 2 Notes

**Version:** 0.2.0+2 · **Date:** 8 Oct 2026
**Package:** `com.nooredeen.app` · **Stack:** Flutter 3.38.3 (stable), Dart 3.10.1

Phase 1 (foundation, prayer times, Qibla, themes) is documented in
PHASE1_NOTES.md. This file covers Phase 2: core Islamic content.

## What was built

### Data layer (`lib/data/`)
- `models/models.dart` — SurahMeta, Ayah, HadithEntry, Dua, DhikrItem,
  Wazifa, TasbeehRecord. Every religious item carries its source.
- `repositories/quran_repository.dart` — lazy asset loading, per-surah
  ayahs (Arabic+Urdu+English merged), global search (Arabic/English/Urdu),
  deterministic ayah-of-the-day, Juz→Surah:Ayah map (standard Madinah
  mushaf divisions).
- `repositories/hadith_repository.dart` — lazy collection loading,
  book list with counts, hadiths per book, text search, hadith-of-the-day.
  Empty-text entries filtered; grades shown only when present in data.
- `repositories/content_repository.dart` — duas (categories, search,
  dua-of-the-day), adhkar sets, wazaif.
- `repositories/user_data_repository.dart` — all on-device via
  shared_preferences: ayah bookmarks/favorites, hadith/dua bookmarks,
  last-read + read-ayah progress, tasbeeh history + streaks, adhkar
  completion, Quran font scale.

### Quran (`lib/features/quran/`)
- Surah list (114, searchable by name/number, Arabic names in Amiri Quran
  font), Juz' (1–30) index jumping to the right surah:ayah, Saved tab
  (bookmarks deep-link back into the reader).
- Reader: Arabic (Amiri Quran, RTL, 2.0 line height) + Urdu + English,
  per-ayah bookmark/favorite/copy/share, font-size slider (0.8–1.6x,
  persisted), Urdu/English toggles, reading progress bar, last-read
  auto-save on scroll, jump-to-ayah (from Juz/bookmarks/daily card).

### Hadith (`lib/features/hadith/`)
- Home: hadith-of-the-day card + collection picker (Sahih al-Bukhari,
  Sahih Muslim). Book/chapter list with hadith counts + book search.
- Hadith list per book with text search. Every card shows an
  **always-visible source line**: collection · book name/number ·
  hadith number · grade (or "Grade not listed in this edition").
  Bookmark / copy / share per hadith.

### Duas (`lib/features/duas/`)
- 30 curated duas across 14 categories, search, detail screen with
  Arabic + transliteration + Urdu + English (fields shown only when the
  dataset provides them — never invented), source badge, bookmark,
  copy/share.

### Wazaif (`lib/features/wazaif/`)
- 8 wazaif, each labeled Quranic verse / From hadith (no "general"
  items survived curation). Provenance badge, reference, repetitions,
  virtue note only where the dataset cites its hadith. Disclaimer that
  unverifiable items were excluded.

### Adhkar (`lib/features/adhkar/`)
- Morning (15) / Evening (12) / After Salah (8) sets. Tap-to-count
  cards with per-item progress, reps from source, source line,
  "mark set done" → daily completion persisted, done-today banner.

### Tasbeeh (`lib/features/tasbeeh/`)
- Big tap target with circular progress, 6 presets + custom dhikr,
  adjustable target, undo stack, vibration (with target-reached buzz),
  sound toggle, reset-and-save, history sheet, daily streak counter.

### Islamic calendar (`lib/features/calendar/`)
- Hijri month grid (Umm al-Qura-based `hijri` package), month
  navigation, today highlight, 9 key dates marked (Ramadan, Laylat
  al-Qadr, Eid al-Fitr, Arafah, Eid al-Adha, Ashura, Mawlid, Mi'raj,
  Shab-e-Barat) with an explicit moon-sighting disclaimer — estimated
  dates are never presented as certain.

### Wiring
- Explore tab is now a real feature grid (Hadith, Duas, Wazaif, Adhkar,
  Tasbeeh, Calendar) + honest Phase 3 roadmap badges.
- Home daily cards now show REAL content (ayah/hadith/dua of the day
  with full text) deep-linking into the reader/detail screens.
- 128 new localized strings (en + ur, RTL-safe). About/version updated
  to Phase 2 · v0.2.0.

## Data sources (full detail in assets/DATA_SOURCES.md)
| Content | Source | License/notes |
|---|---|---|
| Quran Arabic (Uthmani, diacritics) | fawazahmed0/quran-api (`ara-quranuthmanihaf`), Tanzil-derived | Community-verified transcription |
| Quran Urdu | same repo (`urd-muhammadjunagar`) — Muhammad Junagarhi | As attributed in dataset |
| Quran English | same repo (`eng-mustafakhattaba`) — Dr Mustafa Khattab, "The Clear Quran" | As attributed in dataset |
| Surah metadata | quran.com API v4 `/chapters` | Names, counts, revelation place |
| Hadith (Bukhari 7,589 / Muslim 7,563, English) | fawazahmed0/hadith-api (`eng-bukhari`, `eng-muslim`) | Translators per dataset index: Muhsin Khan / Abdul Hamid Siddiqui. Grades absent in these editions — UI says so honestly |
| Duas/Adhkar (30 + 35) | HsnSaboor/quran-api-toon (Hisnul Muslim transcription, 16 langs), cross-checked vs asellam/HisnElMuslim + dua-api + alquran.cloud | Arabic/Urdu/English copied verbatim; missing fields = null, never invented; `((`/`))` transcription markers stripped (text preserved) |
| Wazaif (8) | Quranic verses + sahih-hadith items from the same curation pass | Only verifiable items kept |
| Arabic font | Amiri Quran, google/fonts | SIL OFL — free to embed |

Bundled asset size: ~13 MB (quran ~3.8 MB, hadith ~8.8 MB, duas ~0.1 MB, font 0.14 MB). Fully offline.

## What's stubbed / deferred
| Item | Status | Target |
|---|---|---|
| Quran audio recitation | — | Phase 3+ (needs licensed audio) |
| Hadith Arabic/Urdu editions | Documented (ara-bukhari 9.4 MB, urd-bukhari 9.6 MB exist upstream) | On-demand download + cache, Phase 3+ |
| Other hadith collections (Abu Dawud, Tirmidhi, Nasa'i, Ibn Majah) | Same API supports them | Phase 3+ |
| Live sensor Qibla compass | Static bearing dial (Phase 1) | Phase 3+ |
| Prayer/Adhan notifications, auth, cloud sync | Stubs + docs (Phase 1) | Phase 4 |
| Ramadan, Salah guide, Hifz, Tajweed, Zakat, Hajj/Umrah | Roadmap badges in Explore | Phase 3 |

## Verification
- `flutter analyze` → **No issues found.**
- `flutter build web --release` → **succeeded** with all data assets
  bundled (verified in build output: quran/, hadith/, duas/adhkar/wazaif,
  AmiriQuran font).
- Data spot-checks: 114 surahs × 3 editions (2:286, 114:6 ✓); Arabic
  1:1 has diacritics ✓; Bukhari 7,589 hadiths, first = intentions
  hadith ✓; Muslim 7,563 (empty-text entries filtered in UI) ✓;
  30 duas / 35 adhkar / 8 wazaif, every item with a source ✓.
- `flutter build apk` → still blocked by the sandbox Java-TCP policy
  documented in PHASE1_NOTES.md (environmental, not a code issue).
  Run `flutter build apk --debug` on a normal machine to produce the APK.

## Religious-accuracy compliance
- Zero invented Quranic Arabic, translations, hadith text, dua wording,
  transliterations, or references — everything is verbatim from the
  datasets above; absent fields render as absent, never as guesses.
- Every hadith/dua/wazifa/adhkar displays its source; wazaif carry
  provenance labels; calendar estimates carry the moon-sighting
  disclaimer; hadith grades show "not listed in this edition" rather
  than invented grades.
- Transcription artifacts (`((`/`))`) were stripped without altering a
  single word of religious text.

## What's next (Phase 3)
Ramadan mode, Salah guide, Hifz tracker, Tajweed academy, Zakat
calculator, Hajj/Umrah guide — then Phase 4 (Noor AI, notifications,
cloud sync), Phase 5 (mosque finder, community), Phase 6 (production).
