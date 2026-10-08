import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

/// A nearby mosque / musalla from OpenStreetMap.
///
/// Source: OpenStreetMap Overpass API (free, no key required).
/// Data quality depends on OSM contributors in the area.
class Mosque {
  const Mosque({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.address,
    this.openingHours,
  });

  final String id;
  final String name;
  final double lat;
  final double lon;
  final String? address;
  final String? openingHours;

  /// Unique id used for favorites: "lat,lon|name".
  String get favId =>
      '${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}|$name';

  /// Haversine distance in kilometres from [lat]/[lon].
  double distanceKm(double lat, double lon) {
    const r = 6371.0;
    final dLat = (this.lat - lat) * pi / 180;
    final dLon = (this.lon - lon) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat * pi / 180) *
            cos(this.lat * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return 2 * r * asin(sqrt(a));
  }
}

/// Optional upgrade: Google Places API (requires key).
///
/// Set GOOGLE_PLACES_API_KEY in .env to enable richer results
/// (ratings, photos, opening hours). The Overpass implementation below
/// remains the default and needs no key.
abstract class MosqueService {
  /// Find mosques within [radiusMeters] of [lat]/[lon].
  Future<List<Mosque>> nearby({
    required double lat,
    required double lon,
    int radiusMeters = 8000,
  });
}

class OverpassMosqueService implements MosqueService {
  static const _endpoint = 'https://overpass-api.de/api/interpreter';
  static const _kmlEndpoint = 'https://overpass.kumi.systems/api/interpreter';

  Future<List<Mosque>> _query(String endpoint, double lat, double lon,
      int radiusMeters) async {
    // Mosques: amenity=place_of_worship + religion=muslim.
    // A second pass without the religion tag catches untagged musallas.
    final ql = '''
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$lat,$lon);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$lat,$lon);
  node["amenity"="place_of_worship"]["name"~"[Mm]osque|[Mm]asjid|[Mm]usalla"](around:$radiusMeters,$lat,$lon);
);
out center 40;
''';
    final res = await http
        .post(Uri.parse(endpoint), body: {'data': ql}).timeout(
              const Duration(seconds: 30),
            );
    if (res.statusCode != 200) {
      throw Exception('Overpass HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final elements = (data['elements'] as List?) ?? [];
    final seen = <String>{};
    final out = <Mosque>[];
    for (final e in elements) {
      final m = e as Map<String, dynamic>;
      final tags = (m['tags'] as Map?) ?? {};
      double? mLat = (m['lat'] as num?)?.toDouble();
      double? mLon = (m['lon'] as num?)?.toDouble();
      final center = m['center'] as Map?;
      mLat ??= (center?['lat'] as num?)?.toDouble();
      mLon ??= (center?['lon'] as num?)?.toDouble();
      if (mLat == null || mLon == null) continue;
      final name = (tags['name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;
      final key =
          '${mLat.toStringAsFixed(4)},${mLon.toStringAsFixed(4)}|$name';
      if (!seen.add(key)) continue;
      final addrParts = [
        tags['addr:housenumber'],
        tags['addr:street'],
        tags['addr:city'] ?? tags['addr:suburb'],
      ].whereType<String>().where((s) => s.isNotEmpty).toList();
      out.add(Mosque(
        id: '${m['type']}/${m['id']}',
        name: name,
        lat: mLat,
        lon: mLon,
        address: addrParts.isEmpty ? null : addrParts.join(', '),
        openingHours: tags['opening_hours'] as String?,
      ));
    }
    out.sort((a, b) => a
        .distanceKm(lat, lon)
        .compareTo(b.distanceKm(lat, lon)));
    return out;
  }

  @override
  Future<List<Mosque>> nearby({
    required double lat,
    required double lon,
    int radiusMeters = 8000,
  }) async {
    try {
      return await _query(_endpoint, lat, lon, radiusMeters);
    } catch (_) {
      // Fallback mirror if the main instance is busy.
      return _query(_kmlEndpoint, lat, lon, radiusMeters);
    }
  }
}
