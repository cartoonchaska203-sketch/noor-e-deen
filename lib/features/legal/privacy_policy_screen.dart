import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

/// Privacy Policy (Phase 6).
///
/// Written to match what the app ACTUALLY does (v1.0.0):
/// - Everything is stored on-device (shared_preferences + keychain).
/// - No account, no analytics, no ads SDK, no tracking.
/// - Network calls: mosque search (OpenStreetMap Overpass), Quran audio
///   streaming (everyayah.com), Zakat metal/FX rates, YouTube links
///   (external app). No personal data is sent with these requests.
/// - Optional future cloud sync is documented as opt-in.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'legal_privacy_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'Noor-e-Deen — Privacy Policy',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Last updated: 8 October 2026 · Version 1.0.0',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _section(context, '1. Data stays on your device',
              'Noor-e-Deen is designed to work without an account. Your prayer settings, Quran bookmarks, hadith bookmarks, tasbeeh history, hifz progress, goals, family data, charity ledger, community circles, and admin settings are stored only on your device using the app\'s local storage. We do not operate servers that receive this data.'),
          _section(context, '2. No analytics, no ads, no tracking',
              'The app contains no advertising SDK, no analytics SDK, and no cross-app tracking. We do not collect device identifiers for advertising.'),
          _section(context, '3. Location',
              'If you enable GPS mode, your location is used only on-device to calculate prayer times, Qibla direction, and nearby mosques. Your coordinates are never sent to us. Mosque search sends your approximate coordinates to the OpenStreetMap Overpass API (a public, third-party service) to find nearby mosques — see their privacy policy for how they handle requests.'),
          _section(context, '4. Network features',
              'Some features need the internet: mosque search (OpenStreetMap), Quran audio streaming (everyayah.com public CDN), live gold/silver and currency rates for the Zakat calculator (public rate APIs), and educational video links (opened in the YouTube app). These requests go directly from your device to those third-party services; we do not proxy or log them. The Zakat calculator\'s rate display is an estimate — see its in-app disclaimer.'),
          _section(context, '5. Notifications',
              'Prayer alarms and reminders are scheduled locally on your device. No push-notification server is involved.'),
          _section(context, '6. App lock & admin PIN',
              'If you enable the app lock or set an admin PIN, the PIN is stored in your device\'s secure keychain/keystore (encrypted). It never leaves the device.'),
          _section(context, '7. Backup & export',
              'The backup/export feature creates a JSON file on your device (or shared by you). You control where that file goes. Importing a backup replaces local data.'),
          _section(context, '8. Children',
              'The app has no age gate and collects no personal data, which makes it suitable for general audiences. Parents: the curated video section opens YouTube in an external app — YouTube\'s own policies apply there.'),
          _section(context, '9. Changes',
              'If this policy changes, the updated version will ship with the app and the "Last updated" date above will change.'),
          _section(context, '10. Contact',
              'For privacy questions, contact the publisher through the app\'s store listing.'),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
