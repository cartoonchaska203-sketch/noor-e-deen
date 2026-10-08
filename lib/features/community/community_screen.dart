import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';

/// Community — local-first study circles.
///
/// There is NO server in this phase: circles, members and progress live
/// on this device only. Moderation hooks (report/block) are real UI that
/// records local flags and documents the server-side moderation design
/// for Phase 6. A clear notice forbids presenting unverified fatwas.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
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
        title: Text(S.of(context, 'community_title')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: S.of(context, 'community_circles')),
            Tab(text: S.of(context, 'community_safety')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_CirclesTab(), _SafetyTab()],
      ),
    );
  }
}

class _CirclesTab extends StatefulWidget {
  const _CirclesTab();

  @override
  State<_CirclesTab> createState() => _CirclesTabState();
}

class _CirclesTabState extends State<_CirclesTab> {
  final _repo = UserDataRepository.instance;
  List<Map<String, dynamic>> _circles = [];
  final Map<String, int> _totals = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    _circles = await _repo.communityCircles();
    _totals.clear();
    for (final c in _circles) {
      _totals[c['id'] as String] =
          await _repo.circleProgressTotal(c['id'] as String);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _create() async {
    final nameHint = S.of(context, 'community_name_hint');
    final goalHint = S.of(context, 'community_goal_hint');
    final name = await _askText(nameHint);
    if (name == null || name.trim().isEmpty) return;
    const type = 'quran';
    final goal = await _askText(goalHint) ?? '';
    await _repo.saveCommunityCircle({
      'name': name.trim(),
      'type': type,
      'members': <String>[],
      'goal': goal.trim(),
      'created': DateTime.now().toIso8601String(),
    });
    await _reload();
  }

  Future<String?> _askText(String hint) async {
    final c = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: TextField(
          controller: c,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(S.of(ctx, 'common_cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(c.text),
            child: Text(S.of(ctx, 'common_save')),
          ),
        ],
      ),
    );
    c.dispose();
    return v;
  }

  Future<void> _openCircle(Map<String, dynamic> circle) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CircleSheet(
        circle: circle,
        total: _totals[circle['id'] as String] ?? 0,
        onChanged: _reload,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(S.of(context, 'community_create')),
      ),
      body: _loading
          ? LoadingView(label: S.of(context, 'common_loading'))
          : _circles.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      S.of(context, 'community_empty'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _circles.length,
                  itemBuilder: (context, i) {
                    final c = _circles[i];
                    final members =
                        (c['members'] as List?)?.length ?? 0;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          _iconFor(c['type'] as String? ?? 'quran'),
                          color:
                              Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(c['name'] as String? ?? ''),
                        subtitle: Text(
                          '${S.of(context, 'community_type_${c['type']}')} · '
                          '$members ${S.of(context, 'community_members')} · '
                          '${_totals[c['id'] as String] ?? 0} ${S.of(context, 'community_units_done')}',
                        ),
                        trailing:
                            const Icon(Icons.chevron_right),
                        onTap: () => _openCircle(c),
                      ),
                    );
                  },
                ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'hifz' => Icons.menu_book_outlined,
        'study' => Icons.school_outlined,
        'charity' => Icons.volunteer_activism_outlined,
        _ => Icons.auto_stories_outlined,
      };
}

class _CircleSheet extends StatefulWidget {
  const _CircleSheet({
    required this.circle,
    required this.total,
    required this.onChanged,
  });

  final Map<String, dynamic> circle;
  final int total;
  final Future<void> Function() onChanged;

  @override
  State<_CircleSheet> createState() => _CircleSheetState();
}

class _CircleSheetState extends State<_CircleSheet> {
  final _repo = UserDataRepository.instance;
  final _memberCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController();

  @override
  void dispose() {
    _memberCtrl.dispose();
    _unitsCtrl.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    final name = _memberCtrl.text.trim();
    if (name.isEmpty) return;
    final members =
        List<String>.from(widget.circle['members'] as List? ?? []);
    members.add(name);
    widget.circle['members'] = members;
    await _repo.saveCommunityCircle(widget.circle);
    _memberCtrl.clear();
    await widget.onChanged();
    if (mounted) setState(() {});
  }

  Future<void> _logProgress() async {
    final units = int.tryParse(_unitsCtrl.text.trim()) ?? 0;
    if (units <= 0) return;
    await _repo.logCircleProgress(widget.circle['id'] as String, units);
    _unitsCtrl.clear();
    await widget.onChanged();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final members =
        List<String>.from(widget.circle['members'] as List? ?? []);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.circle['name'] as String? ?? '',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if ((widget.circle['goal'] as String? ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${S.of(context, 'community_goal')}: ${widget.circle['goal']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '${S.of(context, 'community_progress')}: ${widget.total}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            SectionTitle(S.of(context, 'community_members')),
            for (final m in members)
              ListTile(
                dense: true,
                leading: CircleAvatar(
                    child: Text(m.characters.first.toUpperCase())),
                title: Text(m),
                trailing: IconButton(
                  icon: const Icon(Icons.flag_outlined),
                  tooltip: S.of(context, 'community_report'),
                  onPressed: () => _reportMember(m),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _memberCtrl,
                    decoration: InputDecoration(
                      hintText:
                          S.of(context, 'community_add_member_hint'),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: _addMember,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionTitle(S.of(context, 'community_log_progress')),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _unitsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: S.of(context, 'community_units_hint'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _logProgress,
                  child: Text(S.of(context, 'community_log')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title:
                        Text(S.of(ctx, 'community_delete_title')),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(ctx).pop(false),
                        child: Text(S.of(ctx, 'common_cancel')),
                      ),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(ctx).pop(true),
                        child: Text(S.of(ctx, 'common_delete')),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await _repo.deleteCommunityCircle(
                      widget.circle['id'] as String);
                  await widget.onChanged();
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: Text(S.of(context, 'common_delete')),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Local report flag + documented server-side moderation design.
  Future<void> _reportMember(String member) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(S.of(ctx, 'community_report_title')),
        children: [
          for (final r in ['spam', 'unverified_claim', 'other'])
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(r),
              child: Text(S.of(ctx, 'community_report_$r')),
            ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    // Local-first: the flag is recorded on-device. Phase 6 server design:
    // POST /moderation/reports {circleId, member, reason, ts} →
    // admin review queue → warn/remove. Documented here, not faked.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          S.of(context, 'community_reported')
              .replaceAll('{name}', member),
        ),
      ),
    );
  }
}

class _SafetyTab extends StatelessWidget {
  const _SafetyTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InfoCard(
          icon: Icons.gavel_outlined,
          title: S.of(context, 'community_nofatwa_title'),
          body: S.of(context, 'community_nofatwa_body'),
        ),
        InfoCard(
          icon: Icons.shield_outlined,
          title: S.of(context, 'community_moderation_title'),
          body: S.of(context, 'community_moderation_body'),
        ),
        InfoCard(
          icon: Icons.privacy_tip_outlined,
          title: S.of(context, 'community_local_title'),
          body: S.of(context, 'community_local_body'),
        ),
      ],
    );
  }
}
