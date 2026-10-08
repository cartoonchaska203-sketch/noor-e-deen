import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/content_repository.dart';
import '../../l10n/strings.dart';
import 'admin_service.dart';

/// Admin: hide/show individual duas and wazaif (Phase 6).
///
/// Lists every bundled dua/wazifa with a visibility switch. Hidden
/// items disappear from the Duas/Wazaif screens (and search). The
/// bundled data itself is never modified — only the flag list.
class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<dynamic> _duas = [];
  List<dynamic> _wazaif = [];
  Set<String> _hidden = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final repo = ContentRepository.instance;
    final duas = await repo.duas();
    final wazaif = await repo.wazaif();
    final hidden = await AdminService.instance.hiddenContent();
    if (mounted) {
      setState(() {
        _duas = duas;
        _wazaif = wazaif;
        _hidden = hidden;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(String type, String id, bool hide) async {
    await AdminService.instance.setHidden(type, id, hide);
    if (mounted) {
      setState(() {
        if (hide) {
          _hidden.add('$type:$id');
        } else {
          _hidden.remove('$type:$id');
        }
      });
    }
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
        title: Text(S.of(context, 'admin_content')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: S.of(context, 'admin_content_duas')),
            Tab(text: S.of(context, 'admin_content_wazaif')),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: InfoCard(
                    icon: Icons.visibility_outlined,
                    title: S.of(context, 'admin_content_note_title'),
                    body: S.of(context, 'admin_content_note_body'),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _list('dua', _duas,
                          (d) => (d.id as String, d.title as String)),
                      _list('wazifa', _wazaif,
                          (w) => (w.id as String, w.title as String)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _list(String type, List<dynamic> items,
      (String, String) Function(dynamic) keyOf) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final (id, title) = keyOf(items[i]);
        final hidden = _hidden.contains('$type:$id');
        return Card(
          child: SwitchListTile(
            title: Text(title,
                style: TextStyle(
                    color: hidden
                        ? Theme.of(context).disabledColor
                        : null)),
            subtitle: Text(id),
            value: !hidden,
            onChanged: (v) => _toggle(type, id, !v),
          ),
        );
      },
    );
  }
}
