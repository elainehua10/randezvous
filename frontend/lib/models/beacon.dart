class Beacon {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime startedAt;

  Beacon({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.startedAt,
  });

  factory Beacon.fromJson(Map<String, dynamic> json) {
    return Beacon(
      id: json['id'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      startedAt: DateTime.parse(json['started_at']),
    );
  }
}