import 'package:flutter/material.dart';

import '../../core/security/input_validation.dart';
import '../../l10n/strings.dart';
import 'admin_service.dart';

/// Admin: manage custom curated video topics (Phase 6).
///
/// Each topic is a label + YouTube search query (never an invented
/// channel URL — the app opens YouTube search results, same as the
/// built-in list).
class AdminVideosScreen extends StatefulWidget {
  const AdminVideosScreen({super.key});

  @override
  State<AdminVideosScreen> createState() => _AdminVideosScreenState();
}

class _AdminVideosScreenState extends State<AdminVideosScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AdminService.instance.customVideos();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _edit([Map<String, dynamic>? existing]) async {
    final title =
        TextEditingController(text: existing?['title'] ?? '');
    final query =
        TextEditingController(text: existing?['query'] ?? '');
    String? error;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(S.of(ctx,
              existing == null ? 'admin_video_add' : 'admin_video_edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: InputDecoration(
                  labelText: S.of(ctx, 'admin_video_title'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: query,
                decoration: InputDecoration(
                  labelText: S.of(ctx, 'admin_video_query'),
                  hintText: S.of(ctx, 'admin_video_query_hint'),
                  border: const OutlineInputBorder(),
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
                final v = InputValidation.validateName(title.text);
                final vq = InputValidation.validateName(query.text);
                final bad = v ?? vq;
                if (bad != null) {
                  setS(() => error = InputValidation.message(bad));
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
    await AdminService.instance.upsertVideo({
      'id': existing?['id'] ??
          'vid_${DateTime.now().millisecondsSinceEpoch}',
      'title': InputValidation.sanitize(title.text),
      'query': InputValidation.sanitize(query.text),
    });
    _load();
  }

  Future<void> _delete(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx, 'common_delete')),
        content: Text('${S.of(ctx, 'admin_delete_confirm')}: $title?'),
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
      await AdminService.instance.deleteVideo(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'admin_videos'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        tooltip: S.of(context, 'admin_video_add'),
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
                    final v = _items[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.play_circle_outline),
                        title: Text(v['title'] as String),
                        subtitle:
                            Text(v['query'] as String),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: S.of(context, 'common_edit'),
                              onPressed: () => _edit(v),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: S.of(context, 'common_delete'),
                              onPressed: () => _delete(
                                  v['id'] as String,
                                  v['title'] as String),
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
