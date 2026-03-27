import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

/// Service for geocoding locations using Nominatim (OpenStreetMap)
class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  /// Search for a location and return coordinates
  Future<LatLng?> searchLocation(String query) async {
    if (query.trim().isEmpty) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search').replace(
          queryParameters: {
            'q': query,
            'format': 'json',
            'limit': '1',
            'addressdetails': '1',
          },
        ),
        headers: {'User-Agent': 'JobSearchApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          final result = results[0];
          final lat = double.parse(result['lat']);
          final lon = double.parse(result['lon']);
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    return null;
  }

  /// Reverse geocode coordinates to get location name
  Future<String?> reverseGeocode(LatLng position) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reverse').replace(
          queryParameters: {
            'lat': position.latitude.toString(),
            'lon': position.longitude.toString(),
            'format': 'json',
            'addressdetails': '1',
          },
        ),
        headers: {'User-Agent': 'JobSearchApp/1.0'},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final address = result['address'];

        // Try to get city, town, or village name
        final locationName =
            address['city'] ??
            address['town'] ??
            address['village'] ??
            address['county'] ??
            address['state'];

        return locationName;
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
    return null;
  }
}
