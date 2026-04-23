import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/api_service.dart';
import '../../models/cart_item.dart';
import '../../models/cart_summary.dart';
import '../orders/consumer_orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  List<CartItem> _cartItems = [];
  CartSummary? _cartSummary;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _selectedPaymentMethod;
  List<String> _availablePaymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      _cartService.setAuthToken(authService.token ?? '');
      
      final cartItems = await _cartService.getCartItems();
      final cartSummary = await _cartService.getCartSummary();
      
      setState(() {
        _cartItems = cartItems;
        _cartSummary = cartSummary;
        _isLoading = false;
      });
      
      _extractPaymentMethods();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cart: $e')),
        );
      }
    }
  }

  String _formatPaymentMethod(String method) {
    // Convert database format to API/user-friendly format
    const mapping = {
      'CASH_ON_DELIVERY': 'Cash on Delivery',
      'MEET_UP_CASH_ON_PICKUP': 'Meet Up / Cash on Pick-up',
    };
    return mapping[method.trim()] ?? method;
  }

  void _extractPaymentMethods() {
    // Get unique payment methods from all cart items
    final Set<String> methods = {};
    for (final item in _cartItems) {
      final product = item.product;
      if (product != null && product['payment_methods'] != null) {
        final paymentMethods = product['payment_methods'] as String;
        final methodList = paymentMethods.split(',').map((m) => m.trim()).toList();
        // Convert database format to API format and store
        for (final method in methodList) {
          methods.add(_formatPaymentMethod(method));
        }
      }
    }
    _availablePaymentMethods = methods.toList();
    
    // Auto-select the first payment method if available
    if (_availablePaymentMethods.isNotEmpty) {
      _selectedPaymentMethod = _availablePaymentMethods.first;
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Create orders for each cart item
      for (final item in _cartItems) {
        final product = item.product;
        if (product == null) continue;
        
        print('🛒 Product data keys: ${product.keys.toList()}');
        print('🛒 Full product data: $product');
        
        final orderData = {
          'buyer_name': authService.currentUser?.name ?? 'Unknown',
          'buyer_contact': authService.currentUser?.phoneNumber ?? '',
          'farm_product_uid': item.productUid,
          'farm_product_name': product['name'] ?? 'Unknown',
          'seller_uid': product['seller_uid'] ?? product['seller_id'] ?? product['uid'] ?? '',
          'seller_name': product['seller_name'] ?? product['seller'] ?? 'Unknown',
          'seller_contact': '',
          'quantity': item.quantity,
          'total_price': item.quantity * item.priceAtTime,
          'payment_method': _selectedPaymentMethod ?? 'Cash on Delivery',
        };
        
        print('🛒 Creating order with payment method: "$_selectedPaymentMethod"');
        print('🛒 Product payment methods: ${product['payment_methods']}');
        print('🛒 Available methods: $_availablePaymentMethods');
        print('🛒 Order data: $orderData');
        
        final response = await ApiService.createOrder(orderData);
        
        print('🛒 Order response - success: ${response.success}, error: ${response.error}, data: ${response.data}');
        
        if (!response.success) {
          if (mounted) {
            final errorMessage = response.error ?? 'Unknown error (backend returned success=false without error message)';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to place order: $errorMessage'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }
      }
      
      // Clear the cart after successful orders
      await _cartService.clearCart();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ConsumerOrdersScreen()),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCheckoutContent(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 16),
                ..._cartItems.map((item) => _buildOrderItem(item)),
                const SizedBox(height: 24),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodSelector(),
                const SizedBox(height: 24),
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDeliveryAddress(),
                const SizedBox(height: 24),
                _buildOrderSummary(),
              ],
            ),
          ),
        ),
        _buildPlaceOrderButton(),
      ],
    );
  }

  Widget _buildOrderItem(CartItem item) {
    final productName = item.product?['name'] ?? 'Unknown Product';
    final productImage = item.product?['image'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: productImage != null && productImage.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      productImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image, color: Colors.grey);
                      },
                    ),
                  )
                : const Icon(Icons.image, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity} x ₱${item.priceAtTime.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₱${(item.quantity * item.priceAtTime).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    if (_availablePaymentMethods.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Payment Methods',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          ..._availablePaymentMethods.asMap().entries.map((entry) {
            final index = entry.key;
            final method = entry.value;
            final isSelected = _selectedPaymentMethod == method;
            final displayMethod = _formatPaymentMethod(method);
            
            IconData icon;
            if (method.contains('MEET_UP')) {
              icon = Icons.store;
            } else if (method.contains('DELIVERY')) {
              icon = Icons.delivery_dining;
            } else {
              icon = Icons.payment;
            }
            
            return Padding(
              padding: EdgeInsets.only(bottom: index < _availablePaymentMethods.length - 1 ? 8 : 0),
              child: _buildPaymentOption(displayMethod, icon, isSelected, method),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, bool isSelected, String method) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF2E7D32) : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[700],
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Home Address',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '123 Main Street, City, Province',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address editing coming soon!')),
              );
            },
            child: const Text('Edit Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', _cartSummary?.totalAmount ?? 0),
          _buildSummaryRow('Delivery Fee', 0.0),
          const Divider(),
          _buildSummaryRow(
            'Total',
            _cartSummary?.totalAmount ?? 0,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            '₱${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: isBold ? const Color(0xFF2E7D32) : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Place Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
