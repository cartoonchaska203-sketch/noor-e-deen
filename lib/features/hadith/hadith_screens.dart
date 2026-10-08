import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/hadith_repository.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';

/// Hadith home: collection picker + hadith of the day.
class HadithHomeScreen extends StatefulWidget {
  const HadithHomeScreen({super.key});

  @override
  State<HadithHomeScreen> createState() => _HadithHomeScreenState();
}

class _HadithHomeScreenState extends State<HadithHomeScreen> {
  Future<List<String>>? _collectionsFuture;
  Future<HadithEntry>? _dailyFuture;

  @override
  void initState() {
    super.initState();
    _collectionsFuture = HadithRepository.instance.availableCollections();
    _dailyFuture = HadithRepository.instance.hadithOfTheDay(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'hadith_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionTitle(S.of(context, 'hadith_daily')),
          FutureBuilder<HadithEntry>(
            future: _dailyFuture,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Card(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator())));
              }
              if (snap.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(S.of(context, 'common_error')),
                  ),
                );
              }
              return _HadithCard(entry: snap.data!, compact: true);
            },
          ),
          SectionTitle(S.of(context, 'hadith_collections')),
          FutureBuilder<List<String>>(
            future: _collectionsFuture,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return LoadingView(label: S.of(context, 'common_loading'));
              }
              final ids = snap.data ?? [];
              if (ids.isEmpty) {
                return ErrorView(
                  message: S.of(context, 'hadith_unavailable'),
                  retryLabel: S.of(context, 'common_retry'),
                  onRetry: () => setState(() {
                    _collectionsFuture = HadithRepository.instance
                        .availableCollections();
                  }),
                );
              }
              return Column(
                children: [
                  for (final id in ids)
                    InfoCard(
                      icon: Icons.library_books_outlined,
                      title: HadithRepository.instance.collectionName(id),
                      body: S.of(context, 'hadith_open_collection'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              HadithBookListScreen(collectionId: id),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            S.of(context, 'hadith_source_note'),
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Book/chapter list inside one collection.
class HadithBookListScreen extends StatefulWidget {
  const HadithBookListScreen({super.key, required this.collectionId});

  final String collectionId;

  @override
  State<HadithBookListScreen> createState() => _HadithBookListScreenState();
}

class _HadithBookListScreenState extends State<HadithBookListScreen> {
  Future<List<({int number, String name, int count})>>? _booksFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _booksFuture =
        HadithRepository.instance.books(widget.collectionId);
  }

  @override
  Widget build(BuildContext context) {
    final name = HadithRepository.instance.collectionName(widget.collectionId);
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: S.of(context, 'hadith_search_hint'),
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
            child: FutureBuilder<List<({int number, String name, int count})>>(
              future: _booksFuture,
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
                      _booksFuture = HadithRepository.instance
                          .books(widget.collectionId);
                    }),
                  );
                }
                var books = snap.data!;
                final q = _query.trim().toLowerCase();
                if (q.isNotEmpty) {
                  books = books
                      .where((b) =>
                          b.name.toLowerCase().contains(q) ||
                          b.number.toString() == q)
                      .toList();
                }
                return ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, i) {
                    final b = books[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        child: Text(
                          '${b.number}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(b.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${b.count} ${S.of(context, 'hadith_count')}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HadithListScreen(
                            collectionId: widget.collectionId,
                            bookNumber: b.number,
                            bookName: b.name,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Hadith list inside one book, with in-book text search.
class HadithListScreen extends StatefulWidget {
  const HadithListScreen({
    super.key,
    required this.collectionId,
    required this.bookNumber,
    required this.bookName,
  });

  final String collectionId;
  final int bookNumber;
  final String bookName;

  @override
  State<HadithListScreen> createState() => _HadithListScreenState();
}

class _HadithListScreenState extends State<HadithListScreen> {
  Future<List<HadithEntry>>? _hadithsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _hadithsFuture = HadithRepository.instance
        .hadithsInBook(widget.collectionId, widget.bookNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.bookName),
            Text(
              HadithRepository.instance
                  .collectionName(widget.collectionId),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: S.of(context, 'hadith_search_text_hint'),
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
            child: FutureBuilder<List<HadithEntry>>(
              future: _hadithsFuture,
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
                      _hadithsFuture = HadithRepository.instance
                          .hadithsInBook(
                              widget.collectionId, widget.bookNumber);
                    }),
                  );
                }
                var list = snap.data!
                    .where((h) => h.text.trim().isNotEmpty)
                    .toList();
                final q = _query.trim().toLowerCase();
                if (q.length >= 3) {
                  list = list
                      .where((h) => h.text.toLowerCase().contains(q))
                      .toList();
                }
                if (list.isEmpty) {
                  return Center(
                      child: Text(S.of(context, 'hadith_no_results')));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) =>
                      _HadithCard(entry: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One hadith card: text + ALWAYS-visible source line + actions.
///
/// The source line is the religious-accuracy guarantee — it can never be
/// hidden or omitted.
class _HadithCard extends StatefulWidget {
  const _HadithCard({required this.entry, this.compact = false});

  final HadithEntry entry;
  final bool compact;

  @override
  State<_HadithCard> createState() => _HadithCardState();
}

class _HadithCardState extends State<_HadithCard> {
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  String get _ref =>
      '${widget.entry.collection}:${widget.entry.bookNumber}:${widget.entry.hadithNumber}';

  Future<void> _refresh() async {
    final b = await UserDataRepository.instance.isHadithBookmarked(_ref);
    if (mounted) setState(() => _bookmarked = b);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final e = widget.entry;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                e.sourceLine,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              e.text,
              style: TextStyle(
                fontSize: widget.compact ? 14 : 15,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    _bookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    size: 20,
                  ),
                  onPressed: () async {
                    await UserDataRepository.instance
                        .toggleHadithBookmark(_ref);
                    _refresh();
                  },
                ),
                IconButton(
                  icon:
                      const Icon(Icons.copy_outlined, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text: '"${e.text}"\n\n— ${e.sourceLine}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(S.of(context, 'quran_copied'))),
                    );
                  },
                ),
                IconButton(
                  icon:
                      const Icon(Icons.share_outlined, size: 20),
                  onPressed: () => Share.share(
                      '"${e.text}"\n\n— ${e.sourceLine}\n(via Noor-e-Deen)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
