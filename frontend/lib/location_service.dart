import 'dart:async';
import 'package:frontend/auth.dart';
import 'package:geolocator/geolocator.dart';

// Location Service class
class LocationService {
  StreamSubscription<Position>? _positionStream;

  LocationService();

  // Check and request location permissions
  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Start location updates
  Future<void> startLocationUpdates() async {
    bool hasPermission = await _handlePermission();
    if (!hasPermission) {
      return;
    }

    // Configure location settings
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Minimum distance (in meters) before update
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _sendLocationToBackend(position);
    });
  }

  // Stop location updates
  void stopLocationUpdates() {
    _positionStream?.cancel();
  }

  // Send location to backend
  Future<void> _sendLocationToBackend(Position position) async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest(
        "update-location",
        {'longitude': position.longitude, 'latitude': position.latitude},
      );

      if (response.statusCode != 200) {
        print('Failed to update location: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending location: $e');
    }
  }
}
