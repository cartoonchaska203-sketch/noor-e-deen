# Noor-e-Deen — Release Notes v1.0.0+6

**Release date:** 8 October 2026
**Package:** `com.nooredeen.app` · **App name:** NOOR-E-DEEN
**Tagline:** Your Complete Islamic Companion

This is the first production release, completing all six build phases.

## What's in v1.0.0

### Worship
- **Prayer times** — real offline calculation (Muslim World League,
  Umm al-Qura, Egyptian, Karachi, ISNA), Standard/Hanafi Asr, GPS +
  manual city, per-prayer adjustments, next-prayer countdown
- **Qibla** — great-circle bearing + distance to Makkah, compass dial
- **Prayer alarms & reminders** — exact-alarm notifications per prayer,
  daily ayah/hadith/dua reminders, quiet hours (prayer alarms always fire)
- **Salah guide** — wudu, ghusl, all five prayers + witr with sourced
  Arabic, transliteration, translation; madhab differences labeled
- **Ramadan mode** — auto-detects Ramadan; sehri/iftar, fasting tracker,
  khatm planner, Laylat-ul-Qadr planner

### Quran & learning
- **Quran** — 114 surahs, Arabic (Uthmani) + Urdu + English, search,
  bookmarks, reading progress, Juz' index — fully offline
- **Hadith** — Sahih al-Bukhari & Sahih Muslim (English), book/chapter
  browser, search, always-visible source lines
- **Hifz tracker** — per-ayah states, hide/reveal self-test, spaced
  repetition due list, progress charts
- **Tajweed academy** — 5 lessons with dataset-verified examples + quiz
- **Noor AI** — source-grounded Q&A (answers only from bundled verified
  content; refuses personal fatwas; "not a fatwa" disclaimer)

### Daily practice
- **Duas** (30, sourced) · **Wazaif** (8, provenance-labeled) ·
  **Adhkar** (morning/evening/after-salah sets) · **Tasbeeh** (counter,
  presets, targets, streaks, history)
- **Islamic calendar** — Hijri month grid with moon-sighting disclaimer
- **Zakat calculator** — live + manual metal/FX rates, nisab toggle,
  history, scholar-consultation disclaimer
- **Hajj & Umrah** — step-by-step rites with checklists, Talbiyah,
  warnings — fully offline

### Community & lifestyle
- **Mosque finder** — nearby mosques via OpenStreetMap (no key needed),
  list + map, favorites, directions
- **Family mode** — private on-device family worship tracking
- **Charity tracker** — zakat/sadaqah ledger with goals and charts
- **Audio** — Quran recitation streaming (5 reciters)
- **Videos** — curated educational topics (links out to YouTube)
- **Scholar directory** — public figures, no invented credentials
- **Community** — local-first study circles with safety policy

### Personalization
- **Dashboard** — worship stats and streaks (no leaderboards)
- **Goals** — 6 goal types with reminders
- **Noor AI** chat in English / اردو / Roman Urdu / العربية
- Light / Dark / **AMOLED** themes; **English + Urdu (RTL)**

### Platform (Phase 6)
- **Admin CMS** — PIN-protected panel: scholars, video topics, content
  visibility, feature toggles, export/import
- **App lock** — optional PIN + biometric gate at startup
- **Privacy Policy & Terms** — honest, app-accurate legal screens
- **Offline mode** — clear offline banners on network features;
  core worship features work fully offline
- **Accessibility** — semantic labels on key widgets, RTL verified,
  system font scaling respected
- **Security** — PINs in platform keychain, input validation on all
  user inputs, no hardcoded secrets

## Known limitations

1. **Prayer alarm timing** must be re-verified on physical devices
   (exact alarms, Doze mode, and OEM battery optimizers vary).
2. **Adhan audio** is a synthesized placeholder chime; replace
   `assets/audio/adhan_placeholder.wav` with a licensed recording
   (see `assets/audio/README.md`).
3. **Mosque data** depends on OpenStreetMap coverage and needs
   internet; offline map tiles are not bundled.
4. **Hadith** is English-only in this release (Arabic/Urdu editions
   documented for on-demand download in a future update).
5. **Noor AI** answers from the local dataset only; the remote-LLM
   integration point is documented but not activated.
6. **Cloud sync / accounts** are not implemented; backup is via
   local JSON export/import.
7. **iOS**: add the adhan sound file to the Runner target for custom
   notification sound.

## Build

- `flutter analyze` — no issues
- `flutter build web --release` — succeeds
- `flutter test` — 18/18 pass
- Android APK/AAB: built via GitHub Actions
  (`.github/workflows/build-apk.yml`)
- R8/ProGuard: Flutter's default release shrinking applies
  (tree-shaking + resource shrinking via the Flutter Gradle plugin).

## Religious-accuracy statement

No Quranic text, hadith, dua wording, translation, or reference was
invented or altered in this app. Every religious item carries its
source. Estimates (Hijri dates, Zakat) are labeled as estimates.
Noor AI refuses personal fatwas. See `assets/DATA_SOURCES.md`.
