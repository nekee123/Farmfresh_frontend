class FarmProduct {
  final String id;
  final String name;
  final String type;
  final double price;
  final int quantity;
  final String? image;
  final String sellerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  FarmProduct({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.quantity,
    this.image,
    required this.sellerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FarmProduct.fromJson(Map<String, dynamic> json) {
    return FarmProduct(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 0,
      image: json['image'],
      sellerId: json['seller_id'] ?? json['sellerId'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'price': price,
      'quantity': quantity,
      'image': image,
      'seller_id': sellerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ProductFilter {
  final String? sellerUid;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final bool? inStock;

  ProductFilter({
    this.sellerUid,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.inStock,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (sellerUid != null) params['seller_uid'] = sellerUid;
    if (category != null) params['category'] = category;
    if (minPrice != null) params['min_price'] = minPrice;
    if (maxPrice != null) params['max_price'] = maxPrice;
    if (inStock != null) params['in_stock'] = inStock;
    return params;
  }
}
