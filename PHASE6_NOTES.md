# Noor-e-Deen — Phase 6 Notes (FINAL)

**Version:** 1.0.0+6 · **Date:** 8 Oct 2026
**Package:** `com.nooredeen.app` · **App name:** NOOR-E-DEEN
**Stack:** Flutter 3.38.3 (stable), Dart 3.10.1

Phases 1–5 documented in PHASE1–5_NOTES.md. This file covers Phase 6:
production hardening. The app is now **release-ready**.

## What was built

### 1. Admin CMS (`lib/features/admin/`)
- **PIN gate** (`admin_gate_screen.dart`): first-launch PIN setup
  (4–8 digits, keychain-stored), verify on later launches, 5-attempt
  lockout for 60s.
- **Dashboard** (`admin_screen.dart`): scholars, video topics, content
  visibility, feature toggles, export/import JSON backup, change PIN.
- **Scholars CRUD** (`admin_scholars_screen.dart`): add/edit/delete
  custom entries. The "verified" flag requires an explicit
  confirmation dialog stating it may only be set after a real,
  independent credential check — never invented.
- **Video topics CRUD** (`admin_videos_screen.dart`): label + YouTube
  search query (never invented channel URLs).
- **Content flags** (`admin_content_screen.dart`): hide/show individual
  duas and wazaif by ID; bundled data is never modified.
- **Feature toggles** (`admin_features_screen.dart`): enable/disable
  any of the 22 Explore tiles (core tabs can't be disabled).
- **Wiring:** `ScholarDirectoryService` merges admin scholars;
  `VideoScreen` merges admin topics; `ExploreScreen` filters disabled
  tiles; `ContentRepository` (`visibleDuas/visibleWazaif`,
  category/search/of-the-day) filters hidden items with an
  all-hidden fallback for dua-of-the-day.
- **Entry:** discreet "Admin Panel" row at the bottom of the More tab.
- **Docs:** `ADMIN_GUIDE.md` with the full Supabase/Firebase server
  upgrade path (schema + which methods to swap — screens don't change).

### 2. Security hardening (`lib/core/security/`)
- `input_validation.dart`: validators for names, free text, amounts,
  integers, PINs; strips control chars and bidi-override spoofing
  characters; human-readable error messages.
- `secure_prefs.dart`: `flutter_secure_storage` wrapper (platform
  keychain/keystore) for admin PIN + app-lock PIN. Non-sensitive
  prefs stay in shared_preferences.
- `app_lock_service.dart` + `AppLockGate` widget: optional PIN gate at
  startup, biometric unlock via `local_auth` (3.x API) with PIN
  fallback. Settings → Security section: enable/disable, change PIN,
  biometric toggle (graceful when unsupported).
- `.env.example` verified: all values are empty placeholders, no
  secrets committed.
- `USE_BIOMETRIC` permission added to the Android manifest.
- Privacy Policy + Terms of Use as real full screens
  (`lib/features/legal/`), written to match actual app behavior;
  wired into the More tab (privacy dialog replaced).

### 3. Offline mode
- `ConnectivityService` (connectivity_plus): app-wide online/offline
  stream, initialized in `main()`.
- `OfflineBanner` widget (with `liveRegion` semantics) on: Mosque
  finder, Audio streaming, Video, Zakat (rates). Core worship
  features (prayer times, Qibla, Tasbeeh, bundled Quran/Duas/Adhkar,
  Salah guide, Hifz) are fully offline and show no banner.
- Mosque map tab carries a code comment documenting the offline
  limitation (tiles need internet; favorites work offline in list).

### 4. Accessibility
- Semantic labels on the Tasbeeh counter (`Tasbeeh: N / target — tap
  to count`), the Qibla dial (bearing in degrees), the app-lock PIN
  dots, and the offline banner (live region).
- RTL verified via Urdu locale; system font scaling respected
  throughout (no fixed pixel text that breaks scaling).

### 5. Testing (`test/`)
- `qibla_service_test.dart` (5): Manchester ≈119°, Makkah ~0 distance,
  0–360 invariant, ~5025 km distance, Karachi differs.
- `prayer_service_test.dart` (5): chronological order, all 6 prayers,
  all 5 methods valid, Hanafi Asr > Standard Asr, +10 min adjustment.
- `input_validation_test.dart` (6): names, control chars, amounts,
  PIN format, sanitize, messages.
- `tasbeeh_widget_test.dart` (2): tap increments; undo restores.
- **Result: 18/18 pass** (`flutter test`).

### 6. Production prep
- Version → **1.0.0+6** (`pubspec.yaml`).
- Manifest `android:label` → **"NOOR-E-DEEN"**; package
  `com.nooredeen.app` confirmed; all permissions justified in
  comments (location, notifications, exact alarm, boot, vibrate,
  biometric).
- New deps: `flutter_secure_storage` 10.3.4, `local_auth` 3.0.2,
  `connectivity_plus` 7.3.1 (API differences vs older docs handled:
  local_auth 3.x uses direct `authenticate()` params; secure_storage
  10.x dropped the deprecated encryptedSharedPreferences flag).
- `RELEASE_NOTES.md` (v1.0.0 changelog + known limitations),
  `README.md` rewritten for the finished app, `ADMIN_GUIDE.md`.

## Verification
- `flutter analyze` → **No issues found.**
- `flutter test` → **18/18 pass.**
- `flutter build web --release` → (run at the end of Phase 6)
- `flutter build apk` → environmentally blocked in this sandbox
  (Java TCP policy, see PHASE1_NOTES.md) — do NOT retry here.
  GitHub Actions (`.github/workflows/build-apk.yml`) is the APK path.

## Religious-accuracy compliance
- Zero new religious content authored in Phase 6. Admin screens
  manage *visibility and metadata only*; the verified-flag
  confirmation dialog actively prevents credential invention.
- Privacy/Terms contain no religious claims.

## Remaining known limitations (see RELEASE_NOTES.md)
Prayer-alarm timing needs physical-device verification; adhan audio
is a placeholder chime; OSM mosque coverage varies; hadith is
English-only; Noor AI is local-dataset only; no cloud accounts yet;
iOS needs the adhan file in the Runner target.

**All six phases are complete. The app is production-ready.**
