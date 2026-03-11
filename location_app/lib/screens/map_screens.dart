import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  static const _defaultCenter = LatLng(27.7172, 85.3240); // Kathmandu

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _animateTo(LatLng target) {
    final camera = _mapController.camera;
    final tween = CameraFit.coordinates(
      coordinates: [target],
      padding: const EdgeInsets.all(80),
    );
    _mapController.move(target, camera.zoom < 15 ? 16 : camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, provider, _) {
        // Auto-pan when tracking
        if (provider.isTracking && provider.latestLatLng != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(provider.latestLatLng!, 17);
          });
        }

        final center = provider.latestLatLng ?? _defaultCenter;

        return Scaffold(
          backgroundColor: const Color(0xFF0D1117),
          body: Stack(
            children: [
              // ── MAP ──────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  // OpenStreetMap tiles - 100% FREE
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.location_app',
                    maxZoom: 19,
                  ),

                  // Route polyline
                  if (provider.routePoints.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: provider.routePoints,
                          strokeWidth: 4.5,
                          color: const Color(0xFF00D4FF),
                          borderStrokeWidth: 1.5,
                          borderColor: const Color(0xFF0099BB).withOpacity(0.5),
                        ),
                      ],
                    ),

                  // Location marker
                  if (provider.currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            provider.currentLocation!.latitude,
                            provider.currentLocation!.longitude,
                          ),
                          width: 60,
                          height: 60,
                          child: _LocationMarker(
                            isTracking: provider.isTracking,
                            pulseController: _pulseController,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // ── TOP BAR ──────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopBar(
                  isTracking: provider.isTracking,
                  pulseController: _pulseController,
                ),
              ),

              // ── ERROR BANNER ──────────────────────────────────────
              if (provider.errorMessage != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 72,
                  left: 16,
                  right: 16,
                  child: _ErrorBanner(message: provider.errorMessage!),
                ),

              // ── ZOOM CONTROLS ─────────────────────────────────────
              Positioned(
                right: 16,
                bottom: 300,
                child: _ZoomControls(mapController: _mapController),
              ),

              // ── CENTER BUTTON ─────────────────────────────────────
              if (provider.currentLocation != null)
                Positioned(
                  right: 16,
                  bottom: 180,
                  child: _CircleButton(
                    icon: Icons.my_location,
                    color: const Color(0xFF00D4FF),
                    onTap: () => _animateTo(provider.latestLatLng!),
                  ),
                ),

              // ── BOTTOM PANEL ──────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BottomPanel(provider: provider),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Location Marker Widget
// ─────────────────────────────────────────────────────────────────────────────
class _LocationMarker extends StatelessWidget {
  final bool isTracking;
  final AnimationController pulseController;

  const _LocationMarker({
    required this.isTracking,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final color = isTracking
        ? const Color(0xFF00D4FF)
        : const Color(0xFFFF6B6B);

    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        final scale = isTracking ? (1.0 + pulseController.value * 0.3) : 1.0;
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              if (isTracking)
                Container(
                  width: 50 * scale,
                  height: 50 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(
                      0.15 * (1 - pulseController.value),
                    ),
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                ),
              // Inner dot
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isTracking;
  final AnimationController pulseController;

  const _TopBar({required this.isTracking, required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 14,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0D1117).withOpacity(0.95),
            const Color(0xFF0D1117).withOpacity(0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00D4FF).withOpacity(0.3),
              ),
            ),
            child: const Icon(
              Icons.satellite_alt,
              color: Color(0xFF00D4FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOCATION TRACKER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isTracking)
            AnimatedBuilder(
              animation: pulseController,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFF00D4FF).withOpacity(0.1),
                    const Color(0xFF00D4FF).withOpacity(0.25),
                    pulseController.value,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00D4FF).withOpacity(0.5),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      size: 8,
                      color: Color(0xFF00D4FF),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFF00D4FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Panel
// ─────────────────────────────────────────────────────────────────────────────
class _BottomPanel extends StatelessWidget {
  final LocationProvider provider;

  const _BottomPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    final loc = provider.currentLocation;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: const Color(0xFF30363D)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF30363D),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: loc == null
                ? _EmptyState(isLoading: provider.isLoading)
                : Column(
                    children: [
                      // Coordinates row
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00D4FF).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_pin,
                              color: Color(0xFF00D4FF),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'COORDINATES',
                                    style: TextStyle(
                                      color: Color(0xFF8B949E),
                                      fontSize: 10,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    loc.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: loc.toString()),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📋 Coordinates copied!'),
                                    duration: Duration(seconds: 2),
                                    backgroundColor: Color(0xFF161B22),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00D4FF,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.copy,
                                  color: Color(0xFF00D4FF),
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Stats grid
                      Row(
                        children: [
                          _StatTile(
                            label: 'SPEED',
                            value: loc.speedKmh,
                            icon: Icons.speed,
                            color: const Color(0xFFFF9800),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 14),

          // Buttons
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 14,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: provider.isTracking ? 'Stop Tracking' : 'Track Me',
                    icon: provider.isTracking
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outlined,
                    color: provider.isTracking
                        ? const Color(0xFFDA3633)
                        : const Color(0xFF1F6FEB),
                    onTap: () {
                      if (provider.isTracking) {
                        provider.stopTracking();
                      } else {
                        provider.startTracking();
                      }
                    },
                  ),
                ),
                if (provider.routePoints.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  _CircleButton(
                    icon: Icons.delete_outline,
                    color: const Color(0xFF8B949E),
                    onTap: provider.clearRoute,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 9,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({
    required this.label,
    required this.color,
    this.icon,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else if (icon != null)
              Icon(icon, color: color, size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  final MapController mapController;

  const _ZoomControls({required this.mapController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CircleButton(
          icon: Icons.add,
          color: Colors.white70,
          onTap: () => mapController.move(
            mapController.camera.center,
            mapController.camera.zoom + 1,
          ),
        ),
        const SizedBox(height: 8),
        _CircleButton(
          icon: Icons.remove,
          color: Colors.white70,
          onTap: () => mapController.move(
            mapController.camera.center,
            mapController.camera.zoom - 1,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3D1F1F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDA3633).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isLoading;

  const _EmptyState({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00D4FF),
              ),
            )
          else
            const Icon(
              Icons.location_searching,
              color: Color(0xFF8B949E),
              size: 18,
            ),
          const SizedBox(width: 10),
          Text(
            isLoading ? 'Getting your location...' : 'Tap "Track Me" to start',
            style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
