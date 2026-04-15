class Buyer {
  final String uid;
  final String name;
  final String phoneNumber;
  final String? location;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime updatedAt;

  Buyer({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    this.location,
    this.profilePicture,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Buyer.fromJson(Map<String, dynamic> json) {
    return Buyer(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      location: json['location'],
      profilePicture: json['profile_picture'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phone_number': phoneNumber,
      'location': location,
      'profile_picture': profilePicture,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
