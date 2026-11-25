import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Service responsible for managing device GPS permissions and location streams.
class LocationService {
  /// Verifies location services and requests permission if needed.
  /// Throws an [Exception] with a descriptive message if unavailable.
  static Future<void> checkAndRequestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled on this device.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions were denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied in device settings.',
      );
    }
  }

  /// Fetches an initial GPS fix quickly so stationary devices don't wait on movement.
  static Future<Position?> getInitialPosition() async {
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
    } catch (_) {
      // getLastKnownPosition is unsupported on some platforms (e.g. web).
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
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
