class Seller {
  final String uid;
  final String name;
  final String location;
  final String phoneNumber;
  final String? profilePicture;

  Seller({
    required this.uid,
    required this.name,
    required this.location,
    required this.phoneNumber,
    this.profilePicture,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      uid: json['uid'],
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      profilePicture: json['profile_picture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'location': location,
      'phone_number': phoneNumber,
      'profile_picture': profilePicture,
    };
  }
}
