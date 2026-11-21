import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/friend_pin.dart';
import '../services/location_service.dart';
import '../utils/distance_utils.dart';
import '../widgets/map_header.dart';
import '../widgets/friends_tray.dart';

/// Interactive live tracking map supporting Streets & Satellite views,
/// live GPS updates, breadcrumb paths, and real-time friend movement.
class MapTrackerScreen extends StatefulWidget {
  const MapTrackerScreen({super.key});

  @override
  State<MapTrackerScreen> createState() => _MapTrackerScreenState();
}

class _MapTrackerScreenState extends State<MapTrackerScreen> {
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  bool _isSatellite = false;

  // Initial center before GPS resolves
  LatLng _myLocation = const LatLng(37.7749, -122.4194);
  bool _hasGpsFix = false;
  bool _isTracking = true;
  String _statusMessage = 'Connecting to GPS...';

  // Breadcrumb path of user's movement
  final List<LatLng> _userTrail = [];

  // Active friends with simulated realistic live movement
  final List<FriendPin> _friends = [
    FriendPin(
      id: 'f1',
      name: 'Alex',
      position: const LatLng(37.7765, -122.4182),
      color: const Color(0xFF10B981),
      speed: 4.2,
      status: 'Walking',
    ),
    FriendPin(
      id: 'f2',
      name: 'Sarah',
      position: const LatLng(37.7731, -122.4208),
      color: const Color(0xFFEC4899),
      speed: 12.5,
      status: 'Cycling',
    ),
    FriendPin(
      id: 'f3',
      name: 'Dave',
      position: const LatLng(37.7758, -122.4235),
      color: const Color(0xFFF59E0B),
      speed: 0.0,
      status: 'Stationary',
    ),
  ];

  StreamSubscription<Position>? _positionStream;
  Timer? _liveSimulationTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    _startLiveFriendSimulation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _liveSimulationTimer?.cancel();
    super.dispose();
  }

  /// Sets up real-time device GPS listening
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

            // Append to breadcrumb trail if moved more than 2 meters
            if (_userTrail.isEmpty ||
                DistanceUtils.getDistanceInMeters(_userTrail.last, newLatLng) > 2) {
              _userTrail.add(newLatLng);
              if (_userTrail.length > 200) _userTrail.removeAt(0);
            }

            // Reposition friends around user's real location on first GPS fix
            if (_userTrail.length == 1) {
              _friends[0].position =
                  LatLng(pos.latitude + 0.0016, pos.longitude + 0.0014);
              _friends[1].position =
                  LatLng(pos.latitude - 0.0018, pos.longitude - 0.0016);
              _friends[2].position =
                  LatLng(pos.latitude + 0.0022, pos.longitude - 0.0019);
            }
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

  /// Simulates realistic live friend movement so the user can see live tracking
  void _startLiveFriendSimulation() {
    _liveSimulationTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!mounted) return;

      setState(() {
        for (var friend in _friends) {
          // Alex moves along north-east path
          if (friend.id == 'f1') {
            final latStep = (_random.nextDouble() - 0.4) * 0.00015;
            final lngStep = (_random.nextDouble() - 0.3) * 0.00015;
            friend.position = LatLng(
              friend.position.latitude + latStep,
              friend.position.longitude + lngStep,
            );
            friend.speed = 3.5 + _random.nextDouble() * 2.0;
            friend.trail.add(friend.position);
            if (friend.trail.length > 30) friend.trail.removeAt(0);
          }
          // Sarah cycles around south-west
          else if (friend.id == 'f2') {
            final latStep = (_random.nextDouble() - 0.5) * 0.00025;
            final lngStep = (_random.nextDouble() - 0.45) * 0.00025;
            friend.position = LatLng(
              friend.position.latitude + latStep,
              friend.position.longitude + lngStep,
            );
            friend.speed = 10.0 + _random.nextDouble() * 5.0;
            friend.trail.add(friend.position);
            if (friend.trail.length > 30) friend.trail.removeAt(0);
          }
        }
      });
    });
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

  void _toggleMapStyle() {
    setState(() => _isSatellite = !_isSatellite);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Professional Map Layer (CartoDB Voyager or Esri World Imagery)
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
              // Tile Layer: CartoDB Voyager (Street) or Esri (Satellite)
              if (!_isSatellite)
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.friend_tracker',
                )
              else
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.friend_tracker',
                ),

              // Breadcrumb Polyline Layer (User trail & Friend trails)
              PolylineLayer(
                polylines: [
                  // User's own movement trail
                  if (_userTrail.length > 1)
                    Polyline(
                      points: _userTrail,
                      color: const Color(0xFF0284C7),
                      strokeWidth: 4.0,
                    ),

                  // Friend movement trails
                  ..._friends
                      .where((f) => f.trail.length > 1)
                      .map((f) => Polyline(
                            points: f.trail,
                            color: f.color.withAlpha(160),
                            strokeWidth: 3.0,
                          )),

                  // Proximity lines connecting you to each friend
                  ..._friends.map(
                    (f) => Polyline(
                      points: [_myLocation, f.position],
                      color: f.color.withAlpha(90),
                      strokeWidth: 2.0,
                      pattern: StrokePattern.dashed(segments: const [6, 8]),
                    ),
                  ),
                ],
              ),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // User's Location Marker (Glowing blue avatar with pulsing radar ring)
                  Marker(
                    point: _myLocation,
                    width: 70,
                    height: 70,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Color(0x660284C7), blurRadius: 6),
                            ],
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0284C7),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xAA0284C7),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Friends Markers (Live moving pins with distance & status)
                  ..._friends.map((friend) {
                    final dist = DistanceUtils.getDistanceInMeters(
                        _myLocation, friend.position);
                    return Marker(
                      point: friend.position,
                      width: 90,
                      height: 75,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xEE0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: friend.color, width: 1.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x66000000),
                                  blurRadius: 6,
                                ),
                              ],
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
                          const SizedBox(height: 2),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: friend.color,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: friend.color.withAlpha(160),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                friend.name.isNotEmpty ? friend.name[0] : '?',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Floating Top Header with GPS Status & Layer Switcher
          MapHeader(
            hasGpsFix: _hasGpsFix,
            statusMessage: _statusMessage,
            isTracking: _isTracking,
            isSatellite: _isSatellite,
            onToggleTracking: _toggleTracking,
            onToggleMapStyle: _toggleMapStyle,
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
