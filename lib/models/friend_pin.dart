import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Represents a friend's active GPS location pin on the map.
class FriendPin {
  final String id;
  final String name;
  LatLng position;
  final Color color;

  FriendPin({
    required this.id,
    required this.name,
    required this.position,
    required this.color,
  });
}

