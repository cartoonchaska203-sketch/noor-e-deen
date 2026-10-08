import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';

/// Charity / Sadaqah tracker — all on-device.
///
/// Types: zakat | sadaqah | donation. Monthly + annual totals, yearly
/// goals, history. Amounts are user-entered; nothing is verified.
class CharityScreen extends StatefulWidget {
  const CharityScreen({super.key});

  @override
  State<CharityScreen> createState() => _CharityScreenState();
}

class _CharityScreenState extends State<CharityScreen> {
  final _repo = UserDataRepository.instance;
  List<Map<String, dynamic>> _entries = [];
  Map<String, double> _goals = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final now = DateTime.now();
    _entries = await _repo.charityEntries();
    _goals = await _repo.charityGoalsForYear(now.year);
    if (mounted) setState(() => _loading = false);
  }

  double _total({int? year, int? month, String? type}) {
    var t = 0.0;
    for (final e in _entries) {
      if (type != null && e['type'] != type) continue;
      final d = DateTime.tryParse(e['date'] as String? ?? '');
      if (d == null) continue;
      if (year != null && d.year != year) continue;
      if (month != null && d.month != month) continue;
      t += (e['amount'] as num?)?.toDouble() ?? 0;
    }
    return t;
  }

  Future<void> _addEntry() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _EntryDialog(),
    );
    if (result == null) return;
    await _repo.addCharityEntry(result);
    await _reload();
  }

  Future<void> _editGoals() async {
    final now = DateTime.now();
    final controllers = {
      for (final t in ['zakat', 'sadaqah', 'donation'])
        t: TextEditingController(
            text: (_goals[t] ?? 0) > 0
                ? (_goals[t]!).toStringAsFixed(0)
                : ''),
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx, 'charity_goals_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in controllers.keys)
              TextField(
                controller: controllers[t],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText:
                      '${S.of(ctx, 'charity_type_$t')} (${S.of(ctx, 'charity_goal_hint')})',
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.of(ctx, 'common_cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(S.of(ctx, 'common_save')),
          ),
        ],
      ),
    );
    if (ok == true) {
      for (final e in controllers.entries) {
        await _repo.setCharityGoal(
          now.year,
          e.key,
          double.tryParse(e.value.text.trim()) ?? 0,
        );
      }
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yearTotal = _total(year: now.year);
    final monthTotal = _total(year: now.year, month: now.month);
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context, 'charity_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: S.of(context, 'charity_goals_title'),
            onPressed: _editGoals,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: Text(S.of(context, 'charity_add')),
      ),
      body: _loading
          ? LoadingView(label: S.of(context, 'common_loading'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _TotalCard(
                        label: S.of(context, 'charity_this_month'),
                        value: monthTotal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TotalCard(
                        label: S.of(context, 'charity_this_year'),
                        value: yearTotal,
                      ),
                    ),
                  ],
                ),
                const SectionTitle(''),
                _GoalsCard(
                  goals: _goals,
                  totals: {
                    for (final t in ['zakat', 'sadaqah', 'donation'])
                      t: _total(year: now.year, type: t),
                  },
                ),
                SectionTitle(S.of(context, 'charity_by_month')),
                SizedBox(height: 180, child: _MonthlyChart(entries: _entries)),
                SectionTitle(S.of(context, 'charity_history')),
                if (_entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(S.of(context, 'charity_empty')),
                    ),
                  )
                else
                  for (final e in _entries)
                    Dismissible(
                      key: ValueKey(e['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red.shade100,
                        child: const Icon(Icons.delete, color: Colors.red),
                      ),
                      onDismissed: (_) async {
                        await _repo.deleteCharityEntry(e['id'] as String);
                        await _reload();
                      },
                      child: ListTile(
                        leading: Icon(_iconFor(e['type'] as String? ?? '')),
                        title: Text(
                          '${(e['amount'] as num).toStringAsFixed(2)} ${e['currency'] ?? ''}',
                        ),
                        subtitle: Text(
                          [
                            S.of(context, 'charity_type_${e['type']}'),
                            e['recipient'] as String? ?? '',
                            e['note'] as String? ?? '',
                          ].where((s) => s.isNotEmpty).join(' · '),
                        ),
                        trailing: Text(
                          _fmtDate(e['date'] as String?),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
              ],
            ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'zakat' => Icons.calculate_outlined,
        'sadaqah' => Icons.volunteer_activism_outlined,
        _ => Icons.card_giftcard_outlined,
      };

  String _fmtDate(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return '';
    return DateFormat.yMMMd().format(d);
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value.toStringAsFixed(2),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.goals, required this.totals});
  final Map<String, double> goals;
  final Map<String, double> totals;

  @override
  Widget build(BuildContext context) {
    final active = goals.entries.where((e) => e.value > 0).toList();
    if (active.isEmpty) {
      return InfoCard(
        icon: Icons.flag_outlined,
        title: S.of(context, 'charity_goals_title'),
        body: S.of(context, 'charity_goals_hint'),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context, 'charity_goals_title'),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final g in active)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(S.of(context, 'charity_type_${g.key}')),
                        Text(
                          '${(totals[g.key] ?? 0).toStringAsFixed(0)} / ${g.value.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: ((totals[g.key] ?? 0) / g.value).clamp(0.0, 1.0),
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

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.entries});
  final List<Map<String, dynamic>> entries;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - 5 + i);
      return (year: d.year, month: d.month);
    });
    final totals = <double>[];
    for (final m in months) {
      var t = 0.0;
      for (final e in entries) {
        final d = DateTime.tryParse(e['date'] as String? ?? '');
        if (d != null && d.year == m.year && d.month == m.month) {
          t += (e['amount'] as num?)?.toDouble() ?? 0;
        }
      }
      totals.add(t);
    }
    final maxY = (totals.isEmpty ? 0 : totals.reduce((a, b) => a > b ? a : b));
    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 10 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= months.length) return const SizedBox();
                return Text(
                  DateFormat.MMM().format(
                      DateTime(months[i].year, months[i].month)),
                  style: Theme.of(context).textTheme.labelSmall,
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < months.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: totals[i],
                  color: Theme.of(context).colorScheme.primary,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EntryDialog extends StatefulWidget {
  const _EntryDialog();

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  String _type = 'sadaqah';
  final _amount = TextEditingController();
  final _recipient = TextEditingController();
  final _note = TextEditingController();
  String _currency = 'GBP';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _recipient.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context, 'charity_add')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              items: ['zakat', 'sadaqah', 'donation']
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(S.of(context, 'charity_type_$t')),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? 'sadaqah'),
            ),
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: S.of(context, 'charity_amount')),
            ),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              items: ['GBP', 'USD', 'PKR', 'EUR']
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v ?? 'GBP'),
              decoration: InputDecoration(
                  labelText: S.of(context, 'charity_currency')),
            ),
            TextField(
              controller: _recipient,
              decoration: InputDecoration(
                  labelText: S.of(context, 'charity_recipient_hint')),
            ),
            TextField(
              controller: _note,
              decoration: InputDecoration(
                  labelText: S.of(context, 'charity_note_hint')),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(DateFormat.yMMMd().format(_date)),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDate: _date,
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  child: Text(S.of(context, 'common_change')),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context, 'common_cancel')),
        ),
        FilledButton(
          onPressed: () {
            final amt = double.tryParse(_amount.text.trim());
            if (amt == null || amt <= 0) return;
            Navigator.of(context).pop({
              'type': _type,
              'amount': amt,
              'currency': _currency,
              'date':
                  '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              'recipient': _recipient.text.trim(),
              'note': _note.text.trim(),
            });
          },
          child: Text(S.of(context, 'common_save')),
        ),
      ],
    );
  }
}
