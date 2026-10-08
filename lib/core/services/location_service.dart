import 'package:geolocator/geolocator.dart';

import '../utils/cities.dart';

/// Outcome of a location resolution attempt.
enum LocationStatus {
  ok,
  serviceDisabled,
  denied,
  deniedForever,
  error,
}

/// Coordinates + human label + status. On any GPS failure the service falls
/// back to the user's manual city so prayer times and Qibla keep working.
class ResolvedLocation {
  const ResolvedLocation({
    required this.lat,
    required this.lon,
    required this.label,
    required this.status,
    this.usedFallback = false,
    this.message,
  });

  final double lat;
  final double lon;
  final String label;
  final LocationStatus status;
  final bool usedFallback;
  final String? message;
}

class LocationService {
  LocationService._();

  static Future<ResolvedLocation> resolve({
    required String mode, // 'gps' | 'manual'
    required String manualCityName,
  }) async {
    final City manual = cityByName(manualCityName);

    ResolvedLocation fallback(LocationStatus status, String? message) {
      return ResolvedLocation(
        lat: manual.lat,
        lon: manual.lon,
        label: '${manual.name}, ${manual.country}',
        status: status,
        usedFallback: true,
        message: message,
      );
    }

    if (mode == 'manual') {
      return ResolvedLocation(
        lat: manual.lat,
        lon: manual.lon,
        label: '${manual.name}, ${manual.country}',
        status: LocationStatus.ok,
      );
    }

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return fallback(
          LocationStatus.serviceDisabled,
          'Location services are turned off on this device.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return fallback(
          LocationStatus.denied,
          'Location permission was denied.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return fallback(
          LocationStatus.deniedForever,
          'Location permission is permanently denied. Enable it in system settings or use a manual city.',
        );
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return ResolvedLocation(
        lat: position.latitude,
        lon: position.longitude,
        label: 'GPS location',
        status: LocationStatus.ok,
      );
    } catch (e) {
      return fallback(
        LocationStatus.error,
        'Could not determine GPS position ($e).',
      );
    }
  }
}
