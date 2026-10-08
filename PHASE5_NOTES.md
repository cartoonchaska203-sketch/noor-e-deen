# Noor-e-Deen — Phase 5 Notes

**Version:** 0.5.0+5 · **Date:** 8 Oct 2026
**Package:** `com.nooredeen.app` · **Stack:** Flutter 3.38.3 (stable), Dart 3.10.1

Phases 1–4 documented in PHASE1–4_NOTES.md. This file covers Phase 5:
community & ecosystem.

## What was built

### Mosque finder (`lib/features/mosques/`, `lib/core/services/mosques/`)
- `OverpassMosqueService` queries the **free OpenStreetMap Overpass API**
  (no key): `amenity=place_of_worship` + `religion=muslim` (plus a
  name-match fallback for untagged musallas) within 8 km, with a
  fallback mirror endpoint if the main instance is busy.
- List tab: distance-sorted (haversine), address + opening hours when
  OSM provides them, favorite toggle (persisted), directions button
  (`geo:` URI → system maps app).
- Map tab: `flutter_map` + OpenStreetMap tiles, user marker + mosque
  markers (tap marker → directions). GPS via existing
  `LocationService` with manual-city fallback and honest banner.
- `GOOGLE_PLACES_API_KEY` documented in `.env.example` as the optional
  richer-data upgrade; the Overpass path stays default.

### Family mode (`lib/features/family/`)
- Optional private family space, **100% on-device** (shared_preferences).
  Create group → add members (name + relation) → log daily activity
  (prayers / ayahs / dhikr) → per-member latest-day summary.
- Privacy-first notice on screen: no accounts, no servers, nothing
  leaves the phone. Group deletion wipes local data.

### Charity tracker (`lib/features/charity/`)
- Ledger: zakat / sadaqah / donation entries (amount, currency
  GBP/USD/PKR/EUR, date, optional recipient + note), swipe-to-delete.
- This-month + this-year totals, 6-month bar chart (`fl_chart`),
  per-type yearly goals with progress bars.
- All persisted on-device (last 1000 entries).

### Islamic audio (`lib/features/audio/`)
- Quran recitation streaming from **everyayah.com** (public Quran audio
  CDN, no key): 5 well-known reciters, surah picker (114, from bundled
  metadata), ayah-by-ayah playback via `just_audio`
  (`setAudioSources`), play/pause/next/prev/stop + ayah indicator.
- Source disclosed in-app; streaming needs internet (stated).
- Dua/adhkar audio: honest "licensed recordings pending" card —
  no fake play buttons.

### Video / education (`lib/features/video/`)
- Curated topic list (sermons, Seerah, tafseer, tajweed, prayer guide…).
  Opens **YouTube search URLs** (never invented channel URLs) in the
  external app via `url_launcher`. "Verify the speaker independently"
  on every row + curation disclaimer.

### Scholar directory (`lib/features/scholars/`)
- `ScholarDirectoryService` interface + starter list of 6 widely-known
  **public figures** with general specialization labels only.
- **No credentials, titles, degrees or affiliations stated anywhere.**
  Every row: "Public figure — verify independently." `verified` flag
  exists but is false for all until a Phase 6 CMS performs real checks
  (`fetchVerified()` returns null until then — documented).

### Community (`lib/features/community/`)
- Local-first study circles: create (Quran/Hifz/study/charity),
  add members, shared goal, log progress units, per-circle totals,
  delete. All on-device.
- Safety tab: **no-fatwa notice**, moderation policy (reports recorded
  locally; server review queue is Phase 6), local-first privacy note.
- Report UI per member (spam / unverified claim / other) records a
  local flag with a snackbar; the server-side design is documented in
  code comments, not faked.

### Wiring & i18n
- Explore tab: 7 new tiles (Mosques, Family, Charity, Audio, Videos,
  Scholars, Community) → 22 features total.
- ~110 new localized strings, en + ur (RTL-safe).
- `UserDataRepository` extended: mosque favorites, family group +
  activity, charity entries + goals, community circles + progress.
- New deps: `flutter_map` 8.3.2, `latlong2` 0.10.1, `just_audio`
  0.10.6, `url_launcher` 6.3.2.
- Version → 0.5.0+5.

## Religious-accuracy compliance
- Zero invented religious text: audio streams third-party recitation
  (not generated); video links out (not embedded claims); scholars are
  public figures with no credential claims; community forbids
  presenting unverified rulings.
- The 5 large data assets (Quran/Hadith JSONs) are unchanged from
  Phase 2; no new religious content was authored.

## Verification
- `flutter analyze` → **No issues found** (fixed: latlong2 import path,
  ErrorView retryLabel, just_audio/DropdownButtonFormField deprecations,
  async-context lints).
- `flutter build web --release` → **succeeded**.
- `flutter build apk` → still environmentally blocked (sandbox
  Java-TCP policy, see PHASE1_NOTES.md). GitHub Actions is the APK path.

## Known limitations / follow-ups
- Overpass API can be slow or rate-limited; the UI surfaces errors
  honestly with retry. OSM mosque coverage varies by region.
- flutter_map tiles need internet; offline map packs are a Phase 6
  optimization.
- just_audio on web: playback works; the position slider is hidden on
  web (platform limitation noted in code).
- Notification tray titles for prayer alarms remain English
  (Phase 4 known limitation, unchanged).

## What's next (Phase 6)
Admin CMS, security hardening, accessibility pass, offline mode,
performance optimization, full testing, production APK/AAB.
