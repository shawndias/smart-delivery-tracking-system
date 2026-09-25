class Timeline {
  final String status;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  Timeline({required this.status, required this.createdAt, this.latitude, this.longitude});

  factory Timeline.fromJson(Map<String, dynamic> json) {
    return Timeline(
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : null,
    );
  }
}
