import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';
import '../quran/surah_reader_screen.dart';

/// Hifz (memorization) tracker: per-ayah states, hide/reveal mode,
/// spaced-repetition due list, targets and progress charts.
class HifzScreen extends StatefulWidget {
  const HifzScreen({super.key});

  @override
  State<HifzScreen> createState() => _HifzScreenState();
}

class _HifzScreenState extends State<HifzScreen>
    with SingleTickerProviderStateMixin {
  final _repo = UserDataRepository.instance;
  late TabController _tabs;
  late Future<_HifzData> _future;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _future = _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<_HifzData> _load() async {
    final states = await _repo.hifzStates();
    final weak = await _repo.hifzWeak();
    final revised = await _repo.hifzRevisedDates();
    final targets = await _repo.hifzTargets();
    final due = await _repo.hifzDue();
    final surahs = await QuranRepository.instance.surahs();
    return _HifzData(
      states: states,
      weak: weak,
      revised: revised,
      targets: targets,
      due: due,
      surahs: surahs,
    );
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context, 'hifz_title')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: S.of(context, 'hifz_tab_track')),
            Tab(text: S.of(context, 'hifz_tab_due')),
            Tab(text: S.of(context, 'hifz_tab_stats')),
          ],
        ),
      ),
      body: FutureBuilder<_HifzData>(
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
          final d = snap.data!;
          return TabBarView(
            controller: _tabs,
            children: [
              _TrackTab(data: d, onChanged: _reload),
              _DueTab(data: d, onChanged: _reload),
              _StatsTab(data: d, onChanged: _reload),
            ],
          );
        },
      ),
    );
  }
}

class _HifzData {
  _HifzData({
    required this.states,
    required this.weak,
    required this.revised,
    required this.targets,
    required this.due,
    required this.surahs,
  });

  final Map<String, String> states;
  final Set<String> weak;
  final Map<String, String> revised;
  final Map<String, int> targets;
  final List<String> due;
  final List<SurahMeta> surahs;
}

// --- Track tab: pick a surah, mark ayahs ---
class _TrackTab extends StatefulWidget {
  const _TrackTab({required this.data, required this.onChanged});

  final _HifzData data;
  final VoidCallback onChanged;

  @override
  State<_TrackTab> createState() => _TrackTabState();
}

class _TrackTabState extends State<_TrackTab> {
  int? _surahId;

  @override
  Widget build(BuildContext context) {
    if (_surahId == null) return _surahPicker();
    return _AyahMarker(
      surahId: _surahId!,
      data: widget.data,
      onChanged: widget.onChanged,
      onBack: () => setState(() => _surahId = null),
    );
  }

  Widget _surahPicker() {
    final withProgress = widget.data.surahs.where((s) {
      return widget.data.states.keys.any((k) => k.startsWith('${s.id}:'));
    }).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InfoCard(
          icon: Icons.info_outline,
          title: S.of(context, 'hifz_how_title'),
          body: S.of(context, 'hifz_how_body'),
        ),
        const SizedBox(height: 8),
        Text(
          S.of(context, 'hifz_surahs_with_progress')
              .replaceAll('{n}', '$withProgress'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        for (final s in widget.data.surahs)
          _surahTile(s),
      ],
    );
  }

  Widget _surahTile(SurahMeta s) {
    final total = s.versesCount;
    final marked = widget.data.states.keys
        .where((k) => k.startsWith('${s.id}:'))
        .length;
    final memorized = widget.data.states.entries
        .where((e) =>
            e.key.startsWith('${s.id}:') && e.value == 'memorized')
        .length;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          child: Text('${s.id}',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700)),
        ),
        title: Text(s.name),
        subtitle: marked == 0
            ? null
            : LinearProgressIndicator(
                value: marked / total,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
        trailing: marked == 0
            ? const Icon(Icons.chevron_right)
            : Text('$memorized/$total',
                style: Theme.of(context).textTheme.labelSmall),
        onTap: () => setState(() => _surahId = s.id),
      ),
    );
  }
}

class _AyahMarker extends StatefulWidget {
  const _AyahMarker({
    required this.surahId,
    required this.data,
    required this.onChanged,
    required this.onBack,
  });

  final int surahId;
  final _HifzData data;
  final VoidCallback onChanged;
  final VoidCallback onBack;

  @override
  State<_AyahMarker> createState() => _AyahMarkerState();
}

class _AyahMarkerState extends State<_AyahMarker> {
  final _repo = UserDataRepository.instance;
  late Future<List<Ayah>> _ayahs;
  bool _hideMode = false;
  final _revealed = <String>{};

  @override
  void initState() {
    super.initState();
    _ayahs = QuranRepository.instance.ayahs(widget.surahId);
  }

  Future<void> _setState(String ref, String? state) async {
    await _repo.setHifzState(ref, state);
    if (state == 'memorized') await _repo.markHifzRevised(ref);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              Expanded(
                child: Text(
                  S.of(context, 'hifz_mark_title'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilterChip(
                label: Text(S.of(context, 'hifz_hide_mode')),
                selected: _hideMode,
                onSelected: (v) => setState(() {
                  _hideMode = v;
                  _revealed.clear();
                }),
              ),
            ],
          ),
        ),
        if (_hideMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(S.of(context, 'hifz_hide_hint'),
                style: Theme.of(context).textTheme.bodySmall),
          ),
        Expanded(
          child: FutureBuilder<List<Ayah>>(
            future: _ayahs,
            builder: (context, snap) {
              if (!snap.hasData) {
                return LoadingView(
                    label: S.of(context, 'common_loading'));
              }
              final ayahs = snap.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ayahs.length,
                itemBuilder: (context, i) {
                  final a = ayahs[i];
                  return _ayahTile(a);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _ayahTile(Ayah a) {
    final ref = a.ref;
    final state = widget.data.states[ref];
    final isWeak = widget.data.weak.contains(ref);
    final hidden = _hideMode && !_revealed.contains(ref);
    final colors = Theme.of(context).colorScheme;

    Color? stateColor;
    if (state == 'memorized') {
      stateColor = Colors.green;
    } else if (state == 'learning') {
      stateColor = Colors.amber.shade700;
    } else if (state == 'revision') {
      stateColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _hideMode
            ? () => setState(() {
                  if (_revealed.contains(ref)) {
                    _revealed.remove(ref);
                  } else {
                    _revealed.add(ref);
                  }
                })
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${a.number}',
                        style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  if (stateColor != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: stateColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        S.of(context, 'hifz_state_$state'),
                        style: TextStyle(
                            color: stateColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (isWeak)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.warning_amber,
                          size: 16, color: Colors.orange.shade700),
                    ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (v) {
                      if (v == 'weak') {
                        _repo.toggleHifzWeak(ref).then((_) => widget.onChanged());
                      } else if (v == 'revised') {
                        _repo.markHifzRevised(ref).then((_) => widget.onChanged());
                      } else if (v == 'open') {
                        final meta = widget.data.surahs.firstWhere(
                          (s) => s.id == a.surah,
                          orElse: () => widget.data.surahs.first,
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SurahReaderScreen(
                              surah: meta,
                              initialAyah: a.number,
                            ),
                          ),
                        );
                      } else {
                        _setState(ref, v == 'none' ? null : v);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'memorized',
                          child: Text(S.of(context, 'hifz_state_memorized'))),
                      PopupMenuItem(
                          value: 'learning',
                          child: Text(S.of(context, 'hifz_state_learning'))),
                      PopupMenuItem(
                          value: 'revision',
                          child: Text(S.of(context, 'hifz_state_revision'))),
                      PopupMenuItem(
                          value: 'none',
                          child: Text(S.of(context, 'hifz_state_none'))),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                          value: 'weak',
                          child: Text(isWeak
                              ? S.of(context, 'hifz_unmark_weak')
                              : S.of(context, 'hifz_mark_weak'))),
                      PopupMenuItem(
                          value: 'revised',
                          child: Text(S.of(context, 'hifz_mark_revised'))),
                      PopupMenuItem(
                          value: 'open',
                          child: Text(S.of(context, 'hifz_open_reader'))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              hidden
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(S.of(context, 'hifz_tap_reveal'),
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    )
                  : Text(
                      a.arabic,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: 20,
                        height: 2.0,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Due tab ---
class _DueTab extends StatelessWidget {
  const _DueTab({required this.data, required this.onChanged});

  final _HifzData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final repo = UserDataRepository.instance;
    final weakDue = data.due.where((r) => data.weak.contains(r)).toList();
    final rest = data.due.where((r) => !data.weak.contains(r)).toList();
    final ordered = [...weakDue, ...rest];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InfoCard(
          icon: Icons.schedule_outlined,
          title: S.of(context, 'hifz_due_title'),
          body: S.of(context, 'hifz_due_body'),
        ),
        const SizedBox(height: 8),
        if (ordered.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(S.of(context, 'hifz_due_empty'),
                    textAlign: TextAlign.center),
              ),
            ),
          )
        else
          for (final ref in ordered)
            Card(
              child: ListTile(
                leading: Icon(
                  data.weak.contains(ref)
                      ? Icons.warning_amber
                      : Icons.refresh,
                  color: data.weak.contains(ref)
                      ? Colors.orange.shade700
                      : Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  S.of(context, 'hifz_ayah_ref').replaceAll('{r}', ref),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                    '${S.of(context, 'hifz_state_${data.states[ref] ?? 'learning'}')}'
                    '${data.revised[ref] != null ? ' · ${S.of(context, 'hifz_last_revised')} ${data.revised[ref]}' : ''}'),
                trailing: FilledButton.tonal(
                  onPressed: () async {
                    await repo.markHifzRevised(ref);
                    onChanged();
                  },
                  child: Text(S.of(context, 'hifz_done')),
                ),
              ),
            ),
      ],
    );
  }
}

// --- Stats tab ---
class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.data, required this.onChanged});

  final _HifzData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final memorized =
        data.states.values.where((v) => v == 'memorized').length;
    final learning = data.states.values.where((v) => v == 'learning').length;
    final revision = data.states.values.where((v) => v == 'revision').length;
    final weak = data.weak.length;
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionTitle(S.of(context, 'hifz_overview')),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: S.of(context, 'hifz_state_memorized'),
                    value: '$memorized',
                    color: Colors.green)),
            const SizedBox(width: 8),
            Expanded(
                child: _StatCard(
                    label: S.of(context, 'hifz_state_learning'),
                    value: '$learning',
                    color: Colors.amber.shade700)),
            const SizedBox(width: 8),
            Expanded(
                child: _StatCard(
                    label: S.of(context, 'hifz_state_revision'),
                    value: '$revision',
                    color: Colors.blue)),
            const SizedBox(width: 8),
            Expanded(
                child: _StatCard(
                    label: S.of(context, 'hifz_weak_label'),
                    value: '$weak',
                    color: Colors.orange.shade700)),
          ],
        ),
        SectionTitle(S.of(context, 'hifz_distribution')),
        SizedBox(
          height: 220,
          child: (memorized + learning + revision) == 0
              ? Center(
                  child: Text(S.of(context, 'hifz_no_data'),
                      style: Theme.of(context).textTheme.bodySmall))
              : PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: memorized.toDouble(),
                        title: '$memorized',
                        color: Colors.green,
                        radius: 60,
                      ),
                      PieChartSectionData(
                        value: learning.toDouble(),
                        title: '$learning',
                        color: Colors.amber.shade700,
                        radius: 60,
                      ),
                      PieChartSectionData(
                        value: revision.toDouble(),
                        title: '$revision',
                        color: Colors.blue,
                        radius: 60,
                      ),
                    ],
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                  ),
                ),
        ),
        SectionTitle(S.of(context, 'hifz_targets')),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _TargetRow(
                  label: S.of(context, 'hifz_daily_target'),
                  value: data.targets['daily'] ?? 3,
                  onChanged: (v) async {
                    await UserDataRepository.instance.setHifzTargets(
                        v, data.targets['weekly'] ?? 15);
                    onChanged();
                  },
                ),
                const SizedBox(height: 8),
                _TargetRow(
                  label: S.of(context, 'hifz_weekly_target'),
                  value: data.targets['weekly'] ?? 15,
                  onChanged: (v) async {
                    await UserDataRepository.instance.setHifzTargets(
                        data.targets['daily'] ?? 3, v);
                    onChanged();
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context, 'hifz_due_count')
                      .replaceAll('{n}', '${data.due.length}'),
                  style: TextStyle(
                      color: colors.secondary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Text('$value',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onChanged(value + 1),
        ),
      ],
    );
  }
}
