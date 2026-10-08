import 'package:flutter/material.dart';

import '../../core/services/prayer_service.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/cities.dart';
import '../../core/widgets/common_widgets.dart';
import '../../l10n/strings.dart';

/// Settings: theme (light/dark/AMOLED), language (EN/UR with RTL),
/// prayer calculation method, Asr method, location mode + manual city.
///
/// Everything persists via shared_preferences through [AppState].
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'settings_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SectionTitle(S.of(context, 'settings_theme')),
          Card(
            child: RadioGroup<AppThemeMode>(
              groupValue: state.themeMode,
              onChanged: (v) {
                if (v != null) state.setThemeMode(v);
              },
              child: Column(
                children: [
                  _ThemeOption(
                    mode: AppThemeMode.light,
                    icon: Icons.light_mode_outlined,
                    label: S.of(context, 'settings_theme_light'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _ThemeOption(
                    mode: AppThemeMode.dark,
                    icon: Icons.dark_mode_outlined,
                    label: S.of(context, 'settings_theme_dark'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _ThemeOption(
                    mode: AppThemeMode.amoled,
                    icon: Icons.contrast_outlined,
                    label: S.of(context, 'settings_theme_amoled'),
                  ),
                ],
              ),
            ),
          ),
          SectionTitle(S.of(context, 'settings_language')),
          Card(
            child: RadioGroup<String>(
              groupValue: state.localeCode,
              onChanged: (v) {
                if (v != null) state.setLocaleCode(v);
              },
              child: const Column(
                children: [
                  RadioListTile<String>(
                    value: 'en',
                    title: Text('English'),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<String>(
                    value: 'ur',
                    title: Text('اردو'),
                    subtitle: Text('RTL layout'),
                  ),
                ],
              ),
            ),
          ),
          SectionTitle(S.of(context, 'settings_prayer')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: Text(S.of(context, 'prayer_method')),
              subtitle: Text(S.of(context, 'method_${state.calcMethod}')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickMethod(context, state),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context, 'prayer_asr'),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'standard',
                        label: Text(S.of(context, 'prayer_asr_standard')),
                      ),
                      ButtonSegment(
                        value: 'hanafi',
                        label: Text(S.of(context, 'prayer_asr_hanafi')),
                      ),
                    ],
                    selected: {state.asrMethod},
                    onSelectionChanged: (sel) =>
                        state.setAsrMethod(sel.first),
                  ),
                ],
              ),
            ),
          ),
          SectionTitle(S.of(context, 'settings_location')),
          Card(
            child: RadioGroup<String>(
              groupValue: state.locationMode,
              onChanged: (v) {
                if (v != null) state.setLocationMode(v);
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'gps',
                    title: Text(S.of(context, 'prayer_gps')),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<String>(
                    value: 'manual',
                    title: Text(S.of(context, 'prayer_manual')),
                  ),
                  if (state.locationMode == 'manual')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: DropdownButtonFormField<String>(
                        initialValue: state.manualCity,
                        decoration: InputDecoration(
                          labelText: S.of(context, 'prayer_city'),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (final city in kCities)
                            DropdownMenuItem(
                              value: city.name,
                              child: Text('${city.name}, ${city.country}'),
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) state.setManualCity(v);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMethod(BuildContext context, AppState state) async {
    final String? picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(S.of(ctx, 'prayer_method')),
        children: [
          for (final id in PrayerService.supportedMethods)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(S.of(ctx, 'method_$id')),
              ),
            ),
        ],
      ),
    );
    if (picked != null) {
      state.setCalcMethod(picked);
    }
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.label,
  });

  final AppThemeMode mode;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<AppThemeMode>(
      value: mode,
      title: Text(label),
      secondary: Icon(icon),
    );
  }
}
