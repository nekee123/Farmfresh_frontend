import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_item.dart';
import '../models/cart_summary.dart';

class CartService {
  static const String baseUrl = 'http://localhost:8000';
  static const Duration timeout = Duration(seconds: 30);
  String? _token;

  void setAuthToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<CartSummary> getCartSummary() async {
    print('🛒 Getting cart summary');
    final response = await http.get(
      Uri.parse('$baseUrl/api/cart/summary'),
      headers: _headers,
    ).timeout(timeout);
    print('📥 Cart summary response: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      return CartSummary.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get cart summary: ${response.statusCode}');
    }
  }

  Future<List<CartItem>> getCartItems() async {
    print('🛒 Getting cart items');
    final response = await http.get(
      Uri.parse('$baseUrl/api/cart/'),
      headers: _headers,
    ).timeout(timeout);
    print('📥 Cart items response: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['items'] as List;
      return items.map((item) => CartItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to get cart items: ${response.statusCode}');
    }
  }

  Future<CartItem> addToCart({
    required String productUid,
    required int quantity,
    required double priceAtTime,
  }) async {
    print('🛒 Adding to cart: product=$productUid, qty=$quantity, price=$priceAtTime');
    print('🌐 POST URL: $baseUrl/api/cart/items');
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/cart/items'),
      headers: _headers,
      body: jsonEncode({
        'product_uid': productUid,
        'quantity': quantity,
        'price_at_time': priceAtTime,
      }),
    ).timeout(timeout);
    
    print('📥 Add to cart response: ${response.statusCode}');
    print('📥 Response body: ${response.body}');
    
    if (response.statusCode == 201) {
      return CartItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add to cart: ${response.statusCode} - ${response.body}');
    }
  }

  Future<CartItem> updateCartItem(String itemUid, int quantity) async {
    print('🛒 Updating cart item: $itemUid to qty=$quantity');
    final response = await http.put(
      Uri.parse('$baseUrl/api/cart/items/$itemUid'),
      headers: _headers,
      body: jsonEncode({'quantity': quantity}),
    ).timeout(timeout);
    print('📥 Update response: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      return CartItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update cart item: ${response.statusCode}');
    }
  }

  Future<void> removeFromCart(String itemUid) async {
    print('🛒 Removing cart item: $itemUid');
    final response = await http.delete(
      Uri.parse('$baseUrl/api/cart/items/$itemUid'),
      headers: _headers,
    ).timeout(timeout);
    print('📥 Remove response: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to remove item: ${response.statusCode}');
    }
  }

  Future<void> clearCart() async {
    print('🛒 Clearing cart');
    final response = await http.delete(
      Uri.parse('$baseUrl/api/cart/'),
      headers: _headers,
    ).timeout(timeout);
    print('📥 Clear cart response: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to clear cart: ${response.statusCode}');
    }
  }
}
