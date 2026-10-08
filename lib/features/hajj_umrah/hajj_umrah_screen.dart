import 'package:flutter/material.dart';

import '../../data/phase3/phase3_content.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';

/// Hajj & Umrah guides: step-by-step rites with checklists, duas with
/// sources, and important warnings. All text bundled — fully offline.
class HajjUmrahScreen extends StatefulWidget {
  const HajjUmrahScreen({super.key});

  @override
  State<HajjUmrahScreen> createState() => _HajjUmrahScreenState();
}

class _HajjUmrahScreenState extends State<HajjUmrahScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
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
        title: Text(S.of(context, 'hajj_title')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: S.of(context, 'hajj_tab')),
            Tab(text: S.of(context, 'umrah_tab')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _GuideList(
            steps: HajjUmrahData.hajj,
            prefix: 'hajj',
            warnings: HajjUmrahData.warnings,
          ),
          _GuideList(
            steps: HajjUmrahData.umrah,
            prefix: 'umrah',
            warnings: const [],
          ),
        ],
      ),
    );
  }
}

class _GuideList extends StatefulWidget {
  const _GuideList({
    required this.steps,
    required this.prefix,
    required this.warnings,
  });

  final List<HajjStep> steps;
  final String prefix;
  final List<String> warnings;

  @override
  State<_GuideList> createState() => _GuideListState();
}

class _GuideListState extends State<_GuideList> {
  final _repo = UserDataRepository.instance;
  Set<String> _checked = {};

  @override
  void initState() {
    super.initState();
    _loadChecks();
  }

  Future<void> _loadChecks() async {
    final all = <String>{};
    for (var si = 0; si < widget.steps.length; si++) {
      for (var ci = 0;
          ci < widget.steps[si].checklist.length;
          ci++) {
        final key = '${widget.prefix}:$si:$ci';
        if (await _repo.isHajjChecked(key)) all.add(key);
      }
    }
    if (mounted) {
      setState(() {
        _checked = all;
      });
    }
  }

  int get _totalChecks =>
      widget.steps.fold(0, (n, s) => n + s.checklist.length);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final done = _checked.length;
    final total = _totalChecks;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.warnings.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade700.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.red.shade700.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber,
                        color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(S.of(context, 'hajj_warnings'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                for (final w in widget.warnings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(w)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (total > 0)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(S.of(context, 'hajj_progress'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                      Text('$done / $total'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                      value: total == 0 ? 0 : done / total),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        for (var si = 0; si < widget.steps.length; si++)
          _stepCard(widget.steps[si], si, colors),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _stepCard(HajjStep step, int si, ColorScheme colors) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(step.title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(step.detail),
            if (step.arabic != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      step.arabic!,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: 21,
                        height: 2.0,
                      ),
                    ),
                    if (step.transliteration != null) ...[
                      const SizedBox(height: 6),
                      Text(step.transliteration!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic)),
                    ],
                    if (step.translation != null) ...[
                      const SizedBox(height: 4),
                      Text(step.translation!,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                    if (step.source != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Source: ${step.source}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: colors.secondary)),
                      ),
                  ],
                ),
              ),
            ],
            if (step.checklist.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (var ci = 0; ci < step.checklist.length; ci++)
                _checkRow(step.checklist[ci], '${widget.prefix}:$si:$ci'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _checkRow(String label, String key) {
    final done = _checked.contains(key);
    return InkWell(
      onTap: () async {
        await _repo.toggleHajjChecked(key);
        setState(() {
          if (done) {
            _checked.remove(key);
          } else {
            _checked.add(key);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_box : Icons.check_box_outline_blank,
              color: done
                  ? Colors.green.shade700
                  : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  decoration:
                      done ? TextDecoration.lineThrough : null,
                  color: done
                      ? Theme.of(context).colorScheme.outline
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
