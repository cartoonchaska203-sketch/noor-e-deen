import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../l10n/strings.dart';
import '../admin/admin_service.dart';

/// Scholar / teacher directory.
///
/// DATA POLICY (strict):
/// - The bundled starter list contains ONLY widely-known public figures,
///   with a general specialization label (e.g. "Islamic lecturer").
/// - NO credentials, titles, or affiliations are stated — nothing is
///   invented. Every entry is marked "public figure — verify independently".
/// - A future admin CMS (Phase 6) is the proper source for verified
///   listings with real credential checks. See [ScholarDirectoryService].
class ScholarDirectoryService {
  ScholarDirectoryService._();
  static final ScholarDirectoryService instance =
      ScholarDirectoryService._();

  /// Starter list: public figures only. Replace/augment via CMS.
  List<ScholarEntry> starterList() => const [
        ScholarEntry(
          name: 'Mufti Ismail Menk',
          specialization: 'Islamic lectures & reminders',
          region: 'Zimbabwe',
        ),
        ScholarEntry(
          name: 'Dr. Yasir Qadhi',
          specialization: 'Seerah & Islamic studies education',
          region: 'United States',
        ),
        ScholarEntry(
          name: 'Dr. Omar Suleiman',
          specialization: 'Quranic reflections & community work',
          region: 'United States',
        ),
        ScholarEntry(
          name: 'Sheikh Assim Al Hakeem',
          specialization: 'Q&A on daily Islamic practice',
          region: 'Saudi Arabia',
        ),
        ScholarEntry(
          name: 'Nouman Ali Khan',
          specialization: 'Quranic Arabic & tafseer studies',
          region: 'United States',
        ),
        ScholarEntry(
          name: 'Mufti Tariq Masood',
          specialization: 'Urdu Islamic lectures',
          region: 'Pakistan',
        ),
      ];

  /// Future CMS integration point. Returns null until an admin backend
  /// with verified credentials is configured (Phase 6).
  Future<List<ScholarEntry>?> fetchVerified() async => null;
}

class ScholarEntry {
  const ScholarEntry({
    required this.name,
    required this.specialization,
    required this.region,
    this.verified = false,
  });

  final String name;
  final String specialization;
  final String region;

  /// True ONLY after a real credential check (Phase 6 CMS).
  final bool verified;
}

class ScholarsScreen extends StatefulWidget {
  const ScholarsScreen({super.key});

  @override
  State<ScholarsScreen> createState() => _ScholarsScreenState();
}

class _ScholarsScreenState extends State<ScholarsScreen> {
  String _query = '';
  Future<List<ScholarEntry>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
  }

  /// Starter list + admin-added custom entries.
  Future<List<ScholarEntry>> _loadAll() async {
    final all = List<ScholarEntry>.from(
        ScholarDirectoryService.instance.starterList());
    try {
      final custom = await AdminService.instance.customScholars();
      for (final c in custom) {
        all.add(ScholarEntry(
          name: (c['name'] ?? '').toString(),
          specialization: (c['specialization'] ?? '').toString(),
          region: (c['region'] ?? '').toString(),
          verified: c['verified'] == true,
        ));
      }
    } catch (_) {
      // Admin data unavailable: show the starter list alone.
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'scholars_title'))),
      body: FutureBuilder<List<ScholarEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data ??
              ScholarDirectoryService.instance.starterList();
          return _body(context, all);
        },
      ),
    );
  }

  Widget _body(BuildContext context, List<ScholarEntry> all) {
    final list = _query.isEmpty
        ? all
        : all
            .where((s) =>
                s.name.toLowerCase().contains(_query.toLowerCase()) ||
                s.specialization
                    .toLowerCase()
                    .contains(_query.toLowerCase()))
            .toList();
    return Column(
      children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: InfoCard(
              icon: Icons.verified_outlined,
              title: S.of(context, 'scholars_policy_title'),
              body: S.of(context, 'scholars_policy_body'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: S.of(context, 'common_search'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final s = list[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(s.name.characters.first),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(s.name)),
                        if (s.verified)
                          const Icon(Icons.verified,
                              color: Colors.blue, size: 18),
                      ],
                    ),
                    subtitle: Text(
                        '${s.specialization} · ${s.region}\n${S.of(context, 'scholars_verify_note')}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      );
  }
}
