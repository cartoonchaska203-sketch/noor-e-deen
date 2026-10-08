import 'package:flutter/material.dart';

import '../../core/services/app_services.dart';
import '../../core/widgets/common_widgets.dart';
import '../../l10n/strings.dart';
import 'goals_repository.dart';

/// Islamic Goals (Phase 4): create goals, track progress & streaks,
/// optional daily reminders. Progress is computed live from on-device data.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final GoalsRepository _repo = GoalsRepository();
  List<Map<String, dynamic>> _goals = [];
  Map<String, GoalProgress> _progress = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final goals = await _repo.goals();
    final progress = <String, GoalProgress>{};
    for (final g in goals) {
      progress[g['id'] as String] = await _repo.progress(g);
    }
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _progress = progress;
      _loading = false;
    });
  }

  String _typeLabel(BuildContext context, String type) {
    switch (type) {
      case GoalType.prayers:
        return S.of(context, 'goal_type_prayers');
      case GoalType.quranAyahs:
        return S.of(context, 'goal_type_quran');
      case GoalType.tasbeeh:
        return S.of(context, 'goal_type_tasbeeh');
      case GoalType.adhkar:
        return S.of(context, 'goal_type_adhkar');
      case GoalType.fasting:
        return S.of(context, 'goal_type_fasting');
      case GoalType.hifz:
        return S.of(context, 'goal_type_hifz');
      default:
        return type;
    }
  }

  Future<void> _addGoalSheet() async {
    String type = GoalType.prayers;
    final titleCtrl = TextEditingController();
    int target = 5;
    TimeOfDay reminderAt = const TimeOfDay(hour: 20, minute: 0);
    bool remind = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.of(ctx, 'goal_new'),
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: S.of(ctx, 'goal_title'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: InputDecoration(
                  labelText: S.of(ctx, 'goal_type'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final t in GoalType.all)
                    DropdownMenuItem(
                      value: t,
                      child: Text(_typeLabel(ctx, t)),
                    ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setSheet(() {
                    type = v;
                    target = _defaultTarget(v);
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(S.of(ctx, 'goal_target')),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => setSheet(
                        () => target = (target - 1).clamp(1, 100000)),
                  ),
                  Text('$target',
                      style:
                          Theme.of(ctx).textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setSheet(
                        () => target = (target + 1).clamp(1, 100000)),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(S.of(ctx, 'goal_remind')),
                value: remind,
                onChanged: (v) => setSheet(() => remind = v),
              ),
              if (remind)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.of(ctx, 'goal_remind_at')),
                  trailing: TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: ctx,
                        initialTime: reminderAt,
                      );
                      if (t != null) setSheet(() => reminderAt = t);
                    },
                    child: Text(reminderAt.format(ctx)),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(ctx).pop(true),
                  child: Text(S.of(ctx, 'goal_save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    titleCtrl.dispose();
    if (saved != true) return;
    if (!mounted) return;

    final id = await _repo.addGoal({
      'title': titleCtrl.text.trim().isEmpty
          ? _typeLabel(context, type)
          : titleCtrl.text.trim(),
      'type': type,
      'target': target,
      'remind': remind,
      'remindHour': reminderAt.hour,
      'remindMinute': reminderAt.minute,
      'created': DateTime.now().toIso8601String(),
    });
    if (remind && mounted) {
      await AppServices.notifications.scheduleDailyReminder(
        id: 'goal_$id',
        title: S.of(context, 'goal_reminder_title'),
        body: S.of(context, 'goal_reminder_body'),
        hour: reminderAt.hour,
        minute: reminderAt.minute,
      );
    }
    await _reload();
  }

  int _defaultTarget(String type) {
    switch (type) {
      case GoalType.prayers:
        return 5;
      case GoalType.quranAyahs:
        return 100;
      case GoalType.tasbeeh:
        return 100;
      case GoalType.adhkar:
        return 2;
      case GoalType.fasting:
        return 30;
      case GoalType.hifz:
        return 10;
      default:
        return 1;
    }
  }

  Future<void> _deleteGoal(Map<String, dynamic> g) async {
    final id = g['id'] as String;
    await AppServices.notifications.cancelReminder('goal_$id');
    await _repo.deleteGoal(id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'goal_title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGoalSheet,
        icon: const Icon(Icons.add),
        label: Text(S.of(context, 'goal_new')),
      ),
      body: _loading
          ? const LoadingView()
          : _goals.isEmpty
              ? _empty(context)
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: _goals.length,
                    itemBuilder: (context, i) {
                      final g = _goals[i];
                      final p = _progress[g['id'] as String];
                      return _goalCard(context, g, p);
                    },
                  ),
                ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              S.of(context, 'goal_empty'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalCard(
      BuildContext context, Map<String, dynamic> g, GoalProgress? p) {
    final colors = Theme.of(context).colorScheme;
    final type = g['type'] as String? ?? GoalType.prayers;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g['title'] as String? ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _typeLabel(context, type),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if ((p?.streak ?? 0) > 0)
                  Chip(
                    avatar: const Icon(Icons.local_fire_department_outlined,
                        size: 16),
                    label: Text('${p!.streak}'),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteGoal(g),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: p?.fraction ?? 0,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${p?.current ?? 0}/${p?.target ?? 0}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            if (p != null && p.met)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 16, color: colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      S.of(context, 'goal_done'),
                      style: TextStyle(color: colors.primary),
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
