import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Represents a friend's active GPS location pin on the map.
class FriendPin {
  final String id;
  final String name;
  LatLng position;
  final Color color;
  double speed;
  String status;
  final List<LatLng> trail;

  FriendPin({
    required this.id,
    required this.name,
    required this.position,
    required this.color,
    this.speed = 0.0,
    this.status = 'Active',
    List<LatLng>? trail,
  }) : trail = trail ?? [];
}
