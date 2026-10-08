import 'package:flutter_test/flutter_test.dart';
import 'package:noor_e_deen/core/services/prayer_service.dart';

void main() {
  group('PrayerService.calculate', () {
    final adjustments = <String, int>{
      'fajr': 0,
      'sunrise': 0,
      'dhuhr': 0,
      'asr': 0,
      'maghrib': 0,
      'isha': 0,
    };

    PrayerDay calc(String method, String asr) =>
        PrayerService.calculate(
          latitude: 53.4808, // Manchester
          longitude: -2.2426,
          date: DateTime(2026, 10, 8),
          methodId: method,
          asrMethod: asr,
          adjustments: adjustments,
        );

    test('prayer times are in chronological order', () {
      final day = calc('muslimWorldLeague', 'standard');
      final times = [for (final e in day.entries) e.time];
      for (var i = 0; i < times.length - 1; i++) {
        expect(times[i].isBefore(times[i + 1]), isTrue,
            reason: 'prayer $i should be before prayer ${i + 1}');
      }
    });

    test('all six prayers are present', () {
      final day = calc('muslimWorldLeague', 'standard');
      final ids = day.entries.map((e) => e.id).toSet();
      expect(ids,
          {'fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'});
    });

    test('all supported methods produce valid days', () {
      for (final m in PrayerService.supportedMethods) {
        final day = calc(m, 'standard');
        expect(day.entries.length, 6);
        expect(day.nextId.isNotEmpty, isTrue);
      }
    });

    test('hanafi asr is later than standard asr', () {
      final standard = calc('muslimWorldLeague', 'standard');
      final hanafi = calc('muslimWorldLeague', 'hanafi');
      final stdAsr =
          standard.entries.firstWhere((e) => e.id == 'asr').time;
      final hanAsr =
          hanafi.entries.firstWhere((e) => e.id == 'asr').time;
      expect(hanAsr.isAfter(stdAsr), isTrue);
    });

    test('manual adjustment shifts the prayer time', () {
      final base = calc('muslimWorldLeague', 'standard');
      final adjusted = PrayerService.calculate(
        latitude: 53.4808,
        longitude: -2.2426,
        date: DateTime(2026, 10, 8),
        methodId: 'muslimWorldLeague',
        asrMethod: 'standard',
        adjustments: {...adjustments, 'fajr': 10},
      );
      final baseFajr =
          base.entries.firstWhere((e) => e.id == 'fajr').time;
      final adjFajr =
          adjusted.entries.firstWhere((e) => e.id == 'fajr').time;
      expect(adjFajr.difference(baseFajr).inMinutes, 10);
    });
  });
}
