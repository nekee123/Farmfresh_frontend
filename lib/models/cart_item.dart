class CartItem {
  final String uid;
  final String productUid;
  final int quantity;
  final double priceAtTime;
  final DateTime createdAt;
  final Map<String, dynamic>? product;

  CartItem({
    required this.uid,
    required this.productUid,
    required this.quantity,
    required this.priceAtTime,
    required this.createdAt,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      uid: json['uid'] ?? '',
      productUid: json['product_uid'] ?? '',
      quantity: json['quantity'] ?? 0,
      priceAtTime: (json['price_at_time'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      product: json['product'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'product_uid': productUid,
      'quantity': quantity,
      'price_at_time': priceAtTime,
      'created_at': createdAt.toIso8601String(),
      'product': product,
    };
  }

  double get totalPrice => quantity * priceAtTime;
}
