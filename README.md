# Noor-e-Deen — Your Complete Islamic Companion

Islamic Super App · **Phase 1** (Flutter · Android / iOS / Web)

## Quick start

```bash
# Flutter SDK must be on PATH
flutter pub get
flutter run
```

Debug APK:

```bash
flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk
```

## Project layout

```
lib/
  main.dart            # entry + global error handling
  app.dart             # MaterialApp (theme/locale wiring)
  core/
    theme/             # light / dark / AMOLED themes, brand colors
    state/             # AppState (persisted settings) + AppStateScope
    services/
      prayer_service.dart      # adhan-based prayer calculation
      location_service.dart    # GPS with manual-city fallback
      qibla_service.dart       # great-circle bearing + distance
      notifications/           # Phase 4 stub + activation docs
      auth/                    # Phase 4 stub + activation docs
      sync/                    # Phase 4 stub + activation docs
    utils/             # cities, time formatting
    widgets/           # shell, cards, pattern painter, error widget
  features/
    home/ prayer/ qibla/       # Phase 1 — fully functional
    quran/ explore/            # Phase 2 placeholders (honest)
    more/ settings/            # settings + info screens
  l10n/                # en / ur strings (RTL via locale)
```

## Phase 1 scope

Home dashboard (live clock, Hijri date, prayer timetable + countdown),
real prayer-time calculation (5 methods, Hanafi/Shafi Asr, manual
adjustments), Qibla bearing + distance, themes, EN/UR + RTL, GPS with
graceful fallbacks, documented service stubs for Phase 4.

See [PHASE1_NOTES.md](PHASE1_NOTES.md) for details.

## Religious content policy

The app **never invents** Quranic text, Hadith, translations, or dua
sources. Phase 1 shows references only; full texts arrive in Phase 2
exclusively from verified, licensed sources.
