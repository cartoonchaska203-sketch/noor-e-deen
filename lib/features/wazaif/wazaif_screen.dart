import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/content_repository.dart';
import '../../l10n/strings.dart';

/// Wazaif list. Each wazifa is labeled by provenance:
/// Quranic verse / from a sahih hadith (with reference) / general practice.
///
/// No virtue claim is ever stated without its hadith reference — items
/// whose claims couldn't be verified were excluded at curation time.
class WazaifScreen extends StatefulWidget {
  const WazaifScreen({super.key});

  @override
  State<WazaifScreen> createState() => _WazaifScreenState();
}

class _WazaifScreenState extends State<WazaifScreen> {
  Future<List<Wazifa>>? _future;

  @override
  void initState() {
    super.initState();
    _future = ContentRepository.instance.wazaif();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'wazaif_title'))),
      body: FutureBuilder<List<Wazifa>>(
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
                  () => _future = ContentRepository.instance.wazaif()),
            );
          }
          final list = snap.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: list.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    S.of(context, 'wazaif_disclaimer'),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                );
              }
              return _WazifaCard(wazifa: list[i - 1]);
            },
          );
        },
      ),
    );
  }
}

class _WazifaCard extends StatelessWidget {
  const _WazifaCard({required this.wazifa});

  final Wazifa wazifa;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final typeLabel = switch (wazifa.type) {
      'quran' => S.of(context, 'wazaif_type_quran'),
      'hadith' => S.of(context, 'wazaif_type_hadith'),
      _ => S.of(context, 'wazaif_type_general'),
    };
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    wazifa.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      color: colors.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            if (wazifa.arabic != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  wazifa.arabic!,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: 22,
                    height: 2.0,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            _MetaRow(
                icon: Icons.menu_book_outlined,
                text:
                    '${S.of(context, 'wazaif_reference')}: ${wazifa.reference}'),
            if (wazifa.reps != null)
              _MetaRow(
                  icon: Icons.repeat,
                  text:
                      '${S.of(context, 'wazaif_reps')}: ${wazifa.reps}'),
            if (wazifa.note != null) ...[
              const SizedBox(height: 6),
              Text(
                wazifa.note!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon,
              size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
