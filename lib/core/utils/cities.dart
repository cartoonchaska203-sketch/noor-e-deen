/// Manual city fallback list (used when GPS is denied / unavailable).
class City {
  const City({
    required this.name,
    required this.country,
    required this.lat,
    required this.lon,
  });

  final String name;
  final String country;
  final double lat;
  final double lon;
}

const List<City> kCities = [
  City(name: 'Makkah', country: 'Saudi Arabia', lat: 21.4225, lon: 39.8262),
  City(name: 'Madinah', country: 'Saudi Arabia', lat: 24.5247, lon: 39.5692),
  City(name: 'Karachi', country: 'Pakistan', lat: 24.8607, lon: 67.0011),
  City(name: 'Lahore', country: 'Pakistan', lat: 31.5204, lon: 74.3587),
  City(name: 'Islamabad', country: 'Pakistan', lat: 33.6844, lon: 73.0479),
  City(name: 'Faisalabad', country: 'Pakistan', lat: 31.4504, lon: 73.1350),
  City(name: 'Dubai', country: 'UAE', lat: 25.2048, lon: 55.2708),
  City(name: 'Doha', country: 'Qatar', lat: 25.2854, lon: 51.5310),
  City(name: 'Istanbul', country: 'Turkiye', lat: 41.0082, lon: 28.9784),
  City(name: 'Cairo', country: 'Egypt', lat: 30.0444, lon: 31.2357),
  City(name: 'London', country: 'UK', lat: 51.5074, lon: -0.1278),
  City(name: 'Manchester', country: 'UK', lat: 53.4808, lon: -2.2426),
  City(name: 'Birmingham', country: 'UK', lat: 52.4862, lon: -1.8904),
  City(name: 'New York', country: 'USA', lat: 40.7128, lon: -74.0060),
  City(name: 'Toronto', country: 'Canada', lat: 43.6532, lon: -79.3832),
  City(name: 'Sydney', country: 'Australia', lat: -33.8688, lon: 151.2093),
];

City cityByName(String name) {
  return kCities.firstWhere(
    (c) => c.name == name,
    orElse: () => kCities.firstWhere((c) => c.name == 'Manchester'),
  );
}
