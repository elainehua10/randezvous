class Group {
  final String? id;
  final String? name;
  final String? leaderId;
  final String? imageUrl;
  final bool isPublic;
  final bool isUserLeader;
  final String? iconUrl;
  int? beaconFrequency;

  Group({
    this.id, 
    this.name, 
    this.leaderId, 
    this.isUserLeader = false,
    this.imageUrl, 
    this.isPublic = false,
    this.iconUrl,
    this.beaconFrequency,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    print("Parsing Group JSON: $json"); // Debugging print

    return Group(
      id: json['id'].toString(), // Ensure it's always a String
      name: json['name'] ?? 'Unnamed Group', // Fix the key
      leaderId: json['leader_id'] ?? 'Unknown Leader', // Fix key and add fallback
      isUserLeader: json['isUserLeader'] ?? false, // Fix key and add fallback
      isPublic: json['is_public'] == true, // Ensure it’s always a boolean
      iconUrl: json['icon_url'] as String?, // Allow it to be null
      beaconFrequency: json['beacon_frequency'] as int?, // Allow it to be null
    );
  }
}
