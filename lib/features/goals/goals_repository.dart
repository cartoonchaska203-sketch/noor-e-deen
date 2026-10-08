import '../../data/repositories/user_data_repository.dart';

/// Goal types supported by the app.
class GoalType {
  GoalType._();
  static const prayers = 'prayers'; // N prayers logged per day
  static const quranAyahs = 'quran_ayahs'; // cumulative ayahs read
  static const tasbeeh = 'tasbeeh'; // dhikr count per day
  static const adhkar = 'adhkar'; // adhkar sets completed per day
  static const fasting = 'fasting'; // fasts logged (cumulative)
  static const hifz = 'hifz'; // ayahs memorized (cumulative)

  static const all = [prayers, quranAyahs, tasbeeh, adhkar, fasting, hifz];

  /// True for goals measured per-day (streaks apply).
  static bool isDaily(String type) =>
      type == prayers || type == tasbeeh || type == adhkar;
}

/// Computed progress for one goal.
class GoalProgress {
  const GoalProgress({
    required this.current,
    required this.target,
    required this.streak,
  });

  final int current;
  final int target;
  final int streak; // consecutive days meeting target (daily goals)

  double get fraction =>
      target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);
  bool get met => current >= target;
}

/// Reads goals from storage and computes live progress from user data.
class GoalsRepository {
  GoalsRepository({UserDataRepository? userData})
      : _user = userData ?? UserDataRepository.instance;

  final UserDataRepository _user;

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<Map<String, dynamic>>> goals() => _user.goals();
  Future<String> addGoal(Map<String, dynamic> g) => _user.addGoal(g);
  Future<void> deleteGoal(String id) => _user.deleteGoal(id);

  Future<GoalProgress> progress(Map<String, dynamic> goal) async {
    final type = goal['type'] as String? ?? GoalType.prayers;
    final target = (goal['target'] as num?)?.toInt() ?? 1;
    final today = _dayKey(DateTime.now());

    int current = 0;
    int streak = 0;

    switch (type) {
      case GoalType.prayers:
        final log = await _user.salahLog();
        current = log[today]?.length ?? 0;
        streak = _streak(log.map((k, v) => MapEntry(k, v.length)), target);
      case GoalType.quranAyahs:
        current = await _user.readAyahCount();
      case GoalType.tasbeeh:
        final totals = await _user.tasbeehTotalsByDay();
        current = totals[today] ?? 0;
        streak = _streak(totals, target);
      case GoalType.adhkar:
        final done = await _user.adhkarDoneToday();
        current = done.length;
        final counts = await _user.adhkarCountsByDay();
        streak = _streak(counts, target);
      case GoalType.fasting:
        final log = await _user.fastingLog();
        current = log.values.where((s) => s == 'fasted').length;
      case GoalType.hifz:
        final states = await _user.hifzStates();
        current =
            states.values.where((s) => s == 'memorized').length;
    }
    return GoalProgress(current: current, target: target, streak: streak);
  }

  int _streak(Map<String, int> perDay, int target) {
    var streak = 0;
    var day = DateTime.now();
    if ((perDay[_dayKey(day)] ?? 0) < target) {
      day = day.subtract(const Duration(days: 1));
    }
    while ((perDay[_dayKey(day)] ?? 0) >= target) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
