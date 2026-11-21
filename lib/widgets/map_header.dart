import 'package:flutter/material.dart';

/// Top floating status header showing live GPS fix, map style toggle, and tracking controls.
class MapHeader extends StatelessWidget {
  final bool hasGpsFix;
  final String statusMessage;
  final bool isTracking;
  final bool isSatellite;
  final VoidCallback onToggleTracking;
  final VoidCallback onToggleMapStyle;

  const MapHeader({
    super.key,
    required this.hasGpsFix,
    required this.statusMessage,
    required this.isTracking,
    required this.isSatellite,
    required this.onToggleTracking,
    required this.onToggleMapStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xEE0F172A),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 12),
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
                  color: hasGpsFix ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                  boxShadow: [
                    BoxShadow(
                      color: (hasGpsFix ? const Color(0xFF22C55E) : const Color(0xFFF59E0B))
                          .withAlpha(120),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Live Friend Tracker',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      statusMessage,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              // Map Style Toggle (Streets vs Satellite)
              IconButton(
                tooltip: isSatellite ? 'Switch to Street Map' : 'Switch to Satellite View',
                icon: Icon(
                  isSatellite ? Icons.map_outlined : Icons.satellite_alt_outlined,
                  color: isSatellite ? const Color(0xFF38BDF8) : Colors.white70,
                  size: 20,
                ),
                onPressed: onToggleMapStyle,
              ),
              // Live Follow / GPS Centering Toggle
              IconButton(
                tooltip: isTracking ? 'Free Camera' : 'Follow My Location',
                icon: Icon(
                  isTracking ? Icons.my_location : Icons.location_searching,
                  color: isTracking ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: onToggleTracking,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
