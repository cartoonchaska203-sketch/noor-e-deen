import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

/// Terms of Use (Phase 6).
///
/// Honest terms matching the app's actual behavior: informational
/// religious content with sources, explicit non-fatwa policy, and
/// user responsibility for verification.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'legal_terms_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'Noor-e-Deen — Terms of Use',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Last updated: 8 October 2026 · Version 1.0.0',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _section(context, '1. Purpose',
              'Noor-e-Deen ("the app") is a personal Islamic companion: prayer times, Qibla, Quran, Hadith, duas, and worship tracking. It is provided free of charge for personal, non-commercial use.'),
          _section(context, '2. Religious content — important',
              'Quranic text, translations, hadith, and duas are reproduced from the sources cited in-app and in DATA_SOURCES. We take care to avoid altering religious text, but you should verify anything you act upon against a printed mushaf or a qualified scholar. Prayer-time calculations follow standard astronomical methods; the Hijri calendar is an estimate — moon sighting in your locality governs actual dates.'),
          _section(context, '3. Not a fatwa',
              'Nothing in the app — including Noor AI answers, wazaif notes, and community posts — constitutes a personal religious ruling (fatwa). For personal religious questions (halal/haram, worship validity, family matters, finance), consult a qualified scholar you trust.'),
          _section(context, '4. Zakat calculator',
              'The Zakat calculator gives an informational estimate only. Zakat obligations depend on personal circumstances; consult a qualified scholar before acting on the result.'),
          _section(context, '5. Your data, your responsibility',
              'Your data lives on your device. If you export a backup, keep it safe. If you delete the app or clear its data without a backup, your history cannot be recovered by us.'),
          _section(context, '6. Acceptable use',
              'Do not misuse the community features to post spam, unverified religious rulings presented as authoritative, or content that harasses others. The app owner may hide content via the admin panel.'),
          _section(context, '7. Third-party services',
              'Mosque data (OpenStreetMap), audio streams (everyayah.com), rate data (public APIs), and videos (YouTube) are provided by third parties under their own terms. We do not control their availability or accuracy.'),
          _section(context, '8. No warranty',
              'The app is provided "as is", without warranties of any kind. To the maximum extent permitted by law, we are not liable for any loss arising from use of the app.'),
          _section(context, '9. Changes',
              'We may update these terms with new app versions. Continued use after an update means you accept the updated terms.'),
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
