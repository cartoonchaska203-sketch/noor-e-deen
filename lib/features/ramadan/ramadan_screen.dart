import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/services/location_service.dart';
import '../../core/services/prayer_service.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';

/// Ramadan mode: auto-activates in Hijri month 9. Sehri/Iftar times,
/// fasting tracker, Taraweeh info, Quran khatm planner, Laylat-ul-Qadr
/// planner and a simple charity log.
class RamadanScreen extends StatefulWidget {
  const RamadanScreen({super.key});

  @override
  State<RamadanScreen> createState() => _RamadanScreenState();
}

class _RamadanScreenState extends State<RamadanScreen> {
  final _repo = UserDataRepository.instance;
  late Future<_RamadanData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_RamadanData> _load() async {
    final state = AppState.instance;
    final loc = await LocationService.resolve(
      mode: state.locationMode,
      manualCityName: state.manualCity,
    );
    final day = PrayerService.calculate(
      latitude: loc.lat,
      longitude: loc.lon,
      date: DateTime.now(),
      methodId: state.calcMethod,
      asrMethod: state.asrMethod,
      adjustments: state.adjustments,
    );
    final hijri = HijriCalendar.now();
    final log = await _repo.fastingLog();
    final paras = await _repo.khatmParas();
    return _RamadanData(day: day, hijri: hijri, log: log, paras: paras);
  }

  void _reload() => setState(() => _future = _load());

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'ramadan_title'))),
      body: FutureBuilder<_RamadanData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return LoadingView(label: S.of(context, 'common_loading'));
          }
          if (snap.hasError || !snap.hasData) {
            return ErrorView(
              message: S.of(context, 'common_error'),
              retryLabel: S.of(context, 'common_retry'),
              onRetry: _reload,
            );
          }
          return _buildBody(context, snap.data!);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, _RamadanData d) {
    final isRamadan = d.hijri.hMonth == 9;
    final fajr = d.day.entries.firstWhere((e) => e.id == 'fajr').time;
    final maghrib = d.day.entries.firstWhere((e) => e.id == 'maghrib').time;
    // Sehri ends at Fajr; show a 10-minute safety buffer note.
    final sehriEnd = fajr;
    final todayKey = _dateKey(DateTime.now());
    final todayStatus = d.log[todayKey];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!isRamadan)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      S.of(context, 'ramadan_not_now'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.nights_stay,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      S
                          .of(context, 'ramadan_active')
                          .replaceAll('{n}', '${d.hijri.hDay}'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SectionTitle(S.of(context, 'ramadan_sehri_iftar')),
        Row(
          children: [
            Expanded(
              child: _TimeCard(
                icon: Icons.restaurant_outlined,
                label: S.of(context, 'ramadan_sehri'),
                time: TimeFormat.hm(context, sehriEnd),
                note: S.of(context, 'ramadan_sehri_note'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimeCard(
                icon: Icons.dinner_dining_outlined,
                label: S.of(context, 'ramadan_iftar'),
                time: TimeFormat.hm(context, maghrib),
                note: S.of(context, 'ramadan_iftar_note'),
              ),
            ),
          ],
        ),
        SectionTitle(S.of(context, 'ramadan_fast_today')),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context, 'ramadan_fast_status'),
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in ['fasted', 'missed', 'excused', 'makeup_done'])
                      ChoiceChip(
                        label: Text(S.of(context, 'ramadan_$s')),
                        selected: todayStatus == s,
                        onSelected: (_) async {
                          await _repo.setFastStatus(todayKey, s);
                          _reload();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _fastStats(d.log),
              ],
            ),
          ),
        ),
        SectionTitle(S.of(context, 'ramadan_taraweeh')),
        InfoCard(
          icon: Icons.mosque_outlined,
          title: S.of(context, 'ramadan_taraweeh_title'),
          body: S.of(context, 'ramadan_taraweeh_body'),
        ),
        SectionTitle(S.of(context, 'ramadan_khatm')),
        _khatmPlanner(d),
        SectionTitle(S.of(context, 'ramadan_qadr')),
        InfoCard(
          icon: Icons.star_border,
          title: S.of(context, 'ramadan_qadr_title'),
          body: S.of(context, 'ramadan_qadr_body'),
        ),
        SectionTitle(S.of(context, 'ramadan_charity')),
        InfoCard(
          icon: Icons.volunteer_activism_outlined,
          title: S.of(context, 'ramadan_charity_title'),
          body: S.of(context, 'ramadan_charity_body'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _fastStats(Map<String, String> log) {
    final fasted = log.values.where((v) => v == 'fasted').length;
    final missed = log.values.where((v) => v == 'missed').length;
    final makeup = log.values.where((v) => v == 'makeup_done').length;
    return Text(
      S
          .of(context, 'ramadan_stats')
          .replaceAll('{f}', '$fasted')
          .replaceAll('{m}', '$missed')
          .replaceAll('{u}', '$makeup'),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  Widget _khatmPlanner(_RamadanData d) {
    final done = d.paras.length;
    final remaining = 30 - done;
    // Approximate days left in Ramadan (Hijri month length 29/30).
    final hijriLen = d.hijri.lengthOfMonth;
    final daysLeft = (hijriLen - d.hijri.hDay).clamp(1, 30);
    final perDay = remaining <= 0 ? 0 : (remaining / daysLeft);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.of(context, 'ramadan_khatm_progress'),
                    style: Theme.of(context).textTheme.titleSmall),
                Text('$done / 30',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: done / 30),
            const SizedBox(height: 8),
            Text(
              S
                  .of(context, 'ramadan_khatm_plan')
                  .replaceAll('{r}', '$remaining')
                  .replaceAll('{d}', '$daysLeft')
                  .replaceAll('{p}', perDay.toStringAsFixed(1)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 1; i <= 30; i++)
                  FilterChip(
                    label: Text('$i'),
                    selected: d.paras.contains('$i'),
                    onSelected: (_) async {
                      await _repo.toggleKhatmPara('$i');
                      _reload();
                    },
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RamadanData {
  _RamadanData({
    required this.day,
    required this.hijri,
    required this.log,
    required this.paras,
  });

  final PrayerDay day;
  final HijriCalendar hijri;
  final Map<String, String> log;
  final Set<String> paras;
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.icon,
    required this.label,
    required this.time,
    required this.note,
  });

  final IconData icon;
  final String label;
  final String time;
  final String note;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: colors.primary, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(time,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(note,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
