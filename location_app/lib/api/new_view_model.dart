import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationViewModel extends ChangeNotifier {
  double? latitude;
  double? longitude;
  String? wifiIpAddress;
  String apiStatus = "Idle";
  String? errorMessage;

  StreamSubscription<Position>? _positionStream;

  LocationViewModel() {
    _init();
  }

  Future<void> _init() async {
    await _requestPermission();
    _startLocationStream();
    _getWifiIpAddress();
  }

  /// Request location permission
  Future<void> _requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      errorMessage = "Location services are disabled.";
      notifyListeners();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        errorMessage = "Location permission denied.";
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      errorMessage =
          "Location permissions are permanently denied. Cannot request.";
      notifyListeners();
    }
  }

  /// Start listening to location updates
  void _startLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // update every 10 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            latitude = position.latitude;
            longitude = position.longitude;
            notifyListeners();

            _sendLocationToApi();
          },
        );
  }

  /// Get Wi-Fi IP Address (prefer local LAN IP, fallback to public IP)
  Future<void> _getWifiIpAddress() async {
    try {
      String? localIp;
      String? publicIp;

      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.isLoopback &&
              !addr.address.startsWith("127")) {
            // Check if it's a private (local) IP
            if (addr.address.startsWith("192.168.") ||
                addr.address.startsWith("10.") ||
                addr.address.startsWith("172.")) {
              localIp = addr.address;
            } else {
              publicIp = addr.address;
            }
          }
        }
      }

      wifiIpAddress = localIp ?? publicIp ?? "Unavailable";
      notifyListeners();

      if (wifiIpAddress != "Unavailable") {
        _sendLocationToApi(); // send once IP is available
      }
    } catch (e) {
      wifiIpAddress = "Unavailable";
      errorMessage = "Could not fetch Wi-Fi IP: $e";
      notifyListeners();
    }
  }

  /// Send location + IP to API
  Future<void> _sendLocationToApi() async {
    if (latitude == null || longitude == null || wifiIpAddress == null) return;

    const String url =
        "https://location.finnetra.com/api/Purchase/MarkAttendance"; // replace with your API endpoint

    try {
      apiStatus = "Sending...";
      errorMessage = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "wifiIpAddress": wifiIpAddress,
          "latitude": latitude,
          "longitude": longitude,
        }),
      );

      if (response.statusCode == 200) {
        apiStatus = "Success ✅";
      } else {
        apiStatus = "Failed ❌";
        errorMessage =
            "Error ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown'}";
      }
    } catch (e) {
      apiStatus = "Failed ❌";
      errorMessage = "Exception: $e";
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
