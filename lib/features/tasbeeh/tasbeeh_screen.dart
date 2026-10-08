import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';
import 'tasbeeh_presets.dart';

/// Digital tasbeeh: tap counter with target, undo, vibration, presets,
/// custom dhikr, daily history and streaks.
class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  static const _presets = TasbeehPresets.items;

  String _dhikr = _presets[0];
  int _count = 0;
  int _target = 100;
  bool _vibrate = true;
  bool _sound = false;
  int _streak = 0;
  List<({String date, String dhikr, int count})> _history = [];
  final List<int> _undoStack = [];

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    final repo = UserDataRepository.instance;
    final streak = await repo.tasbeehStreak();
    final history = await repo.tasbeehHistory();
    if (mounted) {
      setState(() {
        _streak = streak;
        _history = history.take(20).toList();
      });
    }
  }

  Future<void> _tap() async {
    setState(() {
      _undoStack.add(_count);
      _count++;
    });
    if (_vibrate) {
      try {
        final has = await Vibration.hasVibrator();
        if (has == true) {
          if (_count == _target) {
            Vibration.vibrate(duration: 300);
          } else {
            Vibration.vibrate(duration: 15);
          }
        }
      } catch (_) {}
    }
    if (_sound) {
      SystemSound.play(SystemSoundType.click);
    }
    if (_count == _target && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, 'tasbeeh_target_reached'))),
      );
    }
  }

  Future<void> _reset({bool save = true}) async {
    if (save && _count > 0) {
      await UserDataRepository.instance.recordTasbeeh(_dhikr, _count);
      _refreshStats();
    }
    setState(() {
      _count = 0;
      _undoStack.clear();
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() => _count = _undoStack.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress =
        _target <= 0 ? 0.0 : (_count / _target).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context, 'tasbeeh_title')),
        actions: [
          IconButton(
            icon: Icon(_vibrate
                ? Icons.vibration
                : Icons.vibration_outlined),
            tooltip: S.of(context, 'tasbeeh_vibrate'),
            onPressed: () =>
                setState(() => _vibrate = !_vibrate),
          ),
          IconButton(
            icon: Icon(
                _sound ? Icons.volume_up : Icons.volume_off_outlined),
            tooltip: S.of(context, 'tasbeeh_sound'),
            onPressed: () => setState(() => _sound = !_sound),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: S.of(context, 'tasbeeh_history'),
            onPressed: _showHistory,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dhikr selector
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length + 1,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, i) {
                if (i == _presets.length) {
                  return ActionChip(
                    label: Text(S.of(context, 'tasbeeh_custom')),
                    avatar: const Icon(Icons.add, size: 16),
                    onPressed: _customDhikrDialog,
                  );
                }
                final p = _presets[i];
                final selected = p == _dhikr;
                return ChoiceChip(
                  label: Text(p,
                      style: const TextStyle(fontSize: 15)),
                  selected: selected,
                  onSelected: (_) => _switchDhikr(p),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Counter button
          GestureDetector(
            onTap: _tap,
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.22),
                    colors.primary.withValues(alpha: 0.06),
                  ],
                ),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: colors.primary
                          .withValues(alpha: 0.12),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_count',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                            ),
                      ),
                      Text(
                        '${S.of(context, 'tasbeeh_target')}: $_target',
                        style:
                            Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _dhikr,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 20, height: 1.8),
            ),
          ),
          const SizedBox(height: 12),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _undo,
                icon: const Icon(Icons.undo),
                label: Text(S.of(context, 'tasbeeh_undo')),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _targetDialog(),
                icon: const Icon(Icons.flag_outlined),
                label: Text(S.of(context, 'tasbeeh_set_target')),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _reset(),
                icon: const Icon(Icons.refresh),
                label: Text(S.of(context, 'tasbeeh_reset')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InfoCard(
            icon: Icons.local_fire_department_outlined,
            title: S.of(context, 'tasbeeh_streak'),
            body: _streak == 0
                ? S.of(context, 'tasbeeh_streak_empty')
                : S.of(context, 'tasbeeh_streak_days')
                    .replaceFirst('{n}', '$_streak'),
          ),
        ],
      ),
    );
  }

  Future<void> _switchDhikr(String dhikr) async {
    await _reset(save: true);
    setState(() => _dhikr = dhikr);
  }

  void _customDhikrDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context, 'tasbeeh_custom')),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
              hintText: S.of(context, 'tasbeeh_custom_hint')),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context, 'common_close')),
          ),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              Navigator.pop(ctx);
              if (v.isNotEmpty) _switchDhikr(v);
            },
            child: Text(S.of(context, 'common_ok')),
          ),
        ],
      ),
    );
  }

  void _targetDialog() {
    final ctrl = TextEditingController(text: '$_target');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context, 'tasbeeh_set_target')),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '100'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context, 'common_close')),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim()) ?? 100;
              Navigator.pop(ctx);
              setState(() => _target = v.clamp(1, 100000));
            },
            child: Text(S.of(context, 'common_ok')),
          ),
        ],
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(context, 'tasbeeh_history'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: _history.isEmpty
                  ? Center(
                      child:
                          Text(S.of(context, 'tasbeeh_history_empty')))
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, i) {
                        final h = _history[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                              Icons.fingerprint_outlined),
                          title: Text(h.dhikr,
                              textDirection: TextDirection.rtl),
                          subtitle: Text(h.date),
                          trailing: Text('${h.count}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
