import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:location_app/api/location_requenst_model.dart';

Future<void> sendLocation(LocationRequest requestData) async {
  const String url =
      "https://location.finnetra.com/api/Purchase/MarkAttendance"; // replace with your API endpoint

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
