import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_app/model/location_mode.dart';

class LocationProvider extends ChangeNotifier {
  LocationModel? _currentLocation;
  bool _isTracking = false;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<Position>? _positionStream;
  final List<LatLng> _routePoints = [];
  final Set<Polyline> _polylines = {};
  GoogleMapController? _mapController;

  // Getters
  LocationModel? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<LatLng> get routePoints => _routePoints;
  Set<Polyline> get polylines => _polylines;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage = 'Location services are disabled. Please enable them.';
      notifyListeners();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorMessage = 'Location permission denied.';
        notifyListeners();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _errorMessage =
          'Location permissions permanently denied. Please enable in settings.';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final hasPermission = await _checkPermissions();
    if (!hasPermission) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updateLocation(position);
    } catch (e) {
      _errorMessage = 'Failed to get location: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> startTracking() async {
    final hasPermission = await _checkPermissions();
    if (!hasPermission) return;

    _isTracking = true;
    _errorMessage = null;
    _routePoints.clear();
    _polylines.clear();
    notifyListeners();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _updateLocation(position);
            _addRoutePoint(LatLng(position.latitude, position.longitude));
            _animateCamera(LatLng(position.latitude, position.longitude));
          },
          onError: (error) {
            _errorMessage = 'Location stream error: $error';
            notifyListeners();
          },
        );
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    notifyListeners();
  }

  void _updateLocation(Position position) {
    _currentLocation = LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      timestamp: position.timestamp,
    );
    notifyListeners();
  }

  void _addRoutePoint(LatLng point) {
    _routePoints.add(point);
    _polylines.clear();
    if (_routePoints.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: List.from(_routePoints),
          color: const Color(0xFF2196F3),
          width: 4,
          patterns: [],
        ),
      );
    }
    notifyListeners();
  }

  Future<void> _animateCamera(LatLng target) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 17)),
    );
  }

  void clearRoute() {
    _routePoints.clear();
    _polylines.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
