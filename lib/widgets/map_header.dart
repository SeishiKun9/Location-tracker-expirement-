import 'package:flutter/material.dart';

/// Top floating status header showing live GPS fix and recenter/tracking toggle.
class MapHeader extends StatelessWidget {
  final bool hasGpsFix;
  final String statusMessage;
  final bool isTracking;
  final VoidCallback onToggleTracking;

  const MapHeader({
    super.key,
    required this.hasGpsFix,
    required this.statusMessage,
    required this.isTracking,
    required this.onToggleTracking,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                  color: hasGpsFix ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
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
                      statusMessage,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                  color: isTracking ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
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

