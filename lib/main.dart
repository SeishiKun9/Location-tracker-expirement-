import 'package:flutter/material.dart';
import 'screens/map_tracker_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FriendTrackerApp());
}

/// Root application widget configuring global themes and starting screen.
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
