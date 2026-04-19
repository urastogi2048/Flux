import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GeocodingService {
  /// Converts a location string to LatLng coordinates using OpenStreetMap Nominatim API
  /// If exact location fails, tries to extract and search for the first/primary location
  /// Returns default coordinates for India if not found
  static Future<LatLng> getCoordinatesFromLocation(String locationString,
      {int retryCount = 0, int maxRetries = 2, bool isRetryWithFallback = false}) async {
    try {
      // Clean up the input
      final cleanLocation = locationString.trim();
      
      print('[GeocodingService] 🔍 Geocoding: "$cleanLocation" (attempt ${retryCount + 1}/${ maxRetries + 1})');
      
      // Use OpenStreetMap Nominatim API with proper User-Agent
      final encodedLocation = Uri.encodeComponent(cleanLocation);
      final url = 'https://nominatim.openstreetmap.org/search?q=$encodedLocation&format=json&limit=1&countrycodes=in';
      
      print('[GeocodingService] 📡 API URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'FluxApp/1.0 (Task Management App)',
        },
      ).timeout(
        const Duration(seconds: 10),
      );

      print('[GeocodingService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List;
        print('[GeocodingService] Results count: ${results.length}');
        
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lng = double.parse(results[0]['lon']);
          final displayName = results[0]['display_name'] ?? 'Unknown';
          final result = LatLng(lat, lng);
          print('[GeocodingService] ✅ Found: $displayName');
          print('[GeocodingService] ✓ Successfully geocoded to: $lat, $lng');
          return result;
        } else {
          // No results - try fallback strategy
          if (!isRetryWithFallback) {
            print('[GeocodingService] ❌ No exact results found, trying fallback...');
            
            // Try just the first location if multiple are comma-separated
            if (cleanLocation.contains(',')) {
              final firstLocation = cleanLocation.split(',')[0].trim();
              print('[GeocodingService] 🔄 Fallback: trying first location only: "$firstLocation"');
              return getCoordinatesFromLocation(firstLocation,
                  retryCount: retryCount, maxRetries: maxRetries, isRetryWithFallback: true);
            }
          }
          
          print('[GeocodingService] ❌ No results returned for "$cleanLocation"');
        }
      } else if (response.statusCode == 429 || response.statusCode == 403) {
        // Rate limited or forbidden - retry with exponential backoff
        if (retryCount < maxRetries) {
          final delayMs = 1000 * (retryCount + 1); // 1s, 2s, 3s...
          print('[GeocodingService] ⏳ Rate limited, retrying in ${delayMs}ms...');
          await Future.delayed(Duration(milliseconds: delayMs));
          return getCoordinatesFromLocation(locationString,
              retryCount: retryCount + 1, maxRetries: maxRetries, isRetryWithFallback: isRetryWithFallback);
        } else {
          print('[GeocodingService] ❌ Max retries reached for "$cleanLocation"');
        }
      } else {
        print('[GeocodingService] ❌ API error (${response.statusCode})');
        print('[GeocodingService] Response: ${response.body}');
      }
    } catch (e) {
      print('[GeocodingService] ❌ Exception: $e');
    }
    
    // Return default coordinates (India center) if geocoding fails
    print('[GeocodingService] ↩️ Returning India center fallback');
    return const LatLng(20.5937, 78.9629);
  }

  /// Converts multiple locations to LatLng
  static Future<Map<String, LatLng>> getCoordinatesForLocations(
    List<String> locations,
  ) async {
    final Map<String, LatLng> result = {};
    
    for (final location in locations) {
      result[location] = await getCoordinatesFromLocation(location);
    }
    
    return result;
  }

  /// Returns a default center point for India
  static LatLng getIndiaCenter() {
    return const LatLng(20.5937, 78.9629);
  }

  /// Returns a default zoom level for India view
  static double getIndiaZoomLevel() {
    return 4.5;
  }
}
