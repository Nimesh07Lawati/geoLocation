import 'dart:convert';
import 'package:http/http.dart' as http;

/// Model class for your JSON
class LocationRequest {
  final String wifiIpAddress;
  final double latitude;
  final double longitude;

  LocationRequest({
    required this.wifiIpAddress,
    required this.latitude,
    required this.longitude,
  });

  /// Convert Dart object -> JSON map
  Map<String, dynamic> toJson() {
    return {
      'wifiIpAddress': wifiIpAddress,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Factory constructor for JSON -> Dart object (optional)
  factory LocationRequest.fromJson(Map<String, dynamic> json) {
    return LocationRequest(
      wifiIpAddress: json['wifiIpAddress'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

/// Example function for POST API call
Future<void> sendLocation(LocationRequest requestData) async {
  const String url =
      "https://your-api-endpoint.com/location"; // replace with your API endpoint

  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestData.toJson()),
  );

  if (response.statusCode == 200) {
    print("Success: ${response.body}");
  } else {
    print("Failed: ${response.statusCode} - ${response.body}");
  }
}
