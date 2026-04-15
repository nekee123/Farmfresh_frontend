class User {
  final String uid;
  final String name;
  final String phoneNumber;
  final String? location;
  final String? profilePicture;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String userType;

  User({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    this.location,
    this.profilePicture,
    this.createdAt,
    this.updatedAt,
    required this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      location: json['location'],
      profilePicture: json['profile_picture'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'])
              : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : json['updatedAt'] != null 
              ? DateTime.parse(json['updatedAt'])
              : null,
      userType: json['userType'] ?? 'consumer', // Default to consumer for login responses
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phone_number': phoneNumber,
      'location': location,
      'profile_picture': profilePicture,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'userType': userType,
    };
  }
}
