class LocationRequest {
  final double lat;
  final double lng;

  LocationRequest({required this.lat, required this.lng});

  Map<String, dynamic> toJson() {
    return {"lat": lat, "lng": lng};
  }
}

class LocationResponse {
  final bool success;
  final String message;

  LocationResponse({required this.success, required this.message});

  factory LocationResponse.fromJson(Map<String, dynamic> json) {
    return LocationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
