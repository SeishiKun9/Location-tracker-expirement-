import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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
        primaryColor: const Color(0xFF2563EB),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          surface: Color(0xFF131D31),
        ),
        useMaterial3: true,
      ),
      home: const TrackerScreen(),
    );
  }
}

class Friend {
  final String id;
  final String name;
  double latitude;
  double longitude;
  final double speed;
  final String lastUpdated;
  final Color color;

  Friend({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.lastUpdated,
    required this.color,
  });
}

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  Position? _currentPosition;
  String? _errorMessage;
  bool _isSharing = true;
  String _roomId = 'FRIEND-9021';
  final TextEditingController _roomController = TextEditingController();

  StreamSubscription<Position>? _positionStream;

  // Mock friends to demonstrate distance calculation and live updates
  final List<Friend> _friends = [
    Friend(
      id: 'f1',
      name: 'Alex',
      latitude: 0,
      longitude: 0,
      speed: 1.2,
      lastUpdated: 'Just now',
      color: const Color(0xFF4ADE80),
    ),
    Friend(
      id: 'f2',
      name: 'Sarah',
      latitude: 0,
      longitude: 0,
      speed: 0.0,
      lastUpdated: '2 min ago',
      color: const Color(0xFFF472B6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _roomController.dispose();
    super.dispose();
  }

  // Haversine formula to compute real-time distance in meters or kilometers
  String _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distanceKm = earthRadiusKm * c;

    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()} m away';
    }
    return '${distanceKm.toStringAsFixed(2)} km away';
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  Future<void> _initLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled on the phone
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = 'Location services are disabled. Please turn on GPS.';
      });
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Location permissions are denied.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage = 'Location permissions are permanently denied.';
      });
      return;
    }

    // Start live continuous location listening
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2, // notify every 2 meters moved
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        _errorMessage = null;

        // Position mock friends near the user's live coordinates for preview
        _friends[0].latitude = position.latitude + 0.0014;
        _friends[0].longitude = position.longitude + 0.0011;
        _friends[1].latitude = position.latitude - 0.0022;
        _friends[1].longitude = position.longitude - 0.0015;
      });
    });
  }

  void _toggleSharing() {
    setState(() {
      _isSharing = !_isSharing;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSharing
            ? 'Live GPS sharing resumed'
            : 'Live GPS sharing paused (Ghost Mode)',
        ),
        backgroundColor: _isSharing ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _joinRoom() {
    final code = _roomController.text.trim().toUpperCase();
    if (code.isNotEmpty) {
      setState(() {
        _roomId = code;
        _roomController.clear();
      });
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to room: $code'),
          backgroundColor: const Color(0xFF2563EB),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Friend Tracker',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isSharing ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Room: $_roomId',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ActionChip(
              backgroundColor: _isSharing ? const Color(0xFF1E293B) : const Color(0xFF334155),
              side: const BorderSide(color: Color(0xFF334155)),
              label: Text(
                _isSharing ? 'Live ON' : 'Paused',
                style: TextStyle(
                  color: _isSharing ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              onPressed: _toggleSharing,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live GPS Status Card
            _buildGpsCard(),
            const SizedBox(height: 16),

            // Room Join Card
            _buildRoomCard(),
            const SizedBox(height: 16),

            // Friends List Card
            _buildFriendsCard(),
            const SizedBox(height: 16),

            // Direct APK Notice
            _buildApkInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MY LIVE GPS STATUS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (_currentPosition != null)
            Row(
              children: [
                _buildStatBox('Latitude', '${_currentPosition!.latitude.toStringAsFixed(4)}°'),
                const SizedBox(width: 8),
                _buildStatBox('Longitude', '${_currentPosition!.longitude.toStringAsFixed(4)}°'),
                const SizedBox(width: 8),
                _buildStatBox(
                  'Speed',
                  '${(_currentPosition!.speed * 3.6).clamp(0, 999).toStringAsFixed(1)} km/h',
                ),
              ],
            )
          else if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFF87171), fontSize: 13),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Searching for GPS satellites...',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONNECT WITH FRIENDS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _roomController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter Room Code',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleToFill(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onPressed: _joinRoom,
                child: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FRIENDS IN ROOM (${_friends.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
              const Text(
                '⚡ Real-time',
                style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._friends.map((friend) {
            String distanceText = 'Acquiring GPS...';
            if (_currentPosition != null && friend.latitude != 0) {
              distanceText = _calculateDistance(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                friend.latitude,
                friend.longitude,
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: friend.color,
                    radius: 18,
                    child: Text(
                      friend.name[0],
                      style: const TextStyle(
                        color: Color(0xFF090D16),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$distanceText • ${friend.speed > 0 ? "Moving" : "Stationary"}',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          friend.lastUpdated,
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildApkInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Color(0xFF38BDF8), width: 4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📦 Standalone Flutter APK',
            style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13),
          ),
          SizedBox(height: 4),
          Text(
            'This Flutter app directly compiles into a native Android APK (app-release.apk) without needing any companion tools or Expo Go.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

