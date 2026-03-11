import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:location_app/api/location_requenst_model.dart';

class LocationService {
  static const String _baseUrl =
      "https://locationtrack.netraverselabs.com/api/MapLocation/update";

  Future<LocationResponse> updateLocation(LocationRequest request) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      return LocationResponse.fromJson(jsonBody);
    } else {
      throw Exception("Failed to update location: ${response.statusCode}");
    }
  }
}
