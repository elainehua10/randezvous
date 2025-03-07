class Group {
  final String id;
  final String name;
  final String? imageUrl;
  final String leaderId;
  final bool isPublic;

  Group({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.leaderId,
    required this.isPublic,
  });

  // 🔹 Convert JSON response to Group object
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'].toString(), // Ensure id is a string
      name: json['name'] ?? 'Unnamed Group',
      imageUrl: json['icon_url'], // icon_url can be null
      leaderId: json['leader_id'].toString(), // Ensure it's a string
      isPublic: json['is_public'] ?? false, // Default to false
    );
  }
}