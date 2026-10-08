import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/offline_banner.dart';
import '../../l10n/strings.dart';

/// Islamic audio library.
///
/// Quran recitation streams from everyayah.com (public streaming CDN,
/// no key required — the same endpoints used by many open Quran apps).
/// Streams require internet; the rest of the app stays offline-first.
///
/// Dua/adhkar audio: only bundled/licensed recordings are offered.
/// Anything without a licensed source shows an honest "pending" note —
/// never a fake play button.
class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

/// Public everyayah.com reciter slugs (streaming, no key).
/// Source: https://everyayah.com — community Quran audio CDN.
class _Reciter {
  const _Reciter(this.slug, this.name);
  final String slug;
  final String name;
}

const _reciters = [
  _Reciter('Alafasy_128kbps', 'Mishary Rashid Alafasy'),
  _Reciter('AbdulSamad_64kbps_QuranExplorer_Com', 'Abdul Basit Abdul Samad'),
  _Reciter('Husary_128kbps', 'Mahmoud Khalil Al-Husary'),
  _Reciter('Minshawy_Murattal_128kbps', 'Mohamed Siddiq El-Minshawy'),
  _Reciter('Abdullah_Basfar_192kbps', 'Abdullah Basfar'),
];

class _AudioScreenState extends State<AudioScreen> {
  final AudioPlayer _player = AudioPlayer();
  List<Map<String, dynamic>> _surahs = [];
  _Reciter _reciter = _reciters.first;
  int _surahId = 1;
  int _ayahCount = 7;
  bool _loadingSurahs = true;
  bool _preparing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/quran/surahs.json');
      final list = (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _surahs = list;
        _loadingSurahs = false;
      });
    } catch (e) {
      setState(() {
        _loadingSurahs = false;
        _error = e.toString();
      });
    }
  }

  String _url(int surah, int ayah) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/${_reciter.slug}/$s$a.mp3';
  }

  Future<void> _playSurah() async {
    setState(() {
      _preparing = true;
      _error = null;
    });
    try {
      final sources = [
        for (var a = 1; a <= _ayahCount; a++)
          AudioSource.uri(
            Uri.parse(_url(_surahId, a)),
            tag: (_surahId, a),
          ),
      ];
      await _player.setAudioSources(sources);
      await _player.play();
    } catch (e) {
      setState(() => _error = S.of(context, 'audio_stream_error'));
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surah = _surahs.cast<Map<String, dynamic>?>().firstWhere(
          (s) => s != null && (s['id'] as num).toInt() == _surahId,
          orElse: () => null,
        );
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'audio_title'))),
      body: Column(
        children: [
          // Phase 6: audio streams need the internet.
          const OfflineBanner(),
          Expanded(
            child: _loadingSurahs
                ? LoadingView(label: S.of(context, 'common_loading'))
                : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                InfoCard(
                  icon: Icons.info_outline,
                  title: S.of(context, 'audio_source_title'),
                  body: S.of(context, 'audio_source_body'),
                ),
                SectionTitle(S.of(context, 'audio_reciter')),
                DropdownButtonFormField<_Reciter>(
                  initialValue: _reciter,
                  items: [
                    for (final r in _reciters)
                      DropdownMenuItem(value: r, child: Text(r.name)),
                  ],
                  onChanged: (r) {
                    if (r == null) return;
                    setState(() => _reciter = r);
                    _player.stop();
                  },
                ),
                SectionTitle(S.of(context, 'audio_surah')),
                DropdownButtonFormField<int>(
                  initialValue: _surahId,
                  isExpanded: true,
                  items: [
                    for (final s in _surahs)
                      DropdownMenuItem(
                        value: (s['id'] as num).toInt(),
                        child: Text(
                          '${(s['id'] as num).toInt()}. ${s['name']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    final count = (_surahs.firstWhere((s) =>
                            (s['id'] as num).toInt() == v)['verses'] as num)
                        .toInt();
                    setState(() {
                      _surahId = v;
                      _ayahCount = count;
                    });
                    _player.stop();
                  },
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _preparing ? null : _playSurah,
                  icon: _preparing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    S.of(context, 'audio_play_surah').replaceAll(
                        '{name}', surah?['name'] as String? ?? ''),
                  ),
                ),
                const SizedBox(height: 16),
                _PlayerControls(player: _player),
                const SizedBox(height: 8),
                InfoCard(
                  icon: Icons.music_note_outlined,
                  title: S.of(context, 'audio_dua_title'),
                  body: S.of(context, 'audio_dua_body'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({required this.player});
  final AudioPlayer player;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snap) {
        final state = snap.data;
        final playing = state?.playing ?? false;
        final processing = state?.processingState;
        if (processing == ProcessingState.idle) {
          return Center(
            child: Text(
              S.of(context, 'audio_idle'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                StreamBuilder<int?>(
                  stream: player.currentIndexStream,
                  builder: (context, idxSnap) {
                    final idx = idxSnap.data;
                    return Text(
                      idx == null
                          ? ''
                          : S.of(context, 'audio_ayah').replaceAll(
                              '{n}', '${idx + 1}'),
                      style: Theme.of(context).textTheme.titleSmall,
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 32),
                      onPressed: player.hasPrevious
                          ? player.seekToPrevious
                          : null,
                    ),
                    IconButton(
                      icon: Icon(
                        playing
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 52,
                      ),
                      onPressed: () {
                        if (playing) {
                          player.pause();
                        } else {
                          player.play();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 32),
                      onPressed:
                          player.hasNext ? player.seekToNext : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop, size: 28),
                      onPressed: player.stop,
                    ),
                  ],
                ),
                if (!kIsWeb)
                  StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, posSnap) {
                      final pos = posSnap.data ?? Duration.zero;
                      final dur = player.duration ?? Duration.zero;
                      return Slider(
                        value: dur.inMilliseconds == 0
                            ? 0
                            : pos.inMilliseconds /
                                dur.inMilliseconds.clamp(1, 1 << 31),
                        onChanged: (v) => player.seek(
                          Duration(
                              milliseconds:
                                  (v * dur.inMilliseconds).round()),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
