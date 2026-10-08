import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/phase3/phase3_content.dart';
import '../../l10n/strings.dart';

/// Salah learning module: Wudu, Ghusl and the five prayers + Witr.
/// Madhab differences are labeled respectfully; Arabic wordings carry
/// their hadith/Quran sources.
class SalahGuideScreen extends StatelessWidget {
  const SalahGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final guides = SalahGuideData.all;
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'salah_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoCard(
            icon: Icons.info_outline,
            title: S.of(context, 'salah_madhab_title'),
            body: S.of(context, 'salah_madhab_body'),
          ),
          const SizedBox(height: 8),
          for (final g in guides)
            Card(
              child: ListTile(
                leading: Icon(_iconFor(g.id),
                    color: Theme.of(context).colorScheme.primary),
                title: Text(g.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(g.subtitle,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _GuideDetailScreen(guide: g),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _iconFor(String id) {
    switch (id) {
      case 'wudu':
        return Icons.water_drop_outlined;
      case 'ghusl':
        return Icons.shower_outlined;
      case 'witr':
        return Icons.nights_stay_outlined;
      default:
        return Icons.mosque_outlined;
    }
  }
}

class _GuideDetailScreen extends StatelessWidget {
  const _GuideDetailScreen({required this.guide});

  final SalahGuide guide;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(guide.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(guide.subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          for (var i = 0; i < guide.steps.length; i++)
            _StepCard(step: guide.steps[i], index: i),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.index});

  final GuideStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('${index + 1}',
                      style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(step.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(step.detail,
                style: Theme.of(context).textTheme.bodyMedium),
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
                  ],
                ),
              ),
              Row(
                children: [
                  if (step.source != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Source: ${step.source}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: colors.secondary)),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: S.of(context, 'quran_copy'),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: step.arabic!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(S.of(context, 'quran_copied'))),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, size: 18),
                    tooltip: S.of(context, 'quran_share'),
                    onPressed: () => Share.share(
                        '${step.title}\n${step.arabic!}\n${step.translation ?? ''}'),
                  ),
                ],
              ),
            ] else if (step.source != null) ...[
              const SizedBox(height: 6),
              Text('Source: ${step.source}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: colors.secondary)),
            ],
            if (step.madhabNote != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: colors.secondary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.balance_outlined,
                        size: 16, color: colors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(step.madhabNote!,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
