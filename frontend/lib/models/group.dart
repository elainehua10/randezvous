class Group {
  final String id;
  final String name;
  final String leaderId;
  final String? imageUrl;
  final bool isPublic;

  Group({required this.id, required this.name, required this.leaderId, this.imageUrl, this.isPublic = false});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['first'],
      leaderId: json['leaderId'],
    );
  }
}
