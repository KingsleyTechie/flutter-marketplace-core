import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static Future<Position> getCurrentPosition() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }
    
    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
    
    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
  
  static Future<LatLng> getCurrentLatLng() async {
    final position = await getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }
  
  static Future<String> getAddressFromLatLng(LatLng latLng) async {
    try {
      final places = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      
      if (places.isNotEmpty) {
        final place = places.first;
        return _formatAddress(place);
      }
      
      return 'Unknown Location';
    } catch (e) {
      print('Failed to get address: $e');
      return 'Location: ${latLng.latitude.toStringAsFixed(4)}, '
             '${latLng.longitude.toStringAsFixed(4)}';
    }
  }
  
  static Future<LatLng?> getLatLngFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        return LatLng(location.latitude, location.longitude);
      }
      
      return null;
    } catch (e) {
      print('Failed to get coordinates: $e');
      return null;
    }
  }
  
  static Future<double> calculateDistance(
    LatLng start,
    LatLng end, {
    bool inKilometers = true,
  }) async {
    final distance = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    
    return inKilometers ? distance / 1000 : distance;
  }
  
  static Future<List<Placemark>> searchPlaces(String query) async {
    try {
      return await placemarkFromAddress(query);
    } catch (e) {
      print('Failed to search places: $e');
      return [];
    }
  }
  
  static Future<List<Placemark>> getNearbyPlaces(
    LatLng location, {
    double radius = 1000, // meters
  }) async {
    try {
      // This is a simplified version
      // In a real app, you would use Google Places API
      return await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
    } catch (e) {
      print('Failed to get nearby places: $e');
      return [];
    }
  }
  
  static Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: locationSettings ??
          const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // meters
          ),
    );
  }
  
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }
  
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }
  
  static String _formatAddress(Placemark place) {
    final parts = <String>[];
    
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }
    
    return parts.join(', ');
  }
  
  static Future<bool> isLocationWithinRadius({
    required LatLng center,
    required LatLng point,
    required double radiusKm,
  }) async {
    final distance = await calculateDistance(center, point);
    return distance <= radiusKm;
  }
  
  static LatLngBounds getBoundsFromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (final point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
