import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Helper utilities for calculating and formatting GPS distances.
class DistanceUtils {
  /// Computes distance in meters between two coordinates using Geolocator.
  static double getDistanceInMeters(LatLng p1, LatLng p2) {
    return Geolocator.distanceBetween(
      p1.latitude,
      p1.longitude,
      p2.latitude,
      p2.longitude,
    );
  }

  /// Formats distance into a human-readable string (e.g. "250 m" or "1.4 km").
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
