# Phase 4 — Intelligence & Personalization (v0.4.0)

**Date:** 8 October 2026
**Status:** Complete — `flutter analyze` clean, `flutter build web --release` verified.

## What was built

### 1. Noor AI (`lib/features/noor_ai/`, `lib/core/services/ai/`)
- **Chat UI** (`noor_ai_screen.dart`): message bubbles, language toggle
  (English / اردو / Roman Urdu / العربية), suggestion chips, persistent
  "AI answers are informational, not fatwa" disclaimer banner, per-answer
  source citations, About dialog.
- **Service** (`noor_ai_service.dart`): `NoorAiService` interface with
  `LocalNoorAiService` implementation. Answers ONLY from bundled verified
  datasets (Quran / Hadith / Dua repositories), in order: dua → hadith
  (Bukhari, then Muslim) → Quran. Feature intents (prayer, wudu, qibla,
  fasting, zakat, dhikr) point at the real in-app screens.
- **Safety rules (hard):** never invents verses/hadith/duas/rulings;
  says "I don't know — consult a qualified scholar" when nothing
  verified matches; **refuses personal fatwa** (halal/haram, divorce,
  inheritance) and directs to a qualified scholar. Every religious
  quote carries its source line (e.g. "Quran 2:255", "Sahih al-Bukhari · Hadith 1").
- **Integration point:** `RemoteNoorAiService` (OpenAI-compatible endpoint)
  documented, gated behind `NOOR_AI_API_URL` / `NOOR_AI_API_KEY` in
  `.env.example`. Even with a remote model, the local service remains
  the source-grounding layer per its docs.

### 2. Personal Dashboard (`lib/features/dashboard/`)
- Daily/weekly (7d) and monthly (30d) views with `fl_chart` bar charts:
  dhikr count, prayers logged, adhkar sets completed.
- Hifz pie chart (memorized / learning / revision), all-time totals
  (ayahs read, dhikr counted, fasts logged), dhikr streak card.
- Pull-to-refresh. **No leaderboards** — personal progress only.

### 3. Islamic Goals (`lib/features/goals/`)
- Create goals: prayers/day, ayahs read (cumulative), dhikr/day,
  adhkar sets/day, fasts (cumulative), ayahs memorized (cumulative).
- Progress bars, daily streaks (consecutive days meeting target),
  "goal met" state, per-goal daily reminder with time picker wired to
  the real notification service (reminder auto-cancelled on delete).
- Salah check-in (`_SalahCheckinCard` on the Prayer screen) feeds both
  dashboard and prayer goals.

### 4. Notifications (`lib/core/services/notifications/`)
- **Real implementation** (`LocalNotificationService`,
  flutter_local_notifications v22 + `timezone` + `flutter_timezone`):
  - `prayer_alarms` channel — max importance, alarm category,
    `adhan_placeholder` raw sound, `exactAllowWhileIdle`.
  - `reminders` channel — default importance, inexact scheduling.
  - tz database initialized and pinned to the device IANA zone, so
    alarms fire on wall-clock time.
  - Web/desktop → `DisabledNotificationService` (honest no-op).
- `PrayerAlarmScheduler`: reschedules 7 days of enabled-prayer alarms
  on app start and on settings change; skips past times.
- **Settings screen**: master toggle (requests OS permission),
  per-prayer toggles, daily ayah/hadith/dua reminders, quiet hours
  (23:00–04:30 default). **Quiet hours mute reminders only** —
  prayer alarms always fire when enabled (stated explicitly in the UI).
- **Adhan audio:** `assets/audio/adhan_placeholder.wav` is a synthesized
  3-note chime (NOT a real adhan). `assets/audio/README.md` documents
  replacing it with a licensed recording (both the asset and
  `android/.../res/raw/adhan_placeholder.wav`).
- **AndroidManifest:** `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`,
  `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE` +
  `ScheduledNotificationBootReceiver` for post-reboot rescheduling.

### 5. Cloud sync (`lib/core/services/sync/`)
- `LocalFirstSyncService`: the app is **fully usable without an
  account**. Export the entire on-device dataset as versioned JSON
  (share sheet / copy to clipboard); import restores it with a key
  count. Invalid files are rejected with a clear error.
- **Backup & sync screen** (More → Account): export / copy / import /
  documented cloud-sync notice.
- `SupabaseSyncService` documented as the future backend integration
  point (table schema + steps in the code comments; env vars in
  `.env.example`).

### Wiring & i18n
- Explore tab gains **Noor AI**, **Dashboard**, **Goals** tiles.
- More tab: Notifications → real settings screen; Account → backup screen.
- `main()` initializes services and reschedules prayer alarms on start.
- ~85 new strings in English + Urdu (`lib/l10n/strings.dart`).
- `TasbeehPresets` extracted to a shared file (single source of truth
  for the counter UI and Noor AI).
- Version bumped to `0.4.0+4`.

## Data-safety compliance
- No new religious content was authored: Noor AI quotes only dataset
  text; tasbeeh presets were moved, not invented; UI wrapper strings
  are interface text, never religious claims.
- All goals/dashboard numbers derive from existing user-data keys.

## Test results
- `flutter analyze` — **no issues**.
- `flutter build web --release` — **succeeded**.
- APK build remains environmentally blocked (Gradle needs localhost TCP,
  disabled in this sandbox) — do not retry here; use GitHub Actions.

## Known limitations / follow-ups
- Notification delivery timing must be re-verified on a physical device
  (exact alarms, Doze, OEM battery optimizers vary).
- Prayer alarm titles are English transliterations (scheduler has no
  BuildContext); localizing tray titles is a Phase 5 polish item.
- iOS: add the adhan sound file to the Runner target for custom sound.
- Cloud backend (Supabase/Firebase) + auth still to be implemented
  when the user wants accounts.
