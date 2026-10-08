import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/phase3/phase3_content.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';

/// Tajweed Academy: lessons with verified Quranic examples + MCQ quizzes.
/// Audio is honestly stubbed — no fake play buttons.
class TajweedScreen extends StatefulWidget {
  const TajweedScreen({super.key});

  @override
  State<TajweedScreen> createState() => _TajweedScreenState();
}

class _TajweedScreenState extends State<TajweedScreen> {
  final _repo = UserDataRepository.instance;
  late Future<({Set<String> done, ({int score, int total})? best})> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<({Set<String> done, ({int score, int total})? best})> _load() async {
    final done = await _repo.tajweedDone();
    final best = await _repo.tajweedQuizBest();
    return (done: done, best: best);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'tajweed_title'))),
      body: FutureBuilder<({Set<String> done, ({int score, int total})? best})>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return LoadingView(label: S.of(context, 'common_loading'));
          }
          if (snap.hasError || !snap.hasData) {
            return ErrorView(
              message: S.of(context, 'common_error'),
              retryLabel: S.of(context, 'common_retry'),
              onRetry: _reload,
            );
          }
          final d = snap.data!;
          final lessons = TajweedData.lessons;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              InfoCard(
                icon: Icons.school_outlined,
                title: S.of(context, 'tajweed_intro_title'),
                body: S.of(context, 'tajweed_intro_body'),
              ),
              if (d.best != null)
                Card(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(S.of(context, 'tajweed_best')),
                    trailing: Text(
                      '${d.best!.score}/${d.best!.total}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              SectionTitle(S.of(context, 'tajweed_lessons')),
              for (final l in lessons)
                Card(
                  child: ListTile(
                    leading: d.done.contains(l.id)
                        ? Icon(Icons.check_circle,
                            color: Colors.green.shade700)
                        : Icon(Icons.menu_book_outlined,
                            color:
                                Theme.of(context).colorScheme.primary),
                    title: Text(l.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${l.rules.length} ${S.of(context, 'tajweed_rules')}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _LessonScreen(lesson: l),
                        ),
                      );
                      _reload();
                    },
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                icon: const Icon(Icons.quiz_outlined),
                label: Text(S.of(context, 'tajweed_take_quiz')),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const _QuizScreen()),
                  );
                  _reload();
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _LessonScreen extends StatelessWidget {
  const _LessonScreen({required this.lesson});

  final TajweedLesson lesson;

  @override
  Widget build(BuildContext context) {
    final repo = UserDataRepository.instance;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(lesson.intro,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          for (final r in lesson.rules)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(r.explanation),
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
                            r.exampleArabic,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: 24,
                              height: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(r.exampleRef,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: colors.secondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(r.exampleNote,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          if (lesson.audioNote != null)
            InfoCard(
              icon: Icons.volume_up_outlined,
              title: S.of(context, 'tajweed_audio_title'),
              body: lesson.audioNote!,
            ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.check),
            label: Text(S.of(context, 'tajweed_mark_done')),
            onPressed: () async {
              await repo.toggleTajweedDone(lesson.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(S.of(context, 'tajweed_done_msg'))),
                );
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _QuizScreen extends StatefulWidget {
  const _QuizScreen();

  @override
  State<_QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<_QuizScreen> {
  final _questions = TajweedData.quiz;
  final _answers = <int, int>{};
  bool _submitted = false;

  int get _score {
    var s = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i].answerIndex) s++;
    }
    return s;
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    await UserDataRepository.instance
        .saveTajweedQuizBest(_score, _questions.length);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'tajweed_quiz_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < _questions.length; i++)
            _questionCard(i, colors),
          if (!_submitted)
            FilledButton(
              onPressed: _answers.length == _questions.length
                  ? _submit
                  : null,
              child: Text(S.of(context, 'tajweed_submit')),
            )
          else
            Card(
              color: colors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      S.of(context, 'tajweed_score')
                          .replaceAll('{s}', '$_score')
                          .replaceAll('{t}', '${_questions.length}'),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(_score == _questions.length
                        ? S.of(context, 'tajweed_perfect')
                        : S.of(context, 'tajweed_keep_learning')),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(S.of(context, 'common_close')),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _questionCard(int i, ColorScheme colors) {
    final q = _questions[i];
    final picked = _answers[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${i + 1}. ${q.question}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            RadioGroup<int>(
              groupValue: picked,
              onChanged: (v) {
                if (_submitted || v == null) return;
                setState(() => _answers[i] = v);
              },
              child: Column(
                children: [
                  for (var o = 0; o < q.options.length; o++)
                    RadioListTile<int>(
                      value: o,
                      title: Row(
                        children: [
                          Expanded(child: Text(q.options[o])),
                          if (_submitted && o == q.answerIndex)
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                          if (_submitted &&
                              picked == o &&
                              o != q.answerIndex)
                            Icon(Icons.cancel,
                                color: colors.error, size: 20),
                        ],
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            if (_submitted) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (picked == q.answerIndex
                          ? Colors.green
                          : colors.error)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(q.explain,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
