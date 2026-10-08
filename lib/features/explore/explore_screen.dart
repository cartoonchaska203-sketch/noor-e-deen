import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../adhkar/adhkar_screen.dart';
import '../calendar/calendar_screen.dart';
import '../duas/duas_screens.dart';
import '../hadith/hadith_screens.dart';
import '../hajj_umrah/hajj_umrah_screen.dart';
import '../hifz/hifz_screen.dart';
import '../ramadan/ramadan_screen.dart';
import '../salah_guide/salah_guide_screen.dart';
import '../tajweed/tajweed_screen.dart';
import '../tasbeeh/tasbeeh_screen.dart';
import '../wazaif/wazaif_screen.dart';
import '../zakat/zakat_screen.dart';

/// Explore tab: grid of all built features.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = <_ExploreItem>[
      _ExploreItem(
        icon: Icons.library_books_outlined,
        label: S.of(context, 'explore_hadith'),
        screen: const HadithHomeScreen(),
      ),
      _ExploreItem(
        icon: Icons.favorite_border,
        label: S.of(context, 'explore_duas'),
        screen: const DuasScreen(),
      ),
      _ExploreItem(
        icon: Icons.auto_awesome_outlined,
        label: S.of(context, 'explore_wazaif'),
        screen: const WazaifScreen(),
      ),
      _ExploreItem(
        icon: Icons.wb_sunny_outlined,
        label: S.of(context, 'explore_adhkar'),
        screen: const AdhkarScreen(),
      ),
      _ExploreItem(
        icon: Icons.fingerprint_outlined,
        label: S.of(context, 'explore_tasbeeh'),
        screen: const TasbeehScreen(),
      ),
      _ExploreItem(
        icon: Icons.calendar_month_outlined,
        label: S.of(context, 'explore_calendar'),
        screen: const IslamicCalendarScreen(),
      ),
      _ExploreItem(
        icon: Icons.nights_stay_outlined,
        label: S.of(context, 'explore_ramadan'),
        screen: const RamadanScreen(),
      ),
      _ExploreItem(
        icon: Icons.mosque_outlined,
        label: S.of(context, 'explore_salah_guide'),
        screen: const SalahGuideScreen(),
      ),
      _ExploreItem(
        icon: Icons.menu_book_outlined,
        label: S.of(context, 'explore_hifz'),
        screen: const HifzScreen(),
      ),
      _ExploreItem(
        icon: Icons.record_voice_over_outlined,
        label: S.of(context, 'explore_tajweed'),
        screen: const TajweedScreen(),
      ),
      _ExploreItem(
        icon: Icons.calculate_outlined,
        label: S.of(context, 'explore_zakat'),
        screen: const ZakatScreen(),
      ),
      _ExploreItem(
        icon: Icons.travel_explore_outlined,
        label: S.of(context, 'explore_hajj'),
        screen: const HajjUmrahScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'explore_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: features.length,
            itemBuilder: (context, i) {
              final f = features[i];
              final colors = Theme.of(context).colorScheme;
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => f.screen),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              colors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(f.icon,
                            color: colors.primary, size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        f.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ExploreItem {
  _ExploreItem(
      {required this.icon, required this.label, required this.screen});

  final IconData icon;
  final String label;
  final Widget screen;
}
