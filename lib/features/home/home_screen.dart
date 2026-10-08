import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/services/location_service.dart';
import '../../core/services/prayer_service.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/pattern_painter.dart';
import '../../data/models/models.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/hadith_repository.dart';
import '../../data/repositories/quran_repository.dart';
import '../../l10n/strings.dart';
import '../duas/duas_screens.dart';
import '../hadith/hadith_screens.dart';
import '../qibla/qibla_screen.dart';
import '../quran/surah_reader_screen.dart';
import '../settings/settings_screen.dart';

/// Home dashboard: live clock, Gregorian + Hijri dates, location, today's
/// prayer timetable with a live countdown to the next prayer, quick actions
/// and daily content cards (ayah / hadith / dua, loaded from the verified
/// bundled datasets).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final void Function(int index) onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<ResolvedLocation> _locationFuture;

  @override
  void initState() {
    super.initState();
    _locationFuture = _resolve();
  }

  Future<ResolvedLocation> _resolve() {
    final state = AppState.instance;
    return LocationService.resolve(
      mode: state.locationMode,
      manualCityName: state.manualCity,
    );
  }

  void _refresh() {
    setState(() {
      _locationFuture = _resolve();
    });
  }

  String _hijriToday() {
    try {
      final HijriCalendar h = HijriCalendar.now();
      return '${h.toFormat('dd/MM/yyyy')} AH';
    } catch (_) {
      return S.of(context, 'hijri_unavailable');
    }
  }

  PrayerDay? _prayerDayFor(ResolvedLocation loc) {
    try {
      final state = AppState.instance;
      return PrayerService.calculate(
        latitude: loc.lat,
        longitude: loc.lon,
        date: DateTime.now(),
        methodId: state.calcMethod,
        asrMethod: state.asrMethod,
        adjustments: state.adjustments,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResolvedLocation>(
      future: _locationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: LoadingView(label: S.of(context, 'common_loading')),
          );
        }
        final loc = snapshot.data;
        if (snapshot.hasError || loc == null) {
          return Scaffold(
            body: ErrorView(
              message: S.of(context, 'common_error'),
              retryLabel: S.of(context, 'common_retry'),
              onRetry: _refresh,
            ),
          );
        }
        return _buildContent(context, loc);
      },
    );
  }

  Widget _buildContent(BuildContext context, ResolvedLocation loc) {
    return Scaffold(
      body: StreamBuilder<int>(
        stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
        builder: (context, tick) {
          final now = DateTime.now();
          final PrayerDay? day = _prayerDayFor(loc);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  now: now,
                  hijri: _hijriToday(),
                  location: loc,
                  onRefresh: _refresh,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (loc.usedFallback) _FallbackBanner(location: loc),
                    if (day != null) ...[
                      _NextPrayerCard(day: day, now: now),
                      SectionTitle(S.of(context, 'home_today')),
                      _TimetableCard(day: day),
                    ] else
                      ErrorView(
                        message: S.of(context, 'common_error'),
                        retryLabel: S.of(context, 'common_retry'),
                        onRetry: _refresh,
                      ),
                    _QuickActions(onNavigate: widget.onNavigate),
                    SectionTitle(S.of(context, 'daily_ayah_title')),
                    _DailyAyahCard(onOpen: () => widget.onNavigate(1)),
                    const SizedBox(height: 12),
                    _DailyHadithCard(onOpen: () => widget.onNavigate(3)),
                    const SizedBox(height: 12),
                    _DailyDuaCard(onOpen: () => widget.onNavigate(3)),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.now,
    required this.hijri,
    required this.location,
    required this.onRefresh,
  });

  final DateTime now;
  final String hijri;
  final ResolvedLocation location;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return PatternHeader(
      height: 248,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mosque, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Noor-e-Deen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        S.of(context, 'app_tagline'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                TimeFormat.hm(context, now),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                TimeFormat.gregorian(now, state.localeCode),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
              ),
              Text(
                hijri,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: onRefresh,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          location.label,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.refresh,
                          color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackBanner extends StatelessWidget {
  const _FallbackBanner({required this.location});

  final ResolvedLocation location;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.secondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${S.of(context, 'home_using_fallback')}: ${location.label}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: Text(S.of(context, 'prayer_open_settings')),
          ),
        ],
      ),
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard({required this.day, required this.now});

  final PrayerDay day;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final remaining = day.nextTime.difference(now);
    return Card(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              colors.primary.withValues(alpha: 0.14),
              colors.secondary.withValues(alpha: 0.10),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.notifications_active_outlined,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context, 'home_next_prayer'),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    S.of(context, 'prayer_${day.nextId}'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${TimeFormat.hm(context, day.nextTime)} · ${S.of(context, 'home_in')} ${TimeFormat.countdown(remaining)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimetableCard extends StatelessWidget {
  const _TimetableCard({required this.day});

  final PrayerDay day;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (final entry in day.entries)
              _TimetableRow(
                entry: entry,
                isNext: entry.id == day.nextId,
                highlight: colors,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimetableRow extends StatelessWidget {
  const _TimetableRow({
    required this.entry,
    required this.isNext,
    required this.highlight,
  });

  final PrayerEntry entry;
  final bool isNext;
  final ColorScheme highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isNext
            ? highlight.primary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isNext
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 16,
            color: isNext ? highlight.primary : highlight.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              S.of(context, 'prayer_${entry.id}'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
          Text(
            TimeFormat.hm(context, entry.time),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                  color: isNext ? highlight.primary : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNavigate});

  final void Function(int index) onNavigate;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.schedule_outlined,
        label: S.of(context, 'quick_prayer'),
        onTap: () => onNavigate(2),
      ),
      _QuickAction(
        icon: Icons.explore_outlined,
        label: S.of(context, 'quick_qibla'),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QiblaScreen()),
          );
        },
      ),
      _QuickAction(
        icon: Icons.menu_book_outlined,
        label: S.of(context, 'quick_quran'),
        onTap: () => onNavigate(1),
      ),
      _QuickAction(
        icon: Icons.timelapse_outlined,
        label: S.of(context, 'quick_tasbeeh'),
        onTap: () => onNavigate(3),
      ),
      _QuickAction(
        icon: Icons.favorite_outline,
        label: S.of(context, 'quick_duas'),
        onTap: () => onNavigate(3),
      ),
      _QuickAction(
        icon: Icons.settings_outlined,
        label: S.of(context, 'quick_settings'),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemCount: actions.length,
          itemBuilder: (context, i) {
            final a = actions[i];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: a.onTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(a.icon,
                        color: Theme.of(context).colorScheme.primary,
                        size: 26),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        a.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QuickAction {
  _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Daily ayah card — real text from the bundled verified dataset.
class _DailyAyahCard extends StatelessWidget {
  const _DailyAyahCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Ayah>(
      future: QuranRepository.instance.ayahOfTheDay(DateTime.now()),
      builder: (context, snap) {
        final ayah = snap.data;
        return InfoCard(
          icon: Icons.menu_book_outlined,
          title: ayah == null
              ? S.of(context, 'common_loading')
              : 'Quran ${ayah.ref}',
          body: ayah == null ? '' : ayah.arabic,
          onTap: ayah == null
              ? null
              : () async {
                  final surahs =
                      await QuranRepository.instance.surahs();
                  final meta = surahs
                      .firstWhere((s) => s.id == ayah.surah);
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SurahReaderScreen(
                          surah: meta,
                          initialAyah: ayah.number,
                        ),
                      ),
                    );
                  }
                },
        );
      },
    );
  }
}

/// Daily hadith card — real text with source line from bundled data.
class _DailyHadithCard extends StatelessWidget {
  const _DailyHadithCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HadithEntry>(
      future:
          HadithRepository.instance.hadithOfTheDay(DateTime.now()),
      builder: (context, snap) {
        final h = snap.data;
        final text = h?.text ?? '';
        final preview =
            text.length > 140 ? '${text.substring(0, 140)}…' : text;
        return InfoCard(
          icon: Icons.history_edu_outlined,
          title: h == null
              ? S.of(context, 'common_loading')
              : h.sourceLine,
          body: preview,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const HadithHomeScreen()),
          ),
        );
      },
    );
  }
}

/// Daily dua card — real text with source from the curated dataset.
class _DailyDuaCard extends StatelessWidget {
  const _DailyDuaCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Dua>(
      future: ContentRepository.instance.duaOfTheDay(DateTime.now()),
      builder: (context, snap) {
        final d = snap.data;
        return InfoCard(
          icon: Icons.favorite_outline,
          title: d == null
              ? S.of(context, 'common_loading')
              : '${d.title} · ${d.source}',
          body: d?.arabic ?? '',
          onTap: d == null
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => DuaDetailScreen(dua: d)),
                  ),
        );
      },
    );
  }
}
