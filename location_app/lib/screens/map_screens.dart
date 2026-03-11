import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_app/widgets/location_info_panal.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerStateMixin {
  static const LatLng _defaultLocation = LatLng(27.7172, 85.3240); // Kathmandu
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Get initial location on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(LocationProvider provider) {
    if (provider.currentLocation == null) return {};
    final pos = LatLng(
      provider.currentLocation!.latitude,
      provider.currentLocation!.longitude,
    );
    return {
      Marker(
        markerId: const MarkerId('current_location'),
        position: pos,
        infoWindow: InfoWindow(
          title: 'My Location',
          snippet: provider.currentLocation.toString(),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          provider.isTracking
              ? BitmapDescriptor.hueAzure
              : BitmapDescriptor.hueRed,
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, provider, _) {
        final initialTarget = provider.currentLocation != null
            ? LatLng(
                provider.currentLocation!.latitude,
                provider.currentLocation!.longitude,
              )
            : _defaultLocation;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: Stack(
            children: [
              // Google Map
              GoogleMap(
                onMapCreated: (controller) {
                  provider.setMapController(controller);
                },
                initialCameraPosition: CameraPosition(
                  target: initialTarget,
                  zoom: 15,
                ),
                markers: _buildMarkers(provider),
                polylines: provider.polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                mapType: MapType.normal,
              ),

              // Top App Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 12,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.97),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Tracker',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            'Real-time GPS tracking',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (provider.isTracking)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                const Color(0xFF4CAF50).withOpacity(0.15),
                                const Color(0xFF4CAF50).withOpacity(0.35),
                                _pulseController.value,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF4CAF50).withOpacity(0.5),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Color(0xFF4CAF50),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Error message
              if (provider.errorMessage != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 70,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[400],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.errorMessage!,
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom Panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Location Info Panel
                    const LocationInfoPanel(),

                    // Control Buttons
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 12,
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                      ),
                      child: Row(
                        children: [
                          // Get Location button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: provider.isLoading
                                  ? null
                                  : () => provider.getCurrentLocation(),
                              icon: provider.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.my_location, size: 18),
                              label: const Text('My Location'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A1A2E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Track / Stop button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (provider.isTracking) {
                                  provider.stopTracking();
                                } else {
                                  provider.startTracking();
                                }
                              },
                              icon: Icon(
                                provider.isTracking
                                    ? Icons.stop_circle
                                    : Icons.play_circle,
                                size: 18,
                              ),
                              label: Text(
                                provider.isTracking ? 'Stop' : 'Track Me',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: provider.isTracking
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF2196F3),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),

                          if (provider.routePoints.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            // Clear route button
                            ElevatedButton(
                              onPressed: provider.clearRoute,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                foregroundColor: Colors.grey[700],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Icon(Icons.delete_outline, size: 18),
                            ),
                          ],
                        ],
                      ),
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

mixin TickerStateMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {
  final Set<Ticker> _tickers = {};

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = Ticker(onTick);
    _tickers.add(ticker);
    return ticker;
  }

  @override
  void dispose() {
    for (final ticker in _tickers) {
      ticker.dispose();
    }
    super.dispose();
  }
}
