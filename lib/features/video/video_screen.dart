import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/offline_banner.dart';
import '../../l10n/strings.dart';
import '../admin/admin_service.dart';

/// Curated Islamic education videos.
///
/// The app does NOT scrape or re-host video. It links out to public
/// YouTube results for well-known scholarly topics/channels. Links use
/// YouTube search URLs (never invented channel URLs) and every entry is
/// marked "verify independently". A future admin CMS can replace this
/// static allowlist with curated, verified entries.
class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  Future<List<_Topic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadTopics();
  }

  /// Built-in topics + admin-added custom topics.
  Future<List<_Topic>> _loadTopics() async {
    final topics = [
      _Topic('video_t1', 'Mufti Menk Friday sermon', Icons.mic_outlined),
      _Topic('video_t2', 'Yasir Qadhi Seerah series', Icons.history_edu_outlined),
      _Topic('video_t3', 'Omar Suleiman Quran reflections', Icons.menu_book_outlined),
      _Topic('video_t4', 'Nouman Ali Khan Quran tafseer', Icons.translate_outlined),
      _Topic('video_t5', 'Assim Al Hakeem Q&A', Icons.question_answer_outlined),
      _Topic('video_t6', 'Tajweed lessons for beginners', Icons.record_voice_over_outlined),
      _Topic('video_t7', 'How to pray step by step', Icons.mosque_outlined),
      _Topic('video_t8', 'Stories of the Prophets', Icons.auto_stories_outlined),
    ];
    try {
      final custom = await AdminService.instance.customVideos();
      for (final c in custom) {
        topics.add(_Topic.custom(
          (c['title'] ?? '').toString(),
          (c['query'] ?? '').toString(),
        ));
      }
    } catch (_) {
      // Admin data unavailable: built-ins alone.
    }
    return topics;
  }

  Future<void> _open(BuildContext context, String query) async {
    final uri = Uri.parse(
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, 'common_open_failed'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'video_title'))),
      body: FutureBuilder<List<_Topic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final topics = snap.data ?? const <_Topic>[];
          return _body(context, topics);
        },
      ),
    );
  }

  Widget _body(BuildContext context, List<_Topic> topics) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Phase 6: YouTube links need the internet.
        const OfflineBanner(),
        InfoCard(
          icon: Icons.verified_outlined,
          title: S.of(context, 'video_curation_title'),
          body: S.of(context, 'video_curation_body'),
        ),
        const SizedBox(height: 8),
        for (final t in topics)
          Card(
            child: ListTile(
              leading: Icon(t.icon,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(t.labelKey != null
                  ? S.of(context, t.labelKey!)
                  : t.customTitle!),
              subtitle: Text(S.of(context, 'video_verify_note')),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _open(context, t.query),
            ),
          ),
      ],
    );
  }
}

class _Topic {
  const _Topic(this.labelKey, this.query, this.icon)
      : customTitle = null;

  const _Topic.custom(this.customTitle, this.query)
      : labelKey = null,
        icon = Icons.play_circle_outline;

  final String? labelKey;
  final String? customTitle;
  final String query;
  final IconData icon;
}
