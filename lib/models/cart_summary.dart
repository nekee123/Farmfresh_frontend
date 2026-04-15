class CartSummary {
  final int totalItems;
  final double totalAmount;
  final int itemsCount;

  CartSummary({
    required this.totalItems,
    required this.totalAmount,
    required this.itemsCount,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      totalItems: json['total_items'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      itemsCount: json['items_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_items': totalItems,
      'total_amount': totalAmount,
      'items_count': itemsCount,
    };
  }
}
