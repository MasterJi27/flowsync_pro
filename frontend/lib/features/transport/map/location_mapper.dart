/// Maps step names to geographic coordinates for visualization
/// This is a helper to demonstrate flow progression on maps
class LocationCoordinate {
  final double latitude;
  final double longitude;
  final String label;
  final String? description;

  LocationCoordinate({
    required this.latitude,
    required this.longitude,
    required this.label,
    this.description,
  });

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'label': label,
        'description': description,
      };
}

class LocationMapper {
  // Default locations for common step types
  static const Map<String, Map<String, double>> _defaultLocations = {
    // Indian cities
    'warehouse': {'lat': 28.7041, 'lng': 77.1025}, // Delhi
    'port': {'lat': 19.0760, 'lng': 72.8777}, // Mumbai Port
    'customs': {'lat': 28.5355, 'lng': 77.0992}, // Delhi Customs
    'distribution': {'lat': 28.7041, 'lng': 77.1025}, // Delhi
    'client': {'lat': 28.5921, 'lng': 77.2064}, // Noida (common client location)
    'truck': {'lat': 28.7041, 'lng': 77.1025}, // Default truck location
  };

  /// Parse step name and return coordinates
  /// Supports both exact matches and fuzzy matching
  static LocationCoordinate? getCoordinates(String stepName) {
    if (stepName.isEmpty) return null;

    final normalizedName = stepName.toLowerCase().trim();

    // Exact match
    if (_defaultLocations.containsKey(normalizedName)) {
      final loc = _defaultLocations[normalizedName]!;
      return LocationCoordinate(
        latitude: loc['lat']!,
        longitude: loc['lng']!,
        label: stepName,
      );
    }

    // Fuzzy matching
    for (final key in _defaultLocations.keys) {
      if (normalizedName.contains(key) || key.contains(normalizedName)) {
        final loc = _defaultLocations[key]!;
        return LocationCoordinate(
          latitude: loc['lat']!,
          longitude: loc['lng']!,
          label: stepName,
          description: 'Inferred from: $key',
        );
      }
    }

    // No match found
    return null;
  }

  /// Get all available step locations
  static List<LocationCoordinate> getAllLocations() {
    return _defaultLocations.entries.map((e) {
      return LocationCoordinate(
        latitude: e.value['lat']!,
        longitude: e.value['lng']!,
        label: e.key,
      );
    }).toList();
  }

  /// Add custom location mapping
  static Map<String, LocationCoordinate> customMappings = {};

  /// Get location with custom mappings fallback
  static LocationCoordinate? getLocationWithCustom(String stepName) {
    if (customMappings.containsKey(stepName)) {
      return customMappings[stepName];
    }
    return getCoordinates(stepName);
  }

  /// Register custom location
  static void registerCustomLocation(String stepName, LocationCoordinate coordinate) {
    customMappings[stepName] = coordinate;
  }

  /// Calculate distance between two coordinates (in kilometers)
  /// Using Haversine formula
  static double calculateDistance(
    LocationCoordinate from,
    LocationCoordinate to,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _toRadians(to.latitude - from.latitude);
    final dLng = _toRadians(to.longitude - from.longitude);

    final a = (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
        (Math.cos(_toRadians(from.latitude)) *
            Math.cos(_toRadians(to.latitude)) *
            Math.sin(dLng / 2) *
            Math.sin(dLng / 2));

    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) {
    return degrees * Math.pi / 180.0;
  }

  /// Get map center point for a set of coordinates
  static LocationCoordinate getCenterPoint(List<LocationCoordinate> coordinates) {
    if (coordinates.isEmpty) {
      throw ArgumentError('Cannot calculate center of empty list');
    }

    final avgLat = coordinates.map((c) => c.latitude).reduce((a, b) => a + b) / coordinates.length;
    final avgLng = coordinates.map((c) => c.longitude).reduce((a, b) => a + b) / coordinates.length;

    return LocationCoordinate(
      latitude: avgLat,
      longitude: avgLng,
      label: 'Center Point',
    );
  }

  /// Create a route from step sequence
  static List<LocationCoordinate> createRoute(List<String> stepNames) {
    return stepNames
        .map((name) => getCoordinates(name))
        .where((coord) => coord != null)
        .cast<LocationCoordinate>()
        .toList();
  }

  /// Estimate travel time between two locations (very simplified)
  /// Returns estimated time in minutes
  static int estimateTravelTime(LocationCoordinate from, LocationCoordinate to) {
    final distanceKm = calculateDistance(from, to);
    // Assume average speed of 40 km/h in urban areas
    final timeHours = distanceKm / 40.0;
    return (timeHours * 60).toInt();
  }
}

/// Math utilities for location calculations
class Math {
  static const double pi = 3.14159265359;

  static double sin(double x) {
    return _sin(x);
  }

  static double cos(double x) {
    return _cos(x);
  }

  static double sqrt(double x) {
    if (x < 0) throw ArgumentError('Cannot take sqrt of negative number');
    return _sqrt(x);
  }

  static double atan2(double y, double x) {
    return _atan2(y, x);
  }

  // Newton-Raphson method for sqrt
  static double _sqrt(double x) {
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  // Simple Taylor series for sin
  static double _sin(double x) {
    x = x % (2 * pi);
    double result = 0;
    double term = x;
    for (int i = 1; i < 10; i++) {
      result += term;
      term *= -x * x / ((2 * i) * (2 * i + 1));
    }
    return result;
  }

  // Simple Taylor series for cos
  static double _cos(double x) {
    x = x % (2 * pi);
    double result = 1;
    double term = 1;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  // atan2 using built-in approach
  static double _atan2(double y, double x) {
    // Simplified atan2 - use Dart's math library would be better
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + pi;
    if (x < 0 && y < 0) return _atan(y / x) - pi;
    if (x == 0 && y > 0) return pi / 2;
    if (x == 0 && y < 0) return -pi / 2;
    return 0;
  }

  static double _atan(double x) {
    double result = x;
    double power = x;
    for (int i = 1; i < 10; i++) {
      power *= -x * x;
      result += power / (2 * i + 1);
    }
    return result;
  }
}
