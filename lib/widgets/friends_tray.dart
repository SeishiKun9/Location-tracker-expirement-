import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/friend_pin.dart';
import '../utils/distance_utils.dart';

/// Bottom sliding tray showing connected friends and dynamic distances.
class FriendsTray extends StatelessWidget {
  final List<FriendPin> friends;
  final LatLng myLocation;
  final Function(LatLng target) onSelectFriend;

  const FriendsTray({
    super.key,
    required this.friends,
    required this.myLocation,
    required this.onSelectFriend,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
                  '${friends.length} active',
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
              children: friends.map((f) {
                final dist = DistanceUtils.getDistanceInMeters(myLocation, f.position);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelectFriend(f.position),
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
                              f.name.isNotEmpty ? f.name[0] : '?',
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
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            DistanceUtils.formatDistance(dist),
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
    );
  }
}
