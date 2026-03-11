import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_app/view/view_model/main_model.dart';
import 'package:http/http.dart' as http;

class LocationViewModel extends ChangeNotifier {
  LocationModel _locationData = LocationModel(isLoading: true);
  StreamSubscription<Position>? _positionStream;
  Timer? _updateTimer;
  bool _isTrackingStarted = false;

  LocationModel get locationData => _locationData;
  bool get isTracking => _positionStream != null;

  LocationViewModel() {
    startLocationTracking();
  }

  Future<void> startLocationTracking() async {
    if (_isTrackingStarted) return;

    _updateLocationData(_locationData.copyWith(isLoading: true, error: null));

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _updateLocationData(
          _locationData.copyWith(
            isLoading: false,
            error: 'Location services are disabled',
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _updateLocationData(
            _locationData.copyWith(
              isLoading: false,
              error: 'Location permissions denied',
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _updateLocationData(
          _locationData.copyWith(
            isLoading: false,
            error: 'Location permissions permanently denied',
          ),
        );
        return;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(_onPositionUpdate, onError: _onLocationError);

      _isTrackingStarted = true;

      _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_locationData.hasValidCoordinates) {
          notifyListeners();
        }
      });
    } catch (e) {
      _updateLocationData(
        _locationData.copyWith(
          isLoading: false,
          error: 'Failed to start location tracking: $e',
        ),
      );
    }
  }

  void _onPositionUpdate(Position position) {
    _updateLocationData(
      _locationData.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
        isLoading: false,
      ),
    );
    sendLocationToApi();
  }

  void _onLocationError(error) {
    _updateLocationData(
      _locationData.copyWith(isLoading: false, error: 'Location error: $error'),
    );
  }

  void _updateLocationData(LocationModel newData) {
    _locationData = newData;
    notifyListeners();
  }

  void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _updateTimer?.cancel();
    _updateTimer = null;
    notifyListeners();
  }

  void restartLocationTracking() {
    stopLocationTracking();
    _isTrackingStarted = false;
    startLocationTracking();
  }

  Future<void> sendLocationToApi() async {
    if (!_locationData.hasValidCoordinates) return;

    final url = Uri.parse(
      'https://location.finnetra.com/api/Purchase/MarkAttendance',
    );

    final body = jsonEncode({
      'lat': _locationData.latitude,
      'lng': _locationData.longitude,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final message = jsonResponse['message'] ?? 'No response';

        _updateLocationData(
          _locationData.copyWith(
            apiMessage: message,
            apiCallCount: _locationData.apiCallCount + 1,
          ),
        );

        if (kDebugMode) {
          print("✅ API Response: $jsonResponse");
        }
      } else {
        _updateLocationData(
          _locationData.copyWith(
            apiMessage: 'Failed: ${response.statusCode}',
            apiCallCount: _locationData.apiCallCount + 1,
          ),
        );
      }
    } catch (e) {
      _updateLocationData(
        _locationData.copyWith(
          apiMessage: 'Error: $e',
          apiCallCount: _locationData.apiCallCount + 1,
        ),
      );
    }
  }

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}
