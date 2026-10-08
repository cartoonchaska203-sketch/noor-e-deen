import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/app_services.dart';
import '../../core/widgets/common_widgets.dart';
import '../../l10n/strings.dart';

/// Backup & sync (Phase 4): local-first. Export the full on-device dataset
/// as JSON (share sheet / copy), import it back. No account required.
/// Backend integration (Supabase/Firebase) is documented, not active.
class BackupSyncScreen extends StatefulWidget {
  const BackupSyncScreen({super.key});

  @override
  State<BackupSyncScreen> createState() => _BackupSyncScreenState();
}

class _BackupSyncScreenState extends State<BackupSyncScreen> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await AppServices.sync.shareBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, 'sync_exported'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.of(context, 'common_error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyExport() async {
    setState(() => _busy = true);
    try {
      final json = await AppServices.sync.exportBackup();
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, 'sync_copied'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.of(context, 'common_error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importDialog() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx, 'sync_import')),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: ctrl,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: S.of(ctx, 'sync_paste_hint'),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.of(ctx, 'common_cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(S.of(ctx, 'sync_import')),
          ),
        ],
      ),
    );
    final text = ctrl.text;
    ctrl.dispose();
    if (ok != true || text.trim().isEmpty) return;

    setState(() => _busy = true);
    try {
      final n = await AppServices.sync.importBackup(text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(S.of(context, 'sync_imported')
                  .replaceFirst('{n}', '$n'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.of(context, 'sync_import_failed')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'sync_title'))),
      body: _busy
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                InfoCard(
                  icon: Icons.cloud_off_outlined,
                  title: S.of(context, 'sync_local_title'),
                  body: S.of(context, 'sync_local_body'),
                ),
                SectionTitle(S.of(context, 'sync_backup')),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.ios_share_outlined),
                        title: Text(S.of(context, 'sync_export')),
                        subtitle:
                            Text(S.of(context, 'sync_export_sub')),
                        trailing:
                            const Icon(Icons.chevron_right),
                        onTap: _export,
                      ),
                      const Divider(
                          height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.copy_outlined),
                        title: Text(S.of(context, 'sync_copy')),
                        trailing:
                            const Icon(Icons.chevron_right),
                        onTap: _copyExport,
                      ),
                      const Divider(
                          height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading:
                            const Icon(Icons.download_outlined),
                        title: Text(S.of(context, 'sync_import')),
                        subtitle:
                            Text(S.of(context, 'sync_import_sub')),
                        trailing:
                            const Icon(Icons.chevron_right),
                        onTap: _importDialog,
                      ),
                    ],
                  ),
                ),
                SectionTitle(S.of(context, 'sync_cloud')),
                InfoCard(
                  icon: Icons.cloud_queue_outlined,
                  title: S.of(context, 'sync_cloud_title'),
                  body: S.of(context, 'sync_cloud_body'),
                ),
              ],
            ),
    );
  }
}
