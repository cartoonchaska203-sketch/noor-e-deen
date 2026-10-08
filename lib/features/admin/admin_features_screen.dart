import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../l10n/strings.dart';
import 'admin_service.dart';

/// Admin: enable/disable Explore tiles (Phase 6).
///
/// Disabled features disappear from the Explore grid. Core tabs
/// (Home, Quran, Prayer, Explore, More) can never be disabled.
class AdminFeaturesScreen extends StatefulWidget {
  const AdminFeaturesScreen({super.key});

  @override
  State<AdminFeaturesScreen> createState() =>
      _AdminFeaturesScreenState();
}

class _AdminFeaturesScreenState extends State<AdminFeaturesScreen> {
  static const _tiles = [
    ('explore_noorai', Icons.auto_awesome_outlined),
    ('explore_dashboard', Icons.dashboard_outlined),
    ('explore_goals', Icons.flag_outlined),
    ('explore_hadith', Icons.library_books_outlined),
    ('explore_duas', Icons.favorite_border),
    ('explore_wazaif', Icons.auto_awesome_outlined),
    ('explore_adhkar', Icons.wb_sunny_outlined),
    ('explore_tasbeeh', Icons.fingerprint_outlined),
    ('explore_calendar', Icons.calendar_month_outlined),
    ('explore_ramadan', Icons.nights_stay_outlined),
    ('explore_salah_guide', Icons.mosque_outlined),
    ('explore_hifz', Icons.menu_book_outlined),
    ('explore_tajweed', Icons.record_voice_over_outlined),
    ('explore_zakat', Icons.calculate_outlined),
    ('explore_hajj', Icons.travel_explore_outlined),
    ('explore_mosques', Icons.mosque),
    ('explore_family', Icons.family_restroom_outlined),
    ('explore_charity', Icons.volunteer_activism_outlined),
    ('explore_audio', Icons.headphones_outlined),
    ('explore_video', Icons.play_circle_outline),
    ('explore_scholars', Icons.school_outlined),
    ('explore_community', Icons.groups_outlined),
  ];

  Set<String> _disabled = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await AdminService.instance.disabledFeatures();
    if (mounted) {
      setState(() {
        _disabled = d;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(String key, bool enable) async {
    await AdminService.instance.setFeatureEnabled(key, enable);
    if (mounted) {
      setState(() {
        if (enable) {
          _disabled.remove(key);
        } else {
          _disabled.add(key);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'admin_features'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                InfoCard(
                  icon: Icons.toggle_on_outlined,
                  title: S.of(context, 'admin_features_note_title'),
                  body: S.of(context, 'admin_features_note_body'),
                ),
                const SizedBox(height: 8),
                for (final (key, icon) in _tiles)
                  Card(
                    child: SwitchListTile(
                      secondary: Icon(icon,
                          color: Theme.of(context)
                              .colorScheme
                              .primary),
                      title: Text(S.of(context, key)),
                      value: !_disabled.contains(key),
                      onChanged: (v) => _toggle(key, v),
                    ),
                  ),
              ],
            ),
    );
  }
}
