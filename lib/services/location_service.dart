import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Service responsible for managing device GPS permissions and location streams.
class LocationService {
  /// Verifies location services and requests permission if needed.
  /// Throws an exception with a descriptive error message if unavailable.
  static Future<void> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled on this device.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions were denied.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied in device settings.';
    }
  }

  /// Returns a stream of real-time position updates.
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Notify every 1 meter moved
      ),
    );
  }
}

