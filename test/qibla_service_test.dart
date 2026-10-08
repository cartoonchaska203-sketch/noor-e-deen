import 'package:flutter_test/flutter_test.dart';
import 'package:noor_e_deen/core/services/qibla_service.dart';

void main() {
  group('QiblaService.calculate', () {
    test('Manchester bearing is approximately 119 degrees', () {
      // Manchester, UK: 53.4808, -2.2426
      final result = QiblaService.calculate(53.4808, -2.2426);
      expect(result.bearing, closeTo(119, 2));
    });

    test('Makkah itself has ~0 distance', () {
      final result = QiblaService.calculate(
          QiblaService.makkahLat, QiblaService.makkahLon);
      expect(result.distanceKm, lessThan(1));
    });

    test('bearing is always within 0-360', () {
      for (final lat in [-45.0, 0.0, 30.0, 60.0]) {
        for (final lon in [-120.0, -30.0, 45.0, 150.0]) {
          final r = QiblaService.calculate(lat, lon);
          expect(r.bearing, greaterThanOrEqualTo(0));
          expect(r.bearing, lessThan(360));
          expect(r.distanceKm, greaterThan(0));
        }
      }
    });

    test('distance Manchester to Makkah is plausible (~5000 km)', () {
      final result = QiblaService.calculate(53.4808, -2.2426);
      expect(result.distanceKm, closeTo(5025, 300));
    });

    test('Karachi bearing differs from Manchester', () {
      final manchester = QiblaService.calculate(53.4808, -2.2426);
      final karachi = QiblaService.calculate(24.8607, 67.0011);
      expect((manchester.bearing - karachi.bearing).abs(),
          greaterThan(10));
    });
  });
}
