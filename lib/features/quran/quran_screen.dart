import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';
import 'surah_reader_screen.dart';

/// Quran tab: surah list (searchable) + Juz/Para index + bookmarks.
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  Future<List<SurahMeta>>? _surahsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  void _load() {
    _surahsFuture = QuranRepository.instance.surahs();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context, 'quran_title')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: S.of(context, 'quran_tab_surahs')),
            Tab(text: S.of(context, 'quran_tab_juz')),
            Tab(text: S.of(context, 'quran_tab_saved')),
          ],
        ),
      ),
      body: FutureBuilder<List<SurahMeta>>(
        future: _surahsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return LoadingView(label: S.of(context, 'common_loading'));
          }
          if (snap.hasError || !snap.hasData) {
            return ErrorView(
              message: S.of(context, 'common_error'),
              retryLabel: S.of(context, 'common_retry'),
              onRetry: () => setState(_load),
            );
          }
          final surahs = snap.data!;
          return TabBarView(
            controller: _tabs,
            children: [
              _SurahList(
                surahs: surahs,
                query: _query,
                onQuery: (q) => setState(() => _query = q),
              ),
              _JuzList(surahs: surahs),
              const _SavedList(),
            ],
          );
        },
      ),
    );
  }
}

class _SurahList extends StatelessWidget {
  const _SurahList({
    required this.surahs,
    required this.query,
    required this.onQuery,
  });

  final List<SurahMeta> surahs;
  final String query;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? surahs
        : surahs
            .where((s) =>
                s.name.toLowerCase().contains(q) ||
                s.arabicName.contains(query.trim()) ||
                s.id.toString() == q)
            .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: S.of(context, 'quran_search_hint'),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: onQuery,
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(S.of(context, 'quran_no_results')))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final s = filtered[i];
                    return ListTile(
                      leading: _NumberBadge(number: s.id),
                      title: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${s.meaning} · ${s.versesCount} ${S.of(context, 'quran_ayahs')} · ${s.revelation == 'makkah' ? S.of(context, 'quran_makki') : S.of(context, 'quran_madani')}',
                      ),
                      trailing: Text(
                        s.arabicName,
                        style: const TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 22,
                        ),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SurahReaderScreen(surah: s),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _JuzList extends StatelessWidget {
  const _JuzList({required this.surahs});

  final List<SurahMeta> surahs;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 30,
      itemBuilder: (context, i) {
        final juz = i + 1;
        final start = QuranRepository.juzStarts[juz]!;
        final surah = surahs.firstWhere((s) => s.id == start[0]);
        return ListTile(
          leading: _NumberBadge(number: juz),
          title: Text('${S.of(context, 'quran_juz')} $juz'),
          subtitle: Text(
            '${S.of(context, 'quran_starts_at')} ${surah.name} ${start[0]}:${start[1]}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SurahReaderScreen(
                surah: surah,
                initialAyah: start[1],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SavedList extends StatefulWidget {
  const _SavedList();

  @override
  State<_SavedList> createState() => _SavedListState();
}

class _SavedListState extends State<_SavedList> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SurahMeta>>(
      future: QuranRepository.instance.surahs(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return LoadingView(label: S.of(context, 'common_loading'));
        }
        final surahs = snap.data!;
        return FutureBuilder<Set<String>>(
          future: UserDataRepository.instance.ayahBookmarks(),
          builder: (context, bsnap) {
            final bookmarks = (bsnap.data ?? {}).toList()..sort();
            if (bookmarks.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    S.of(context, 'quran_no_bookmarks'),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: bookmarks.length,
              itemBuilder: (context, i) {
                final parts = bookmarks[i].split(':');
                final sId = int.parse(parts[0]);
                final aNo = int.parse(parts[1]);
                final surah = surahs.firstWhere((s) => s.id == sId);
                return ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: Text('${surah.name} · $sId:$aNo'),
                  subtitle: Text(surah.arabicName,
                      style: const TextStyle(fontFamily: 'AmiriQuran')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => SurahReaderScreen(
                            surah: surah,
                            initialAyah: aNo,
                          ),
                        ),
                      )
                      .then((_) => setState(() {})),
                );
              },
            );
          },
        );
      },
    );
  }
}
