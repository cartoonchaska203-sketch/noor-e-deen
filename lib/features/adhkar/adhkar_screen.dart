import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';

/// Adhkar: morning / evening / after-salah sets with tap counters,
/// per-item progress, daily completion and a simple done-today state.
class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  Future<Map<String, List<DhikrItem>>>? _future;

  static const _sets = ['morning', 'evening', 'after_salah'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _sets.length, vsync: this);
    _future = ContentRepository.instance.adhkar();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _setLabel(String set) => switch (set) {
        'morning' => S.of(context, 'adhkar_morning'),
        'evening' => S.of(context, 'adhkar_evening'),
        _ => S.of(context, 'adhkar_after_salah'),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context, 'adhkar_title')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [for (final s in _sets) Tab(text: _setLabel(s))],
        ),
      ),
      body: FutureBuilder<Map<String, List<DhikrItem>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return LoadingView(label: S.of(context, 'common_loading'));
          }
          if (snap.hasError || !snap.hasData) {
            return ErrorView(
              message: S.of(context, 'common_error'),
              retryLabel: S.of(context, 'common_retry'),
              onRetry: () => setState(
                  () => _future = ContentRepository.instance.adhkar()),
            );
          }
          final data = snap.data!;
          return TabBarView(
            controller: _tabs,
            children: [
              for (final s in _sets)
                _AdhkarSetView(
                  setId: s,
                  items: data[s] ?? [],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AdhkarSetView extends StatefulWidget {
  const _AdhkarSetView({required this.setId, required this.items});

  final String setId;
  final List<DhikrItem> items;

  @override
  State<_AdhkarSetView> createState() => _AdhkarSetViewState();
}

class _AdhkarSetViewState extends State<_AdhkarSetView> {
  late List<int> _counts;
  bool _doneToday = false;

  @override
  void initState() {
    super.initState();
    _counts = List.filled(widget.items.length, 0);
    _checkDone();
  }

  Future<void> _checkDone() async {
    final done = await UserDataRepository.instance.adhkarDoneToday();
    if (mounted) setState(() => _doneToday = done.contains(widget.setId));
  }

  bool get _allComplete {
    for (var i = 0; i < widget.items.length; i++) {
      if (_counts[i] < widget.items[i].reps) return false;
    }
    return widget.items.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Center(child: Text(S.of(context, 'adhkar_empty')));
    }
    return Column(
      children: [
        if (_doneToday)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(S.of(context, 'adhkar_done_today'))),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: widget.items.length,
            itemBuilder: (context, i) {
              final item = widget.items[i];
              final done = _counts[i] >= item.reps;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: done
                      ? null
                      : () => setState(() => _counts[i]++),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: item.reps == 0
                                    ? 0
                                    : (_counts[i] / item.reps)
                                        .clamp(0.0, 1.0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_counts[i].clamp(0, item.reps)} / ${item.reps}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (done) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.arabic,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: 22,
                            height: 2.0,
                          ),
                        ),
                        if (item.english != null) ...[
                          const SizedBox(height: 6),
                          Text(item.english!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          '${S.of(context, 'duas_source')}: ${item.source}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton.icon(
            onPressed: _allComplete && !_doneToday
                ? () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final doneMsg =
                        S.of(context, 'adhkar_completed');
                    await UserDataRepository.instance
                        .markAdhkarDone(widget.setId);
                    _checkDone();
                    messenger.showSnackBar(
                      SnackBar(content: Text(doneMsg)),
                    );
                  }
                : null,
            icon: const Icon(Icons.check),
            label: Text(S.of(context, 'adhkar_mark_done')),
          ),
        ),
      ],
    );
  }
}
