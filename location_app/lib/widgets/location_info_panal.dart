import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import 'info_card.dart';

class LocationInfoPanel extends StatelessWidget {
  const LocationInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, provider, _) {
        final loc = provider.currentLocation;

        if (loc == null) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.location_off, color: Colors.grey[400], size: 24),
                const SizedBox(width: 12),
                Text(
                  'No location data yet',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: provider.isTracking
                          ? const Color(0xFF4CAF50)
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.isTracking ? 'LIVE TRACKING' : 'LAST KNOWN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: provider.isTracking
                          ? const Color(0xFF4CAF50)
                          : Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: '${loc.latitude}, ${loc.longitude}',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coordinates copied!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 14, color: Colors.blue[400]),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.8,
                children: [
                  InfoCard(
                    label: 'LATITUDE',
                    value: loc.latitude.toStringAsFixed(6),
                    icon: Icons.north,
                    color: const Color(0xFF2196F3),
                  ),
                  InfoCard(
                    label: 'LONGITUDE',
                    value: loc.longitude.toStringAsFixed(6),
                    icon: Icons.east,
                    color: const Color(0xFF9C27B0),
                  ),
                  InfoCard(
                    label: 'ACCURACY',
                    value: '±${loc.accuracy.toStringAsFixed(1)}m',
                    icon: Icons.gps_fixed,
                    color: const Color(0xFF4CAF50),
                  ),
                  InfoCard(
                    label: 'SPEED',
                    value: loc.speed != null
                        ? '${(loc.speed! * 3.6).toStringAsFixed(1)} km/h'
                        : 'N/A',
                    icon: Icons.speed,
                    color: const Color(0xFFFF9800),
                  ),
                ],
              ),
              if (provider.isTracking && provider.routePoints.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.route,
                        color: Color(0xFF2196F3),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${provider.routePoints.length} points recorded',
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
