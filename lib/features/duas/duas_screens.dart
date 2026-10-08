import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';

String duaCategoryLabel(BuildContext context, String category) {
  const keys = {
    'morning': 'dua_cat_morning',
    'evening': 'dua_cat_evening',
    'salah': 'dua_cat_salah',
    'sleep': 'dua_cat_sleep',
    'waking': 'dua_cat_waking',
    'eating': 'dua_cat_eating',
    'travel': 'dua_cat_travel',
    'anxiety': 'dua_cat_anxiety',
    'forgiveness': 'dua_cat_forgiveness',
    'protection': 'dua_cat_protection',
    'parents': 'dua_cat_parents',
    'rizq': 'dua_cat_rizq',
    'knowledge': 'dua_cat_knowledge',
    'general': 'dua_cat_general',
  };
  return S.of(context, keys[category] ?? 'dua_cat_general');
}

/// Dua library: categories → list → detail with source.
class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});

  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  Future<List<String>>? _catsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _catsFuture = ContentRepository.instance.duaCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'duas_title'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: S.of(context, 'duas_search_hint'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (q) => setState(() => _query = q),
            ),
          ),
          Expanded(
            child: _query.trim().length >= 2
                ? _DuaSearchResults(query: _query.trim())
                : FutureBuilder<List<String>>(
                    future: _catsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return LoadingView(
                            label: S.of(context, 'common_loading'));
                      }
                      if (snap.hasError || !snap.hasData) {
                        return ErrorView(
                          message: S.of(context, 'common_error'),
                          retryLabel: S.of(context, 'common_retry'),
                          onRetry: () => setState(() {
                            _catsFuture = ContentRepository.instance
                                .duaCategories();
                          }),
                        );
                      }
                      final cats = snap.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: cats.length,
                        itemBuilder: (context, i) => InfoCard(
                          icon: Icons.favorite_border,
                          title: duaCategoryLabel(context, cats[i]),
                          body: S.of(context, 'duas_open_category'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DuaListScreen(category: cats[i]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DuaSearchResults extends StatelessWidget {
  const _DuaSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Dua>>(
      future: ContentRepository.instance.searchDuas(query),
      builder: (context, snap) {
        if (!snap.hasData) {
          return LoadingView(label: S.of(context, 'common_loading'));
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return Center(child: Text(S.of(context, 'duas_no_results')));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: list.length,
          itemBuilder: (context, i) => _DuaTile(dua: list[i]),
        );
      },
    );
  }
}

class DuaListScreen extends StatelessWidget {
  const DuaListScreen({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(duaCategoryLabel(context, category))),
      body: FutureBuilder<List<Dua>>(
        future: ContentRepository.instance.duasInCategory(category),
        builder: (context, snap) {
          if (!snap.hasData) {
            return LoadingView(label: S.of(context, 'common_loading'));
          }
          final list = snap.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: list.length,
            itemBuilder: (context, i) => _DuaTile(dua: list[i]),
          );
        },
      ),
    );
  }
}

class _DuaTile extends StatelessWidget {
  const _DuaTile({required this.dua});

  final Dua dua;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(dua.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          dua.source,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DuaDetailScreen(dua: dua)),
        ),
      ),
    );
  }
}

class DuaDetailScreen extends StatefulWidget {
  const DuaDetailScreen({super.key, required this.dua});

  final Dua dua;

  @override
  State<DuaDetailScreen> createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends State<DuaDetailScreen> {
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
    UserDataRepository.instance
        .isDuaBookmarked(widget.dua.id)
        .then((b) => mounted ? setState(() => _bookmarked = b) : null);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dua;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(d.title),
        actions: [
          IconButton(
            icon: Icon(
                _bookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () async {
              await UserDataRepository.instance
                  .toggleDuaBookmark(d.id);
              final b = await UserDataRepository.instance
                  .isDuaBookmarked(d.id);
              if (mounted) setState(() => _bookmarked = b);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share(
                '${d.arabic}\n\n${d.english ?? ''}\n\n— ${d.source} (via Noor-e-Deen)'),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(
                  text: '${d.arabic}\n\n${d.english ?? ''}\n\n— ${d.source}'));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(S.of(context, 'quran_copied'))));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${S.of(context, 'duas_source')}: ${d.source}',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                d.arabic,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 24,
                  height: 2.0,
                ),
              ),
            ),
          ),
          if (d.transliteration != null) ...[
            const SizedBox(height: 12),
            _LabeledText(
                label: S.of(context, 'duas_transliteration'),
                text: d.transliteration!),
          ],
          if (d.urdu != null) ...[
            const SizedBox(height: 12),
            _LabeledText(
              label: S.of(context, 'duas_urdu'),
              text: d.urdu!,
              rtl: true,
            ),
          ],
          if (d.english != null) ...[
            const SizedBox(height: 12),
            _LabeledText(
                label: S.of(context, 'duas_english'), text: d.english!),
          ],
        ],
      ),
    );
  }
}

class _LabeledText extends StatelessWidget {
  const _LabeledText(
      {required this.label, required this.text, this.rtl = false});

  final String label;
  final String text;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          rtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          text,
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          textAlign: rtl ? TextAlign.right : TextAlign.left,
          style: TextStyle(fontSize: 15, height: rtl ? 2.0 : 1.6),
        ),
      ],
    );
  }
}
