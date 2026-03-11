class LocationModel {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime? timestamp;
  final bool isLoading;
  final String? error;
  final String? apiMessage;
  final int apiCallCount; // ✅ count of API calls

  LocationModel({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.timestamp,
    this.isLoading = false,
    this.error,
    this.apiMessage,
    this.apiCallCount = 0,
  });

  bool get hasValidCoordinates => latitude != null && longitude != null;

  String get formattedLatitude => latitude?.toStringAsFixed(6) ?? '--';
  String get formattedLongitude => longitude?.toStringAsFixed(6) ?? '--';
  String get formattedAccuracy =>
      accuracy != null ? "${accuracy!.toStringAsFixed(2)} m" : '--';
  String get formattedTimestamp =>
      timestamp != null ? timestamp!.toLocal().toString() : '--';

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? timestamp,
    bool? isLoading,
    String? error,
    String? apiMessage,
    int? apiCallCount,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      apiMessage: apiMessage ?? this.apiMessage,
      apiCallCount: apiCallCount ?? this.apiCallCount,
    );
  }
}
