import 'package:flutter/material.dart';

import '../../core/services/location_service.dart';
import '../../core/services/prayer_service.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/common_widgets.dart';
import '../../l10n/strings.dart';
import '../settings/settings_screen.dart';

/// Full prayer-times screen: timetable, calculation method, Asr method,
/// per-prayer manual adjustments and location controls.
///
/// All calculations are offline (adhan package). Every failure mode
/// (GPS denied, no position, calc error) shows a friendly state — never
/// a crash.
class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
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

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'prayer_title'))),
      body: FutureBuilder<ResolvedLocation>(
        future: _locationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingView(label: S.of(context, 'common_loading'));
          }
          final loc = snapshot.data;
          if (snapshot.hasError || loc == null) {
            return ErrorView(
              message: S.of(context, 'common_error'),
              retryLabel: S.of(context, 'common_retry'),
              onRetry: _refresh,
            );
          }
          PrayerDay? day;
          try {
            day = PrayerService.calculate(
              latitude: loc.lat,
              longitude: loc.lon,
              date: DateTime.now(),
              methodId: state.calcMethod,
              asrMethod: state.asrMethod,
              adjustments: state.adjustments,
            );
          } catch (_) {
            day = null;
          }
          return _buildBody(context, state, loc, day);
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppState state,
    ResolvedLocation loc,
    PrayerDay? day,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _LocationCard(location: loc, onRefresh: _refresh),
        SectionTitle(S.of(context, 'home_today')),
        if (day == null)
          ErrorView(
            message: S.of(context, 'common_error'),
            retryLabel: S.of(context, 'common_retry'),
            onRetry: _refresh,
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final entry in day.entries)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        entry.id == day.nextId
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: entry.id == day.nextId
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                      title: Text(
                        S.of(context, 'prayer_${entry.id}'),
                        style: TextStyle(
                          fontWeight: entry.id == day.nextId
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        TimeFormat.hm(context, entry.time),
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
          ),
        SectionTitle(S.of(context, 'settings_prayer')),
        _MethodTile(state: state),
        _AsrTile(state: state),
        SectionTitle(S.of(context, 'prayer_adjust')),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final key in AppState.prayerKeys)
                  _AdjustmentRow(prayerKey: key, state: state),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location, required this.onRefresh});

  final ResolvedLocation location;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = AppStateScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_outlined, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  S.of(context, 'prayer_location'),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  tooltip: S.of(context, 'prayer_refresh'),
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(location.label),
            if (location.usedFallback) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: colors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        S.of(context, 'prayer_gps_issue'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    );
                  },
                  child: Text(S.of(context, 'prayer_open_settings')),
                ),
              ),
            ] else
              Text(
                state.locationMode == 'gps'
                    ? S.of(context, 'prayer_gps')
                    : S.of(context, 'prayer_manual'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calculate_outlined),
        title: Text(S.of(context, 'prayer_method')),
        subtitle: Text(S.of(context, 'method_${state.calcMethod}')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _pickMethod(context),
      ),
    );
  }

  Future<void> _pickMethod(BuildContext context) async {
    final String? picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(S.of(ctx, 'prayer_method')),
        children: [
          for (final id in PrayerService.supportedMethods)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(S.of(ctx, 'method_$id')),
              ),
            ),
        ],
      ),
    );
    if (picked != null) {
      state.setCalcMethod(picked);
    }
  }
}

class _AsrTile extends StatelessWidget {
  const _AsrTile({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context, 'prayer_asr'),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'standard',
                  label: Text(S.of(context, 'prayer_asr_standard')),
                ),
                ButtonSegment(
                  value: 'hanafi',
                  label: Text(S.of(context, 'prayer_asr_hanafi')),
                ),
              ],
              selected: {state.asrMethod},
              onSelectionChanged: (sel) => state.setAsrMethod(sel.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustmentRow extends StatelessWidget {
  const _AdjustmentRow({required this.prayerKey, required this.state});

  final String prayerKey;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final int value = state.adjustments[prayerKey] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(S.of(context, 'prayer_$prayerKey'))),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: value <= -30
                ? null
                : () => state.setAdjustment(prayerKey, value - 1),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '${value >= 0 ? '+' : ''}$value',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: value >= 30
                ? null
                : () => state.setAdjustment(prayerKey, value + 1),
          ),
        ],
      ),
    );
  }
}
