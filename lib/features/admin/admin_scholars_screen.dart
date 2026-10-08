import 'package:flutter/material.dart';

import '../../core/security/input_validation.dart';
import '../../l10n/strings.dart';
import 'admin_service.dart';

/// Admin: manage custom scholar directory entries (Phase 6).
///
/// STRICT DATA POLICY: the "verified" flag may ONLY be set after a
/// real, independent credential check. The UI forces an explicit
/// confirmation stating this before the flag can be turned on.
/// Nothing about credentials, degrees, or affiliations is invented.
class AdminScholarsScreen extends StatefulWidget {
  const AdminScholarsScreen({super.key});

  @override
  State<AdminScholarsScreen> createState() =>
      _AdminScholarsScreenState();
}

class _AdminScholarsScreenState extends State<AdminScholarsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AdminService.instance.customScholars();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _edit([Map<String, dynamic>? existing]) async {
    final name = TextEditingController(text: existing?['name'] ?? '');
    final spec =
        TextEditingController(text: existing?['specialization'] ?? '');
    final region =
        TextEditingController(text: existing?['region'] ?? '');
    var verified = existing?['verified'] == true;
    String? error;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(S.of(ctx,
              existing == null ? 'admin_scholar_add' : 'admin_scholar_edit')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: S.of(ctx, 'admin_scholar_name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: spec,
                  decoration: InputDecoration(
                    labelText: S.of(ctx, 'admin_scholar_spec'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: region,
                  decoration: InputDecoration(
                    labelText: S.of(ctx, 'admin_scholar_region'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  title: Text(S.of(ctx, 'admin_scholar_verified')),
                  subtitle: Text(S.of(ctx, 'admin_scholar_verified_note')),
                  value: verified,
                  onChanged: (v) async {
                    if (v) {
                      final confirm = await showDialog<bool>(
                        context: ctx,
                        builder: (c2) => AlertDialog(
                          title: Text(S.of(
                              c2, 'admin_verify_confirm_title')),
                          content: Text(S.of(
                              c2, 'admin_verify_confirm_body')),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(c2).pop(false),
                              child:
                                  Text(S.of(c2, 'common_cancel')),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(c2).pop(true),
                              child: Text(
                                  S.of(c2, 'admin_verify_confirm_yes')),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                    }
                    setS(() => verified = v);
                  },
                ),
                if (error != null)
                  Text(error!,
                      style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(S.of(ctx, 'common_cancel')),
            ),
            FilledButton(
              onPressed: () {
                final vName = InputValidation.validateName(name.text);
                if (vName != null) {
                  setS(() => error = InputValidation.message(vName));
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
    if (saved != true) return;
    final entry = {
      'id': existing?['id'] ??
          'custom_${DateTime.now().millisecondsSinceEpoch}',
      'name': InputValidation.sanitize(name.text),
      'specialization': InputValidation.sanitize(spec.text),
      'region': InputValidation.sanitize(region.text),
      'verified': verified,
      'custom': true,
    };
    await AdminService.instance.upsertScholar(entry);
    _load();
  }

  Future<void> _delete(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx, 'common_delete')),
        content: Text('${S.of(ctx, 'admin_delete_confirm')}: $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.of(ctx, 'common_cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(S.of(ctx, 'common_delete')),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AdminService.instance.deleteScholar(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'admin_scholars'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        tooltip: S.of(context, 'admin_scholar_add'),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text(S.of(context, 'admin_empty'),
                      style: Theme.of(context).textTheme.bodyLarge))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final s = _items[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                              (s['name'] as String).characters.first),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                                child: Text(s['name'] as String)),
                            if (s['verified'] == true)
                              const Icon(Icons.verified,
                                  color: Colors.blue, size: 18),
                          ],
                        ),
                        subtitle: Text(
                            '${s['specialization']} · ${s['region']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: S.of(context, 'common_edit'),
                              onPressed: () => _edit(s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: S.of(context, 'common_delete'),
                              onPressed: () => _delete(
                                  s['id'] as String,
                                  s['name'] as String),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
