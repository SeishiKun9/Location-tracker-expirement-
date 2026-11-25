import 'package:flutter/material.dart';

/// Top floating status header showing live GPS fix and tracking controls.
class MapHeader extends StatelessWidget {
  final bool hasGpsFix;
  final bool hasGpsError;
  final String statusMessage;
  final bool isTracking;
  final VoidCallback onToggleTracking;
  final VoidCallback? onRetryGps;

  const MapHeader({
    super.key,
    required this.hasGpsFix,
    this.hasGpsError = false,
    required this.statusMessage,
    required this.isTracking,
    required this.onToggleTracking,
    this.onRetryGps,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = hasGpsFix
        ? const Color(0xFF22C55E)
        : (hasGpsError ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));

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
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withAlpha(120),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasGpsError && onRetryGps != null)
                IconButton(
                  tooltip: 'Retry GPS',
                  icon: const Icon(
                    Icons.refresh,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                  onPressed: onRetryGps,
                ),
              IconButton(
                tooltip: isTracking ? 'Free Camera' : 'Follow My Location',
                icon: Icon(
                  isTracking ? Icons.my_location : Icons.location_searching,
                  color: isTracking
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF64748B),
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
