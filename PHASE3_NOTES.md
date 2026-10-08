# Noor-e-Deen — Phase 3 Notes

**Version:** 0.3.0+3 · **Date:** 8 Oct 2026
**Package:** `com.nooredeen.app` · **Stack:** Flutter 3.38.3 (stable), Dart 3.10.1

Phases 1–2 documented in PHASE1_NOTES.md / PHASE2_NOTES.md. This file
covers Phase 3: advanced worship modules.

## What was built

### Ramadan mode (`lib/features/ramadan/`)
- Auto-detects Ramadan via `HijriCalendar.now().hMonth == 9`; shows an
  honest "not Ramadan right now" state outside the month (features still
  usable for preparation).
- Sehri end = Fajr time and Iftar = Maghrib from the real
  `PrayerService` calculation (user's method/location/adjustments).
- Fasting tracker: per-day status (fasted / missed / excused / made-up),
  persisted in shared_preferences, with running totals.
- Taraweeh info card (8 vs 20 rak'ahs labeled by school, respectfully).
- Quran khatm planner: 30-para chip grid, auto plan
  (remaining paras ÷ estimated days left in the Hijri month).
- Laylat-ul-Qadr planner card (last-10 odd nights, Quran 97:3 cited).
- Charity card (full ledger deferred to Phase 5 — stated honestly).

### Salah guide (`lib/features/salah_guide/`)
- Wudu (9 steps, Bukhari 159), Ghusl (5 steps, Bukhari 248).
- All five prayers generated from one verified step skeleton with
  correct fard rak'ah counts (2/4/4/3/4) + Witr module.
- Arabic wordings with transliteration, translation and **hadith
  sources**: takbir, ruku/sujud dhikr (Muslim 772), sami'allahu /
  rabbana lakal-hamd (Bukhari 796), full Tashahhud (Bukhari 831),
  Durood-e-Ibrahim (Bukhari 3370), salam (Muslim 582), Rabbana Atina
  (Quran 2:201).
- Madhab differences labeled in gold "difference" boxes: Asr timing
  (matches the app's Asr toggle), Witr rak'ahs (Hanafi 3 wajib vs
  1/3/5 emphasized sunnah), hand positions, qunut.
- Copy/share per Arabic block.

### Hifz tracker (`lib/features/hifz/`)
- Per-ayah states (memorized / learning / revision), weak-ayah flag,
  "revised today" marking — all on-device.
- Hide/reveal self-test mode per surah (tap to reveal).
- Due list: simple spaced repetition (due 1 day after last revision;
  intervals 1→3→7→14→30 documented in repository).
- Stats tab: counts + `fl_chart` pie distribution + adjustable
  daily/weekly targets.
- Deep-links into the Phase 2 Quran reader at the exact ayah.

### Tajweed academy (`lib/features/tajweed/`)
- 5 lessons: Makharij, Noon Sakinah (4 rules), Meem Sakinah (3 rules),
  Madd, Qalqalah detail. Every rule has a **real Quranic example
  verified against the bundled dataset** (see verification below).
- 6-question MCQ quiz with explanations, best-score persistence,
  lesson completion tracking.
- Audio honestly stubbed: lessons carry an "audio needs licensed
  reciter recording" note instead of fake play buttons.

### Zakat calculator (`lib/features/zakat/`)
- Inputs: cash, bank, gold/silver grams, investments, business assets,
  receivables, liabilities. Nisab toggle: gold 87.48g / silver 612.36g.
- Rates: live fetch (`api.gold-api.com` XAU/XAG + `open.er-api.com`
  USD→GBP/PKR) with manual override, saved overrides, and
  clearly-labeled estimate fallbacks. Currency: GBP/USD/PKR.
- Itemized breakdown, 2.5% result, save-to-history (SQLite-style via
  shared_preferences, last 50).
- **Prominent disclaimer** (en+ur): informational estimate, consult a
  qualified scholar.

### Hajj & Umrah (`lib/features/hajj_umrah/`)
- Hajj: 12 rites (Ihram→Tawaf al-Wada) with the Talbiyah (Bukhari 1549)
  in Arabic + transliteration + translation; per-rite checklists with
  progress bar, all persisted.
- Umrah: 4 rites with checklists.
- 5 important warnings (permits, authorized groups, health, documents).
- Fully offline (all text bundled).

### Wiring & i18n
- Explore tab now shows all 12 features (6 Phase 2 + 6 Phase 3);
  the "Coming in Phase 3" badge section is retired.
- ~150 new localized strings, en + ur (RTL-safe).
- Version → 0.3.0+3; About/More screen version strings updated.
- New dependencies: `fl_chart` (Hifz charts), `http` (Zakat rates).

## Content verification (religious accuracy)
- **Tajweed examples verified programmatically** against
  `assets/data/quran/quran_ara.json` (diacritic-stripped search):
  Izhar أَنعَمتَ 1:7 ✓ · Idgham مَن يَقُولُ 2:8 ✓ ·
  Iqlab أَنبِئهُم 2:33 ✓ · Ikhfa مِن شَرِّ 113:2 ✓ ·
  Ikhfa Shafawi هُم بِهِ 9:55 ✓ · Idgham Shafawi لَكُم مَّا 2:29 ✓ ·
  Izhar Shafawi عَلَيْهِمْ غَيْرِ 1:7 ✓ · Madd الضَّالِّين 1:7 ✓ ·
  Qalqalah قُلْ 113:1, أَحَدٌ 112:1 ✓. Exact diacritized snippets
  extracted from the dataset for display.
- Prayer Arabic (tashahhud, durood, talbiyah, dhikr phrases) are the
  universally-memorized wordings with their hadith sources cited;
  nothing was paraphrased or invented.
- Wudu/ghusl/Hajj/Umrah steps describe undisputed standard practice;
  all madhab differences are labeled, never presented as the only
  position.

## Verification
- `flutter analyze` → **No issues found.**
- `flutter build web --release` → **succeeded** (116s).
- `flutter build apk` → still environmentally blocked (sandbox
  Java-TCP policy, see PHASE1_NOTES.md). GitHub Actions workflow is
  the delivery path for APKs.

## What's next (Phase 4)
Noor AI (source-grounded), prayer/Adhan notifications, personal
dashboard, goals, cloud sync — then Phase 5 (mosque finder, family
mode, charity ledger, audio/video, community), Phase 6 (production).
