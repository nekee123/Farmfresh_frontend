class Review {
  final String uid;
  final String buyerUid;
  final String buyerName;
  final String buyerProfilePicture;
  final String sellerUid;
  final String productUid;
  final String productName;
  final int rating; // 1-5 stars
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    required this.uid,
    required this.buyerUid,
    required this.buyerName,
    required this.buyerProfilePicture,
    required this.sellerUid,
    required this.productUid,
    required this.productName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      uid: json['uid'],
      buyerUid: json['buyer_uid'],
      buyerName: json['buyer_name'],
      buyerProfilePicture: json['buyer_profile_picture'],
      sellerUid: json['seller_uid'],
      productUid: json['product_uid'],
      productName: json['product_name'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'buyer_uid': buyerUid,
      'buyer_name': buyerName,
      'buyer_profile_picture': buyerProfilePicture,
      'seller_uid': sellerUid,
      'product_uid': productUid,
      'product_name': productName,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ReviewCreateRequest {
  final String orderUid;
  final String buyerUid;
  final String sellerUid;
  final String productUid;
  final int rating;
  final String comment;

  ReviewCreateRequest({
    required this.orderUid,
    required this.buyerUid,
    required this.sellerUid,
    required this.productUid,
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_uid': orderUid,
      'buyer_uid': buyerUid,
      'seller_uid': sellerUid,
      'farm_product_uid': productUid,
      'product_uid': productUid,
      'rating': rating,
      'comment': comment,
    };
  }
}
