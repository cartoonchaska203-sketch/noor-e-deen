import 'package:adhan/adhan.dart';

/// One row of the daily timetable.
class PrayerEntry {
  const PrayerEntry({required this.id, required this.time});
  final String id; // fajr | sunrise | dhuhr | asr | maghrib | isha
  final DateTime time;
}

/// Result of a prayer-time calculation for a single day.
class PrayerDay {
  const PrayerDay({
    required this.entries,
    required this.nextId,
    required this.nextTime,
    required this.calcMethodId,
  });

  final List<PrayerEntry> entries;
  final String nextId;
  final DateTime nextTime;
  final String calcMethodId;
}

/// Prayer-time calculation backed by the `adhan` package (offline math —
/// works with no internet once coordinates are known).
///
/// Supported methods: Muslim World League, Umm al-Qura, Egyptian,
/// Karachi, ISNA (via North America). Asr: Standard (Shafi) / Hanafi.
class PrayerService {
  PrayerService._();

  static const List<String> supportedMethods = [
    'muslimWorldLeague',
    'ummAlQura',
    'egyptian',
    'karachi',
    'isna',
  ];

  static CalculationParameters paramsFor(
    String methodId,
    String asrMethod,
    Map<String, int> adjustments,
  ) {
    final CalculationMethod method;
    switch (methodId) {
      case 'ummAlQura':
        method = CalculationMethod.umm_al_qura;
        break;
      case 'egyptian':
        method = CalculationMethod.egyptian;
        break;
      case 'karachi':
        method = CalculationMethod.karachi;
        break;
      case 'isna':
        method = CalculationMethod.north_america;
        break;
      case 'muslimWorldLeague':
      default:
        method = CalculationMethod.muslim_world_league;
    }
    final params = method.getParameters();
    params.madhab = asrMethod == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
    params.adjustments = PrayerAdjustments(
      fajr: adjustments['fajr'] ?? 0,
      sunrise: adjustments['sunrise'] ?? 0,
      dhuhr: adjustments['dhuhr'] ?? 0,
      asr: adjustments['asr'] ?? 0,
      maghrib: adjustments['maghrib'] ?? 0,
      isha: adjustments['isha'] ?? 0,
    );
    return params;
  }

  /// Calculates all prayer times for [date] at the given coordinates.
  /// Throws only on invalid input; callers should still guard with try/catch.
  static PrayerDay calculate({
    required double latitude,
    required double longitude,
    required DateTime date,
    required String methodId,
    required String asrMethod,
    required Map<String, int> adjustments,
  }) {
    final coords = Coordinates(latitude, longitude);
    final params = paramsFor(methodId, asrMethod, adjustments);
    final times = PrayerTimes(coords, DateComponents.from(date), params);

    final entries = <PrayerEntry>[
      PrayerEntry(id: 'fajr', time: times.fajr),
      PrayerEntry(id: 'sunrise', time: times.sunrise),
      PrayerEntry(id: 'dhuhr', time: times.dhuhr),
      PrayerEntry(id: 'asr', time: times.asr),
      PrayerEntry(id: 'maghrib', time: times.maghrib),
      PrayerEntry(id: 'isha', time: times.isha),
    ];

    final Prayer next = times.nextPrayer();
    late final String nextId;
    late final DateTime nextTime;
    if (next == Prayer.none) {
      // After Isha: next prayer is tomorrow's Fajr.
      final tomorrow = PrayerTimes(
        coords,
        DateComponents.from(date.add(const Duration(days: 1))),
        params,
      );
      nextId = 'fajr';
      nextTime = tomorrow.fajr;
    } else {
      nextId = next.name;
      // timeForPrayer is nullable in adhan 2.x; fall back to the matching
      // entry (or now) so the countdown never receives null.
      nextTime = times.timeForPrayer(next) ??
          entries
              .firstWhere((e) => e.id == next.name,
                  orElse: () => entries.first)
              .time;
    }

    return PrayerDay(
      entries: entries,
      nextId: nextId,
      nextTime: nextTime,
      calcMethodId: methodId,
    );
  }
}
