# Noor-e-Deen — Admin CMS Guide

**Version:** 1.0.0 · **Date:** 8 Oct 2026

## What the admin panel is

A PIN-protected content-management panel built into the app
(**More → Admin Panel**). It lets the app owner manage dynamic content
without shipping a new app version:

| Section | What it manages |
|---|---|
| Scholars | Add / edit / delete custom scholar directory entries; mark "verified" only after a real credential check |
| Video topics | Add / edit / delete curated YouTube search topics |
| Content visibility | Hide / show individual duas and wazaif |
| Feature toggles | Enable / disable Explore tiles |
| Export / Import | Backup all admin settings as JSON |
| Change PIN | Rotate the admin PIN |

## How it works (v1.0.0 — local)

- All admin data is stored **on-device** in SharedPreferences as JSON
  (see `lib/features/admin/admin_service.dart`).
- The admin **PIN** is stored in the platform keychain/keystore via
  `flutter_secure_storage` (never in plain text).
- 5 wrong PIN attempts → 60-second lockout (brute-force deterrent).
- Screens that consume admin data (`ScholarsScreen`, `VideoScreen`,
  `ExploreScreen`, `ContentRepository`) merge admin data with the
  bundled defaults at runtime.

### Data rules (non-negotiable)

1. **Never invent credentials.** The "verified" flag on a scholar may
   only be set after an independent, real credential check. The UI
   forces an explicit confirmation dialog stating this.
2. **Never invent religious content.** Video topics are YouTube *search
   queries* (never invented channel URLs). Hidden/show flags only
   toggle visibility of already-curated items.
3. Admin-added scholars are shown with the same "verify independently"
   notice as the starter list unless genuinely verified.

## Server CMS upgrade path

To run a shared backend (so one admin update reaches all users):

1. **Pick a backend:** Supabase (Postgres + Row Level Security) or
   Firebase (Firestore). Both are already documented as options in
   `.env.example` and `lib/core/services/auth/`.
2. **Schema** (one table/collection per section):
   - `admin_scholars`: id, name, specialization, region, verified,
     updated_at
   - `admin_videos`: id, title, query, updated_at
   - `admin_hidden_content`: content_key (e.g. "dua:dua_05")
   - `admin_disabled_features`: tile_key
3. **Replace the storage layer** in `AdminService`: swap the
   SharedPreferences reads/writes for Supabase/Firestore calls.
   The method signatures (`customScholars()`, `upsertScholar()`, …)
   stay the same, so **no screen code needs to change**.
4. **Add an `updated_at` poll:** on app start, fetch the server
   timestamp; if newer than the local cache, pull and overwrite.
5. **Secure the PIN:** move PIN verification server-side (e.g.
   Supabase Auth with an `admin` role) instead of a local PIN.
6. **Moderation queue:** the community "report" flags (currently
   recorded locally) should land in a server-side review collection
   for human moderation.

Until then, the local CMS is fully functional for a single-device
owner workflow, and export/import JSON makes device migration easy.
