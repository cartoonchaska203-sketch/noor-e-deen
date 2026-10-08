import 'dart:math';

/// Qibla direction result for a position.
class QiblaResult {
  const QiblaResult({required this.bearing, required this.distanceKm});

  /// Degrees clockwise from true North (0–360).
  final double bearing;

  /// Great-circle distance to the Kaaba in kilometres.
  final double distanceKm;
}

/// Pure-math Qibla calculation (no sensors, no network).
///
/// Bearing uses the standard great-circle initial-bearing formula.
/// A live magnetometer compass is a Phase 2 enhancement; until then the UI
/// shows the bearing with "face North, turn X° clockwise" guidance.
class QiblaService {
  QiblaService._();

  static const double makkahLat = 21.4225;
  static const double makkahLon = 39.8262;
  static const double _earthRadiusKm = 6371.0;

  static QiblaResult calculate(double latitude, double longitude) {
    final double phi1 = latitude * pi / 180.0;
    final double phi2 = makkahLat * pi / 180.0;
    final double deltaLambda = (makkahLon - longitude) * pi / 180.0;

    final double y = sin(deltaLambda);
    final double x =
        cos(phi1) * tan(phi2) - sin(phi1) * cos(deltaLambda);
    double bearing = atan2(y, x) * 180.0 / pi;
    bearing = (bearing + 360.0) % 360.0;

    final double deltaPhi = phi2 - phi1;
    final double a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return QiblaResult(
      bearing: bearing,
      distanceKm: _earthRadiusKm * c,
    );
  }
}
