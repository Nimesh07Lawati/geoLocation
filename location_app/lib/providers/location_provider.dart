import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_app/model/location_mode.dart';

class LocationProvider extends ChangeNotifier {
  LocationModel? _currentLocation;
  bool _isTracking = false;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<Position>? _positionStream;
  final List<LatLng> _routePoints = [];

  // Getters
  LocationModel? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<LatLng> get routePoints => List.unmodifiable(_routePoints);

  // Notifier for map centering
  LatLng? _latestLatLng;
  LatLng? get latestLatLng => _latestLatLng;

  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage =
          'Location services are disabled. Please enable them in settings.';
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
          'Location permissions permanently denied. Enable in app settings.';
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
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _applyPosition(position);
    } catch (e) {
      _errorMessage = 'Could not get location: $e';
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
    notifyListeners();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) {
            _applyPosition(position);
            _routePoints.add(LatLng(position.latitude, position.longitude));
            notifyListeners();
          },
          onError: (e) {
            _errorMessage = 'Tracking error: $e';
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

  void clearRoute() {
    _routePoints.clear();
    notifyListeners();
  }

  void _applyPosition(Position position) {
    _currentLocation = LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      timestamp: position.timestamp,
    );
    _latestLatLng = LatLng(position.latitude, position.longitude);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
