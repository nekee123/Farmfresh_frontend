import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../buyer/buyer_cart_screen.dart';
import '../buyer/checkout_screen.dart';
import '../profile/seller_profile_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            if (product['image'] != null && product['image'].isNotEmpty)
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.image, size: 80, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 20),
            
            // Product Name
            Text(
              product['name'] ?? 'Unknown Product',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            
            // Seller Info
            if (product['seller_name'] != null)
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sold by: ${product['seller_name']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  if (product['seller_uid'] != null)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SellerProfileScreen(
                              sellerId: product['seller_uid'],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('View Profile'),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            
            // Price
            Row(
              children: [
                Text(
                  '₱${product['price']?.toString() ?? '0'}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${product['quantity']?.toString() ?? '0'} in stock',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Product Type
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product['type'] ?? 'Unknown',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product['description'] ?? 'No description available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // Payment Methods
            const Text(
              'Payment Methods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (product['payment_methods'] != null)
                  ...(product['payment_methods'] as String).split(',').map((method) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Text(
                        method.trim(),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      final cartService = CartService();
                      cartService.setAuthToken(authService.token ?? '');
                      
                      try {
                        final buyerUid = authService.currentUser?.uid;
                        if (buyerUid == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please log in to add items to cart'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        await cartService.addToCart(
                          productUid: product['uid'] ?? '',
                          quantity: 1,
                          priceAtTime: double.parse(product['price']?.toString() ?? '0'),
                        );
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Added to cart!'),
                              backgroundColor: Colors.green,
                              action: SnackBarAction(
                                label: 'View Cart',
                                textColor: Colors.white,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const BuyerCartScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add to cart: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final authService = Provider.of<AuthService>(context, listen: false);
                        final cartService = CartService();
                        
                        // Set auth token
                        cartService.setAuthToken(authService.token ?? '');
                        
                        // Add product to cart with quantity 1
                        await cartService.addToCart(
                          productUid: product['uid'],
                          quantity: 1,
                          priceAtTime: product['price'],
                        );
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to cart'),
                              backgroundColor: const Color(0xFF2E7D32),
                            ),
                          );
                          // Navigate to checkout
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CheckoutScreen(),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add to cart: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
