import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';

/// Full surah reader: Arabic (Amiri Quran font) + Urdu + English,
/// bookmarks, copy/share, font controls, reading progress.
class SurahReaderScreen extends StatefulWidget {
  const SurahReaderScreen({
    super.key,
    required this.surah,
    this.initialAyah,
  });

  final SurahMeta surah;
  final int? initialAyah;

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  Future<List<Ayah>>? _ayahsFuture;
  final ScrollController _scroll = ScrollController();
  double _fontScale = 1.0;
  bool _showUrdu = true;
  bool _showEnglish = true;
  Set<String> _bookmarks = {};
  Set<String> _favorites = {};
  int _visibleAyah = 1;

  @override
  void initState() {
    super.initState();
    _ayahsFuture = QuranRepository.instance.ayahs(widget.surah.id);
    _initPrefs();
    _scroll.addListener(_onScroll);
  }

  Future<void> _initPrefs() async {
    final repo = UserDataRepository.instance;
    final results = await Future.wait([
      repo.quranFontScale(),
      repo.ayahBookmarks(),
      repo.ayahFavorites(),
    ]);
    if (mounted) {
      setState(() {
        _fontScale = results[0] as double;
        _bookmarks = results[1] as Set<String>;
        _favorites = results[2] as Set<String>;
      });
    }
    // Jump to requested ayah after first layout.
    if (widget.initialAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToAyah());
    }
  }

  void _jumpToAyah() {
    final target = (widget.initialAyah ?? 1) - 1;
    if (target <= 0 || !_scroll.hasClients) return;
    // Approximate offset: each ayah card ~ variable height; use item jump
    // via a generous estimate then let the user fine-scroll.
    _scroll.jumpTo((target * 220 * _fontScale).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    ));
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final idx = (_scroll.offset / (220 * _fontScale)).round().clamp(0, 1 << 30);
    final ayahNo = idx + 1;
    if (ayahNo != _visibleAyah) {
      _visibleAyah = ayahNo;
      UserDataRepository.instance.saveLastRead(widget.surah.id, ayahNo);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.surah.name),
            Text(
              '${widget.surah.arabicName} · ${widget.surah.versesCount} ${S.of(context, 'quran_ayahs')}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: S.of(context, 'quran_font_size'),
            onPressed: _showReaderSettings,
          ),
        ],
      ),
      body: FutureBuilder<List<Ayah>>(
        future: _ayahsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return LoadingView(label: S.of(context, 'common_loading'));
          }
          if (snap.hasError || !snap.hasData) {
            return ErrorView(
              message: S.of(context, 'common_error'),
              retryLabel: S.of(context, 'common_retry'),
              onRetry: () => setState(() {
                _ayahsFuture =
                    QuranRepository.instance.ayahs(widget.surah.id);
              }),
            );
          }
          final ayahs = snap.data!;
          return Column(
            children: [
              _ProgressBar(
                read: _visibleAyah.clamp(1, ayahs.length),
                total: ayahs.length,
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: ayahs.length,
                  itemBuilder: (context, i) => _AyahCard(
                    ayah: ayahs[i],
                    fontScale: _fontScale,
                    showUrdu: _showUrdu,
                    showEnglish: _showEnglish,
                    bookmarked: _bookmarks.contains(ayahs[i].ref),
                    favorite: _favorites.contains(ayahs[i].ref),
                    onBookmark: () => _toggleBookmark(ayahs[i]),
                    onFavorite: () => _toggleFavorite(ayahs[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleBookmark(Ayah a) async {
    await UserDataRepository.instance.toggleAyahBookmark(a.ref);
    final bm = await UserDataRepository.instance.ayahBookmarks();
    if (mounted) setState(() => _bookmarks = bm);
  }

  Future<void> _toggleFavorite(Ayah a) async {
    await UserDataRepository.instance.toggleAyahFavorite(a.ref);
    final fav = await UserDataRepository.instance.ayahFavorites();
    if (mounted) setState(() => _favorites = fav);
  }

  void _showReaderSettings() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context, 'quran_reader_settings'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(S.of(context, 'quran_font_size')),
                  Expanded(
                    child: Slider(
                      value: _fontScale,
                      min: 0.8,
                      max: 1.6,
                      divisions: 8,
                      label: _fontScale.toStringAsFixed(1),
                      onChanged: (v) {
                        setSheet(() {});
                        setState(() => _fontScale = v);
                        UserDataRepository.instance.setQuranFontScale(v);
                      },
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                title: Text(S.of(context, 'quran_show_urdu')),
                value: _showUrdu,
                onChanged: (v) {
                  setSheet(() {});
                  setState(() => _showUrdu = v);
                },
              ),
              SwitchListTile(
                title: Text(S.of(context, 'quran_show_english')),
                value: _showEnglish,
                onChanged: (v) {
                  setSheet(() {});
                  setState(() => _showEnglish = v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.read, required this.total});

  final int read;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : read / total,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 8),
          Text('$read / $total',
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({
    required this.ayah,
    required this.fontScale,
    required this.showUrdu,
    required this.showEnglish,
    required this.bookmarked,
    required this.favorite,
    required this.onBookmark,
    required this.onFavorite,
  });

  final Ayah ayah;
  final double fontScale;
  final bool showUrdu;
  final bool showEnglish;
  final bool bookmarked;
  final bool favorite;
  final VoidCallback onBookmark;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ayah.ref,
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    bookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 20,
                  ),
                  tooltip: S.of(context, 'quran_bookmark'),
                  onPressed: onBookmark,
                ),
                IconButton(
                  icon: Icon(
                    favorite ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                  ),
                  tooltip: S.of(context, 'quran_favorite'),
                  onPressed: onFavorite,
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  tooltip: S.of(context, 'quran_share'),
                  onPressed: () => _share(context),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  tooltip: S.of(context, 'quran_copy'),
                  onPressed: () => _copy(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ayah.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 24 * fontScale,
                height: 2.0,
              ),
            ),
            if (showUrdu && ayah.urdu.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                ayah.urdu,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 15 * fontScale, height: 1.8),
              ),
            ],
            if (showEnglish && ayah.english.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                ayah.english,
                style: TextStyle(
                  fontSize: 14 * fontScale,
                  height: 1.6,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _shareText() =>
      '${ayah.arabic}\n\n${ayah.english}\n\n— Quran ${ayah.ref} (via Noor-e-Deen)';

  void _share(BuildContext context) {
    Share.share(_shareText());
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _shareText()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context, 'quran_copied'))),
    );
  }
}
