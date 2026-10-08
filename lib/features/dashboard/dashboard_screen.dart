import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';

/// Personal Islamic dashboard (Phase 4): daily/weekly/monthly stats for
/// Salah, Quran, Dhikr, Hifz and fasting. No leaderboards — personal
/// progress only.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final UserDataRepository _user = UserDataRepository.instance;
  int _range = 7; // 7 | 30
  bool _loading = true;

  Map<String, int> _tasbeeh = {};
  Map<String, int> _adhkar = {};
  Map<String, Set<String>> _salah = {};
  Map<String, String> _hifzStates = {};
  Map<String, String> _fasting = {};
  int _readAyahs = 0;
  int _tasbeehStreak = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _user.tasbeehTotalsByDay(),
      _user.adhkarCountsByDay(),
      _user.salahLog(),
      _user.hifzStates(),
      _user.fastingLog(),
      _user.readAyahCount(),
      _user.tasbeehStreak(),
    ]);
    if (!mounted) return;
    setState(() {
      _tasbeeh = results[0] as Map<String, int>;
      _adhkar = results[1] as Map<String, int>;
      _salah = (results[2] as Map<String, Set<String>>);
      _hifzStates = results[3] as Map<String, String>;
      _fasting = results[4] as Map<String, String>;
      _readAyahs = results[5] as int;
      _tasbeehStreak = results[6] as int;
      _loading = false;
    });
  }

  List<DateTime> get _days {
    final now = DateTime.now();
    return List.generate(
        _range, (i) => now.subtract(Duration(days: _range - 1 - i)));
  }

  double _maxY(List<double> vals) {
    final m = vals.fold<double>(0, (a, b) => a > b ? a : b);
    return (m <= 0 ? 10 : m * 1.2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'dash_title'))),
      body: _loading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _rangePicker(context),
                  _streakRow(context),
                  SectionTitle(S.of(context, 'dash_dhikr')),
                  _barCard(context, _days.map((d) =>
                      (_tasbeeh[_key(d)] ?? 0).toDouble()).toList()),
                  SectionTitle(S.of(context, 'dash_salah')),
                  _barCard(context, _days.map((d) =>
                      (_salah[_key(d)]?.length ?? 0).toDouble()).toList()),
                  SectionTitle(S.of(context, 'dash_adhkar')),
                  _barCard(context, _days.map((d) =>
                      (_adhkar[_key(d)] ?? 0).toDouble()).toList()),
                  SectionTitle(S.of(context, 'dash_hifz')),
                  _hifzCard(context),
                  SectionTitle(S.of(context, 'dash_totals')),
                  _totalsCard(context),
                ],
              ),
            ),
    );
  }

  Widget _rangePicker(BuildContext context) {
    return Center(
      child: SegmentedButton<int>(
        segments: [
          ButtonSegment(
              value: 7, label: Text(S.of(context, 'dash_week'))),
          ButtonSegment(
              value: 30, label: Text(S.of(context, 'dash_month'))),
        ],
        selected: {_range},
        onSelectionChanged: (s) {
          setState(() => _range = s.first);
        },
      ),
    );
  }

  Widget _streakRow(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.local_fire_department_outlined,
                color: colors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.of(context, 'dash_streak'),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    S.of(context, 'dash_streak_days')
                        .replaceFirst('{n}', '$_tasbeehStreak'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text('$_tasbeehStreak',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: colors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _barCard(BuildContext context, List<double> values) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: _maxY(values),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= _days.length) {
                        return const SizedBox.shrink();
                      }
                      // Label first/last/middle only to avoid crowding.
                      if (_range == 7 ||
                          i == 0 ||
                          i == _days.length - 1 ||
                          i == _days.length ~/ 2) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${_days[i].day}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              barGroups: [
                for (int i = 0; i < values.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        color: colors.primary,
                        width: _range == 7 ? 22 : 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hifzCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mem =
        _hifzStates.values.where((s) => s == 'memorized').length;
    final learn =
        _hifzStates.values.where((s) => s == 'learning').length;
    final rev =
        _hifzStates.values.where((s) => s == 'revision').length;
    final total = mem + learn + rev;
    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(S.of(context, 'dash_no_data')),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              height: 140,
              width: 140,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 32,
                  sections: [
                    PieChartSectionData(
                      value: mem.toDouble(),
                      color: colors.primary,
                      title: '$mem',
                      titleStyle: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                    PieChartSectionData(
                      value: learn.toDouble(),
                      color: colors.secondary,
                      title: '$learn',
                      titleStyle: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                    PieChartSectionData(
                      value: rev.toDouble(),
                      color: colors.tertiary,
                      title: '$rev',
                      titleStyle: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legend(context, colors.primary,
                      S.of(context, 'dash_memorized'), mem),
                  _legend(context, colors.secondary,
                      S.of(context, 'dash_learning'), learn),
                  _legend(context, colors.tertiary,
                      S.of(context, 'dash_revision'), rev),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(
      BuildContext context, Color c, String label, int n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
              width: 12, height: 12,
              decoration:
                  BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text('$n',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _totalsCard(BuildContext context) {
    final fasted =
        _fasting.values.where((s) => s == 'fasted').length;
    final rows = [
      [S.of(context, 'dash_total_ayahs'), '$_readAyahs'],
      [S.of(context, 'dash_total_dhikr'),
        '${_tasbeeh.values.fold<int>(0, (a, b) => a + b)}'],
      [S.of(context, 'dash_total_fasts'), '$fasted'],
    ];
    return Card(
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            ListTile(
              title: Text(rows[i][0]),
              trailing: Text(rows[i][1],
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (i < rows.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}
