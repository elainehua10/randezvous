class User {
  final String id;
  final String name;
  final String username;
  final String? avatarUrl;
  final double? longitude;
  final double? latitude;

  User({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    this.longitude,
    this.latitude,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] as String,
      name: "${json['first_name'] as String}  ${json['last_name'] as String}",
      username: json['username'] as String,
      avatarUrl: json['profile_picture'] as String?,
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
    );
  }
}
