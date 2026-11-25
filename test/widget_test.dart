import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:friend_tracker/main.dart';
import 'package:friend_tracker/models/friend_pin.dart';
import 'package:friend_tracker/utils/distance_utils.dart';
import 'package:friend_tracker/widgets/friends_tray.dart';
import 'package:friend_tracker/widgets/map_header.dart';

void main() {
  test('DistanceUtils formats meters and kilometers accurately', () {
    expect(DistanceUtils.formatDistance(0), '0 m');
    expect(DistanceUtils.formatDistance(249.6), '250 m');
    expect(DistanceUtils.formatDistance(1000), '1.0 km');
    expect(DistanceUtils.formatDistance(2450), '2.5 km');
  });

  testWidgets('MapHeader renders status, tracking toggle, and retry on error',
      (WidgetTester tester) async {
    var toggled = false;
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapHeader(
            hasGpsFix: false,
            hasGpsError: true,
            statusMessage: 'Location services are disabled.',
            isTracking: true,
            onToggleTracking: () => toggled = true,
            onRetryGps: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Live Friend Tracker'), findsOneWidget);
    expect(find.text('Location services are disabled.'), findsOneWidget);
    expect(find.byIcon(Icons.satellite_alt_outlined), findsNothing);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.tap(find.byIcon(Icons.my_location));
    expect(retried, isTrue);
    expect(toggled, isTrue);
  });

  testWidgets('FriendsTray renders friends and fires callback on tap',
      (WidgetTester tester) async {
    LatLng? selected;
    final friends = [
      FriendPin(
        id: 'f1',
        name: 'Alex',
        position: const LatLng(37.7765, -122.4182),
        color: const Color(0xFF10B981),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FriendsTray(
                friends: friends,
                myLocation: const LatLng(37.7749, -122.4194),
                onSelectFriend: (target) => selected = target,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('1 active'), findsOneWidget);

    await tester.tap(find.text('Alex'));
    expect(selected, const LatLng(37.7765, -122.4182));
  });

  testWidgets('FriendTrackerApp renders single map API and friend tray cleanly',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FriendTrackerApp());
    await tester.pump();

    expect(find.byType(TileLayer), findsOneWidget);
    expect(find.text('Live Friend Tracker'), findsOneWidget);
    expect(find.text('Friends on Map'), findsOneWidget);

    // Selecting a friend pauses auto-follow tracking
    await tester.tap(find.text('Alex').last);
    await tester.pump();
    expect(find.byIcon(Icons.location_searching), findsOneWidget);

    // Dispose MapTrackerScreen so periodic timers are cleaned up before exit
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
