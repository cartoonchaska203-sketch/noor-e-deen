import 'package:flutter/material.dart';

import '../../core/services/ai/noor_ai_service.dart';
import '../../core/services/app_services.dart';
import '../../core/widgets/common_widgets.dart';
import '../../l10n/strings.dart';

/// Noor AI chat screen (Phase 4).
///
/// Source-grounded Islamic Q&A: answers come only from the app's bundled
/// verified datasets. A persistent disclaimer states answers are
/// informational, not fatwa.
class NoorAiScreen extends StatefulWidget {
  const NoorAiScreen({super.key});

  @override
  State<NoorAiScreen> createState() => _NoorAiScreenState();
}

class _NoorAiScreenState extends State<NoorAiScreen> {
  final List<NoorAiMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  String _lang = 'en';
  bool _busy = false;

  static const _langs = ['en', 'ur', 'roman', 'ar'];
  static const _langLabels = {
    'en': 'English',
    'ur': 'اردو',
    'roman': 'Roman Urdu',
    'ar': 'العربية',
  };

  static const _suggestions = [
    'dua for anxiety',
    'hadith about intentions',
    'ayah about patience',
    'how to pray',
    'zakat nisab',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _busy) return;
    _controller.clear();
    setState(() {
      _messages.add(NoorAiMessage(role: 'user', text: text));
      _busy = true;
    });
    _scrollToEnd();

    final reply =
        await AppServices.noorAi.ask(text, lang: _lang);
    if (!mounted) return;
    setState(() {
      _messages.add(NoorAiMessage(
        role: 'assistant',
        text: reply.text,
        sources: reply.sources,
      ));
      _busy = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context, 'noorai_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: S.of(context, 'noorai_about'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(S.of(context, 'noorai_about')),
                content: Text(S.of(context, 'noorai_about_body')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(S.of(ctx, 'common_close')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Disclaimer banner — always visible.
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colors.secondary.withValues(alpha: 0.12),
            child: Text(
              S.of(context, 'noorai_disclaimer'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          // Language toggle.
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<String>(
              segments: [
                for (final l in _langs)
                  ButtonSegment(
                    value: l,
                    label: Text(_langLabels[l]!,
                        style: const TextStyle(fontSize: 12)),
                  ),
              ],
              selected: {_lang},
              onSelectionChanged: (s) =>
                  setState(() => _lang = s.first),
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? _emptyState(context)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _messages.length + (_busy ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LoadingView(),
                        );
                      }
                      return _bubble(context, _messages[i]);
                    },
                  ),
          ),
          _inputBar(context),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.auto_awesome_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          S.of(context, 'noorai_welcome'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final s in _suggestions)
              ActionChip(
                label: Text(s),
                onPressed: () => _send(s),
              ),
          ],
        ),
      ],
    );
  }

  Widget _bubble(BuildContext context, NoorAiMessage m) {
    final colors = Theme.of(context).colorScheme;
    final isUser = m.role == 'user';
    final isRtl = _lang == 'ur' || _lang == 'ar';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? colors.primary.withValues(alpha: 0.14)
              : colors.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.text,
              textDirection: isRtl && !isUser
                  ? TextDirection.rtl
                  : null,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    fontFamily: isRtl && !isUser ? 'AmiriQuran' : null,
                  ),
            ),
            if (m.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final s in m.sources)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified_outlined,
                          size: 14, color: colors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colors.primary),
                        ),
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

  Widget _inputBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: S.of(context, 'noorai_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _busy ? null : () => _send(),
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(14),
              ),
              child: const Icon(Icons.send_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
