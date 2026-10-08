import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../l10n/strings.dart';
import '../settings/settings_screen.dart';

/// "More" tab: settings entry, about, privacy and honest Phase 4 notices.
///
/// Every row does something real: navigates to a working screen or opens an
/// information dialog. Nothing here is a dead button.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _showInfo(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(S.of(ctx, 'common_close')),
          ),
        ],
      ),
    );
  }

  void _showPhase4(BuildContext context, String title) {
    _showInfo(
      context,
      '$title · ${S.of(context, 'more_phase4')}',
      S.of(context, 'more_phase4_body'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'more_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(S.of(context, 'more_settings')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(S.of(context, 'more_notifications')),
                  trailing: PhaseBadge(S.of(context, 'more_phase4')),
                  onTap: () => _showPhase4(
                      context, S.of(context, 'more_notifications')),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: Text(S.of(context, 'more_account')),
                  trailing: PhaseBadge(S.of(context, 'more_phase4')),
                  onTap: () =>
                      _showPhase4(context, S.of(context, 'more_account')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(S.of(context, 'more_about')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showInfo(
                    context,
                    S.of(context, 'more_about'),
                    S.of(context, 'about_body'),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(S.of(context, 'more_privacy')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showInfo(
                    context,
                    S.of(context, 'more_privacy'),
                    S.of(context, 'privacy_body'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              S.of(context, 'more_version'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
