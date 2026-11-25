import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/friend_pin.dart';
import '../services/location_service.dart';
import '../utils/distance_utils.dart';
import '../widgets/friends_tray.dart';
import '../widgets/map_header.dart';

/// Interactive live tracking map using CartoDB Voyager tiles,
/// live GPS updates, breadcrumb trails, and friend movement.
class MapTrackerScreen extends StatefulWidget {
  const MapTrackerScreen({super.key});

  @override
  State<MapTrackerScreen> createState() => _MapTrackerScreenState();
}

class _MapTrackerScreenState extends State<MapTrackerScreen> {
  static const String _mapTileUrl =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  final MapController _mapController = MapController();
  bool _isMapReady = false;

  // Initial center before GPS resolves
  LatLng _myLocation = const LatLng(37.7749, -122.4194);
  bool _hasGpsFix = false;
  bool _hasGpsError = false;
  bool _hasAnchoredFriends = false;
  bool _isTracking = true;
  String _statusMessage = 'Connecting to GPS...';

  // Breadcrumb path of user's movement
  final List<LatLng> _userTrail = [];

  // Active friends with simulated live movement
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
    _mapController.dispose();
    super.dispose();
  }

  void _applyPosition(Position pos) {
    if (!mounted) return;
    final newLatLng = LatLng(pos.latitude, pos.longitude);

    setState(() {
      _myLocation = newLatLng;
      _hasGpsFix = true;
      _hasGpsError = false;
      final speedKmH = (pos.speed * 3.6).clamp(0, 999);
      _statusMessage = 'Live • ${speedKmH.toStringAsFixed(1)} km/h';

      // Append to breadcrumb trail if moved more than 2 meters
      if (_userTrail.isEmpty ||
          DistanceUtils.getDistanceInMeters(_userTrail.last, newLatLng) > 2) {
        _userTrail.add(newLatLng);
        if (_userTrail.length > 200) _userTrail.removeAt(0);
      }

      // Anchor friends once around user's real location on first GPS fix
      if (!_hasAnchoredFriends) {
        _hasAnchoredFriends = true;
        final offsets = [
          const LatLng(0.0016, 0.0014),
          const LatLng(-0.0018, -0.0016),
          const LatLng(0.0022, -0.0019),
        ];
        for (var i = 0; i < _friends.length && i < offsets.length; i++) {
          _friends[i].trail.clear();
          _friends[i].position = LatLng(
            pos.latitude + offsets[i].latitude,
            pos.longitude + offsets[i].longitude,
          );
        }
      }
    });

    if (_isTracking && _isMapReady) {
      _safeMoveCamera(newLatLng, 16.0);
    }
  }

  String _formatError(Object error) {
    final msg = error.toString();
    return msg.startsWith('Exception: ') ? msg.substring(11) : msg;
  }

  /// Sets up real-time device GPS listening.
  Future<void> _initLocationTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;

    if (mounted) {
      setState(() {
        _hasGpsError = false;
        _statusMessage = 'Connecting to GPS...';
      });
    }

    try {
      await LocationService.checkAndRequestPermission();
      if (!mounted) return;

      setState(() => _statusMessage = 'Acquiring GPS fix...');

      final initialPos = await LocationService.getInitialPosition();
      if (!mounted) return;
      if (initialPos != null) {
        _applyPosition(initialPos);
      }

      _positionStream = LocationService.getPositionStream().listen(
        _applyPosition,
        onError: (Object error) {
          if (!mounted) return;
          setState(() {
            _hasGpsError = true;
            _statusMessage = 'GPS Error: ${_formatError(error)}';
          });
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _hasGpsError = true;
        _statusMessage = _formatError(error);
      });
    }
  }

  /// Simulates live friend movement so the user can test tracking offline.
  void _startLiveFriendSimulation() {
    _liveSimulationTimer =
        Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!mounted) return;

      setState(() {
        for (final friend in _friends) {
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
          } else if (friend.id == 'f2') {
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

  void _focusFriend(LatLng target) {
    // Pause auto-follow so the camera stays on the selected friend
    if (_isTracking) {
      setState(() => _isTracking = false);
    }
    _safeMoveCamera(target, 16.5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _myLocation,
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onMapReady: () {
                setState(() => _isMapReady = true);
                if (_hasGpsFix && _isTracking) {
                  _safeMoveCamera(_myLocation, 16.0);
                }
              },
              onPositionChanged: (_, hasGesture) {
                if (hasGesture && _isTracking) {
                  setState(() => _isTracking = false);
                }
              },
            ),
            children: [
              // Single Map API: CartoDB Voyager (OpenStreetMap, no key required)
              TileLayer(
                urlTemplate: _mapTileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                retinaMode: RetinaMode.isHighDensity(context),
                maxNativeZoom: 19,
                userAgentPackageName: 'com.example.friend_tracker',
              ),

              // Breadcrumb Polyline Layer (User trail & Friend trails)
              PolylineLayer(
                polylines: [
                  if (_userTrail.length > 1)
                    Polyline(
                      points: _userTrail,
                      color: const Color(0xFF0284C7),
                      strokeWidth: 4.0,
                    ),
                  ..._friends
                      .where((f) => f.trail.length > 1)
                      .map((f) => Polyline(
                            points: f.trail,
                            color: f.color.withAlpha(160),
                            strokeWidth: 3.0,
                          )),
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
                  ..._friends.map((friend) {
                    final dist = DistanceUtils.getDistanceInMeters(
                        _myLocation, friend.position);
                    return Marker(
                      point: friend.position,
                      width: 120,
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
                              border:
                                  Border.all(color: friend.color, width: 1.5),
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

          // Floating Top Header with GPS Status & Tracking Toggle
          MapHeader(
            hasGpsFix: _hasGpsFix,
            hasGpsError: _hasGpsError,
            statusMessage: _statusMessage,
            isTracking: _isTracking,
            onToggleTracking: _toggleTracking,
            onRetryGps: _initLocationTracking,
          ),

          // Floating Bottom Friends Tray
          FriendsTray(
            friends: _friends,
            myLocation: _myLocation,
            onSelectFriend: _focusFriend,
          ),
        ],
      ),
    );
  }
}
