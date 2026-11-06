import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FriendTrackerApp());
}

class FriendTrackerApp extends StatelessWidget {
  const FriendTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Friend Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D16),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          surface: Color(0xFF131D31),
        ),
        useMaterial3: true,
      ),
      home: const MapTrackerScreen(),
    );
  }
}

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

class MapTrackerScreen extends StatefulWidget {
  const MapTrackerScreen({super.key});

  @override
  State<MapTrackerScreen> createState() => _MapTrackerScreenState();
}

class _MapTrackerScreenState extends State<MapTrackerScreen> {
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  // Default initial coordinates before GPS fix
  LatLng _myLocation = const LatLng(37.7749, -122.4194);
  bool _hasGpsFix = false;
  bool _isTracking = true;
  String _statusMessage = 'Connecting to GPS...';

  // Connected demo friends in room
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
    _startGpsStream();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startGpsStream() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _statusMessage = 'Location services disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() => _statusMessage = 'Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _statusMessage = 'Location permission permanently denied');
        return;
      }

      if (!mounted) return;
      setState(() => _statusMessage = 'Acquiring GPS fix...');

      // Continuous live location listening
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // trigger on 1 meter movement
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position pos) {
          if (!mounted) return;

          final newLatLng = LatLng(pos.latitude, pos.longitude);

          setState(() {
            _myLocation = newLatLng;
            _hasGpsFix = true;
            final speedKmH = (pos.speed * 3.6).clamp(0, 999);
            _statusMessage = 'Live • ${speedKmH.toStringAsFixed(1)} km/h';

            // Anchor mock friends around user's real location once GPS connects
            _friends[0].position = LatLng(pos.latitude + 0.0015, pos.longitude + 0.0012);
            _friends[1].position = LatLng(pos.latitude - 0.0018, pos.longitude - 0.0014);
            _friends[2].position = LatLng(pos.latitude + 0.0020, pos.longitude - 0.0016);
          });

          // Safe camera update only when map is ready and tracking is on
          if (_isTracking && _isMapReady) {
            try {
              _mapController.move(newLatLng, 16.0);
            } catch (_) {}
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _statusMessage = 'GPS Error: $error');
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Error: $e');
    }
  }

  // Safe distance calculation using Geolocator
  double _getDistanceInMeters(LatLng p1, LatLng p2) {
    return Geolocator.distanceBetween(
      p1.latitude,
      p1.longitude,
      p2.latitude,
      p2.longitude,
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  void _safeMoveCamera(LatLng target, double zoom) {
    if (_isMapReady) {
      try {
        _mapController.move(target, zoom);
      } catch (_) {}
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
                  // My Location Marker
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
                    final dist = _getDistanceInMeters(_myLocation, friend.position);
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
                              '${friend.name} (${_formatDistance(dist)})',
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

          // Top Floating Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xEB0F172A),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66000000), blurRadius: 10),
                  ],
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hasGpsFix ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Friend Tracker',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _statusMessage,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                        color: _isTracking ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                      ),
                      onPressed: () {
                        setState(() => _isTracking = !_isTracking);
                        if (_isTracking) {
                          _safeMoveCamera(_myLocation, 16.0);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Connected Friends Tray
          Positioned(
            bottom: 24,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xEB0F172A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Friends on Map',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                      Text(
                        '${_friends.length} active',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _friends.map((f) {
                      final dist = _getDistanceInMeters(_myLocation, f.position);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _safeMoveCamera(f.position, 16.5);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: f.color.withAlpha(100)),
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: f.color,
                                  child: Text(
                                    f.name[0],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  f.name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _formatDistance(dist),
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
