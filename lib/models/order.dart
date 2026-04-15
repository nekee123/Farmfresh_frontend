class Order {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final String productName;
  final double totalPrice;
  final int quantity;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isReviewed;

  Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.productName,
    required this.totalPrice,
    required this.quantity,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.isReviewed = false,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      buyerId: json['buyer_id'] ?? '',
      sellerId: json['seller_id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      paymentMethod: json['payment_method'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isReviewed: json['is_reviewed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'product_id': productId,
      'product_name': productName,
      'total_price': totalPrice,
      'quantity': quantity,
      'payment_method': paymentMethod,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_reviewed': isReviewed,
    };
  }
}
