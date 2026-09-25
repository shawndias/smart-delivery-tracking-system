class Location {
  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  Location({required this.latitude, required this.longitude, required this.recordedAt});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }
}
