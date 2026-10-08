import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';

/// Family mode — an OPTIONAL private family space.
///
/// Privacy-first: everything stays on this device (shared_preferences).
/// No accounts, no servers, no sharing outside the phone. Tracks simple
/// per-member daily activity (prayers / ayahs read / dhikr) for gentle
/// encouragement — never competition.
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _repo = UserDataRepository.instance;
  Map<String, dynamic>? _group;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    _group = await _repo.familyGroup();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createGroup() async {
    final name = await _askText(
      S.of(context, 'family_group_name_hint'),
      S.of(context, 'family_create_title'),
    );
    if (name == null || name.trim().isEmpty) return;
    await _repo.saveFamilyGroup({
      'name': name.trim(),
      'members': <Map<String, dynamic>>[],
      'created': DateTime.now().toIso8601String(),
    });
    await _reload();
  }

  Future<void> _addMember() async {
    final nameHint = S.of(context, 'family_member_name_hint');
    final addTitle = S.of(context, 'family_add_member');
    final relationHint = S.of(context, 'family_relation_hint');
    final name = await _askText(nameHint, addTitle);
    if (name == null || name.trim().isEmpty) return;
    final relation = await _askText(relationHint, addTitle);
    final members =
        List<Map<String, dynamic>>.from(_group!['members'] as List? ?? []);
    members.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name.trim(),
      'relation': (relation ?? '').trim(),
    });
    _group!['members'] = members;
    await _repo.saveFamilyGroup(_group!);
    await _reload();
  }

  Future<void> _removeMember(Map<String, dynamic> m) async {
    final members =
        List<Map<String, dynamic>>.from(_group!['members'] as List? ?? []);
    members.removeWhere((e) => e['id'] == m['id']);
    _group!['members'] = members;
    await _repo.saveFamilyGroup(_group!);
    await _reload();
  }

  Future<void> _logActivity(Map<String, dynamic> m) async {
    final prayersHint = S.of(context, 'family_prayers_hint');
    final ayahsHint = S.of(context, 'family_ayahs_hint');
    final dhikrHint = S.of(context, 'family_dhikr_hint');
    final prayers = await _askNumber(prayersHint);
    if (prayers == null) return;
    final ayahs = await _askNumber(ayahsHint) ?? 0;
    final dhikr = await _askNumber(dhikrHint) ?? 0;
    await _repo.recordFamilyActivity(m['id'] as String, prayers, ayahs, dhikr);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, 'family_logged'))),
      );
    }
    await _reload();
  }

  Future<String?> _askText(String hint, String title) async {
    final c = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
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

  Future<int?> _askNumber(String hint) async {
    final c = TextEditingController();
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hint),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(S.of(ctx, 'common_cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(int.tryParse(c.text.trim()) ?? 0),
            child: Text(S.of(ctx, 'common_save')),
          ),
        ],
      ),
    );
    c.dispose();
    return v;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'family_title'))),
      body: _loading
          ? LoadingView(label: S.of(context, 'common_loading'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                InfoCard(
                  icon: Icons.privacy_tip_outlined,
                  title: S.of(context, 'family_privacy_title'),
                  body: S.of(context, 'family_privacy_body'),
                ),
                const SizedBox(height: 8),
                if (_group == null) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: FilledButton.icon(
                      onPressed: _createGroup,
                      icon: const Icon(Icons.group_add_outlined),
                      label: Text(S.of(context, 'family_create')),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _group!['name'] as String? ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add_outlined),
                        tooltip: S.of(context, 'family_add_member'),
                        onPressed: _addMember,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: S.of(context, 'family_delete_group'),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                  S.of(ctx, 'family_delete_group_title')),
                              content: Text(
                                  S.of(ctx, 'family_delete_group_body')),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(false),
                                  child:
                                      Text(S.of(ctx, 'common_cancel')),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(true),
                                  child:
                                      Text(S.of(ctx, 'common_delete')),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await _repo.clearFamilyGroup();
                            await _reload();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._memberCards(),
                ],
              ],
            ),
    );
  }

  List<Widget> _memberCards() {
    final members =
        List<Map<String, dynamic>>.from(_group!['members'] as List? ?? []);
    if (members.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(S.of(context, 'family_no_members'))),
        ),
      ];
    }
    return [
      for (final m in members)
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _repo.familyActivity(m['id'] as String),
          builder: (context, snap) {
            final acts = snap.data ?? [];
            final today = acts.isNotEmpty ? acts.last : null;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    ((m['name'] as String?) ?? '?')
                        .characters
                        .first
                        .toUpperCase(),
                  ),
                ),
                title: Text(m['name'] as String? ?? ''),
                subtitle: Text(
                  [
                    if ((m['relation'] as String? ?? '').isNotEmpty)
                      m['relation'] as String,
                    if (today != null)
                      S.of(context, 'family_today_summary')
                          .replaceAll('{p}', '${today['prayers'] ?? 0}')
                          .replaceAll('{a}', '${today['ayahs'] ?? 0}')
                          .replaceAll('{d}', '${today['dhikr'] ?? 0}'),
                  ].join(' · '),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_task_outlined),
                      tooltip: S.of(context, 'family_log'),
                      onPressed: () => _logActivity(m),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: () => _removeMember(m),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
    ];
  }
}
