import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/friend_pin.dart';
import '../services/location_service.dart';
import '../utils/distance_utils.dart';
import '../widgets/map_header.dart';
import '../widgets/friends_tray.dart';

/// Main screen featuring the interactive tracking map, markers, and friend tray.
class MapTrackerScreen extends StatefulWidget {
  const MapTrackerScreen({super.key});

  @override
  State<MapTrackerScreen> createState() => _MapTrackerScreenState();
}

class _MapTrackerScreenState extends State<MapTrackerScreen> {
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  // Initial fallback coordinates before GPS lock
  LatLng _myLocation = const LatLng(37.7749, -122.4194);
  bool _hasGpsFix = false;
  bool _isTracking = true;
  String _statusMessage = 'Connecting to GPS...';

  // Demo friends in the tracking room
  final List<FriendPin> _friends = [
    FriendPin(
      id: 'f1',
      name: 'Alex',
      position: const LatLng(37.7765, -122.4182),
      color: const Color(0xFF10B981),
    ),
    FriendPin(
      id: 'f2',
      name: 'Sarah',
      position: const LatLng(37.7731, -122.4208),
      color: const Color(0xFFEC4899),
    ),
    FriendPin(
      id: 'f3',
      name: 'Dave',
      position: const LatLng(37.7758, -122.4235),
      color: const Color(0xFFF59E0B),
    ),
  ];

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    try {
      await LocationService.checkAndRequestPermission();

      if (!mounted) return;
      setState(() => _statusMessage = 'Acquiring GPS fix...');

      _positionStream = LocationService.getPositionStream().listen(
        (Position pos) {
          if (!mounted) return;

          final newLatLng = LatLng(pos.latitude, pos.longitude);

          setState(() {
            _myLocation = newLatLng;
            _hasGpsFix = true;
            final speedKmH = (pos.speed * 3.6).clamp(0, 999);
            _statusMessage = 'Live • ${speedKmH.toStringAsFixed(1)} km/h';

            // Position demo friends relative to user's real coordinates
            _friends[0].position = LatLng(pos.latitude + 0.0015, pos.longitude + 0.0012);
            _friends[1].position = LatLng(pos.latitude - 0.0018, pos.longitude - 0.0014);
            _friends[2].position = LatLng(pos.latitude + 0.0020, pos.longitude - 0.0016);
          });

          if (_isTracking && _isMapReady) {
            _safeMoveCamera(newLatLng, 16.0);
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _statusMessage = 'GPS Error: $error');
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _statusMessage = '$error');
    }
  }

  void _safeMoveCamera(LatLng target, double zoom) {
    if (_isMapReady) {
      try {
        _mapController.move(target, zoom);
      } catch (_) {}
    }
  }

  void _toggleTracking() {
    setState(() => _isTracking = !_isTracking);
    if (_isTracking) {
      _safeMoveCamera(_myLocation, 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Single reliable Map API (OpenStreetMap)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _myLocation,
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onMapReady: () {
                setState(() => _isMapReady = true);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.friend_tracker',
              ),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // User's Location Marker
                  Marker(
                    point: _myLocation,
                    width: 60,
                    height: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.location_pin,
                          color: Color(0xFF0284C7),
                          size: 36,
                        ),
                      ],
                    ),
                  ),

                  // Friends Markers
                  ..._friends.map((friend) {
                    final dist = DistanceUtils.getDistanceInMeters(_myLocation, friend.position);
                    return Marker(
                      point: friend.position,
                      width: 80,
                      height: 65,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: friend.color, width: 1.5),
                            ),
                            child: Text(
                              '${friend.name} (${DistanceUtils.formatDistance(dist)})',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: friend.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.person_pin_circle,
                            color: friend.color,
                            size: 34,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Floating Top Header
          MapHeader(
            hasGpsFix: _hasGpsFix,
            statusMessage: _statusMessage,
            isTracking: _isTracking,
            onToggleTracking: _toggleTracking,
          ),

          // Floating Bottom Friends Tray
          FriendsTray(
            friends: _friends,
            myLocation: _myLocation,
            onSelectFriend: (target) => _safeMoveCamera(target, 16.5),
          ),
        ],
      ),
    );
  }
}
