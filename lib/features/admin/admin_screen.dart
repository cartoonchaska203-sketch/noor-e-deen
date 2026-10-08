import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/security/input_validation.dart';
import '../../core/widgets/common_widgets.dart';
import '../../l10n/strings.dart';
import 'admin_content_screen.dart';
import 'admin_features_screen.dart';
import 'admin_scholars_screen.dart';
import 'admin_service.dart';
import 'admin_videos_screen.dart';

/// Admin CMS dashboard (Phase 6). All sections are functional.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'admin_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoCard(
            icon: Icons.info_outline,
            title: S.of(context, 'admin_about_title'),
            body: S.of(context, 'admin_about_body'),
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            Icons.school_outlined,
            S.of(context, 'admin_scholars'),
            S.of(context, 'admin_scholars_sub'),
            const AdminScholarsScreen(),
          ),
          _tile(
            context,
            Icons.play_circle_outline,
            S.of(context, 'admin_videos'),
            S.of(context, 'admin_videos_sub'),
            const AdminVideosScreen(),
          ),
          _tile(
            context,
            Icons.visibility_outlined,
            S.of(context, 'admin_content'),
            S.of(context, 'admin_content_sub'),
            const AdminContentScreen(),
          ),
          _tile(
            context,
            Icons.toggle_on_outlined,
            S.of(context, 'admin_features'),
            S.of(context, 'admin_features_sub'),
            const AdminFeaturesScreen(),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: Text(S.of(context, 'admin_export')),
                  subtitle: Text(S.of(context, 'admin_export_sub')),
                  onTap: () => _export(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.upload_outlined),
                  title: Text(S.of(context, 'admin_import')),
                  subtitle: Text(S.of(context, 'admin_import_sub')),
                  onTap: () => _import(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.lock_reset_outlined),
                  title: Text(S.of(context, 'admin_change_pin')),
                  onTap: () => _changePin(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title,
      String sub, Widget screen) {
    return Card(
      child: ListTile(
        leading: Icon(icon,
            color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => screen),
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final json = await AdminService.instance.exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, 'admin_exported'))),
      );
    }
    // Also offer the share sheet for large exports.
    if (context.mounted) {
      await Share.share(json,
          subject: S.of(context, 'admin_export_subject'));
    }
  }

  Future<void> _import(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx, 'admin_import')),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: S.of(ctx, 'admin_import_hint'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.of(ctx, 'common_cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(S.of(ctx, 'admin_import_button')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final n = await AdminService.instance.importJson(ctrl.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${S.of(context, 'admin_imported')}: $n')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${S.of(context, 'admin_import_failed')}: $e')),
        );
      }
    }
  }

  Future<void> _changePin(BuildContext context) async {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(S.of(ctx, 'admin_change_pin')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: c1,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: S.of(ctx, 'admin_pin_new'),
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: c2,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: S.of(ctx, 'admin_pin_confirm'),
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!,
                    style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(S.of(ctx, 'common_cancel')),
            ),
            FilledButton(
              onPressed: () {
                final v = InputValidation.validatePin(c1.text.trim());
                if (v != null) {
                  setS(() => error = InputValidation.message(v));
                  return;
                }
                if (c1.text.trim() != c2.text.trim()) {
                  setS(() =>
                      error = S.of(ctx, 'admin_pin_mismatch'));
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: Text(S.of(ctx, 'common_save')),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await AdminService.instance.setPin(c1.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, 'admin_pin_changed'))),
        );
      }
    }
  }
}
