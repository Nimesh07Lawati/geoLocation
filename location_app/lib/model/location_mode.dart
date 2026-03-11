class LocationModel {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? altitude;
  final double? speed;
  final DateTime timestamp;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude,
    this.speed,
    required this.timestamp,
  });

  String get latStr => latitude.toStringAsFixed(6);
  String get lngStr => longitude.toStringAsFixed(6);
  String get speedKmh =>
      speed != null ? '${(speed! * 3.6).toStringAsFixed(1)} km/h' : '0.0 km/h';
  String get accuracyStr => '±${accuracy.toStringAsFixed(1)}m';

  @override
  String toString() => '$latStr, $lngStr';
}
