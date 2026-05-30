import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/api_service.dart';
import '../../models/cart_item.dart';
import '../../models/cart_summary.dart';
import '../../models/api_response.dart';
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
  final TextEditingController _addressController = TextEditingController();
  List<CartItem> _cartItems = [];
  CartSummary? _cartSummary;
  List<Map<String, dynamic>> _activeDeals = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _selectedPaymentMethod;
  List<String> _availablePaymentMethods = [];

  final List<String> _barangayList = [
    'Brgy. Balimbing Proper, Panglima Sugala, Tawi-Tawi',
    'Brgy. Batu-batu (Pob.), Panglima Sugala, Tawi-Tawi',
    'Brgy. Buan, Panglima Sugala, Tawi-Tawi',
    'Brgy. Dungon, Panglima Sugala, Tawi-Tawi',
    'Brgy. Luuk Buntal, Panglima Sugala, Tawi-Tawi',
    'Brgy. Parangan, Panglima Sugala, Tawi-Tawi',
    'Brgy. Tabunan, Panglima Sugala, Tawi-Tawi',
    'Brgy. Tungbangkaw, Panglima Sugala, Tawi-Tawi',
    'Brgy. Bauno Garing, Panglima Sugala, Tawi-Tawi',
    'Brgy. Belatan Halu, Panglima Sugala, Tawi-Tawi',
    'Brgy. Karaha, Panglima Sugala, Tawi-Tawi',
    'Brgy. Kulape, Panglima Sugala, Tawi-Tawi',
    'Brgy. Liyaburan, Panglima Sugala, Tawi-Tawi',
    'Brgy. Magsaggaw, Panglima Sugala, Tawi-Tawi',
    'Brgy. Malacca, Panglima Sugala, Tawi-Tawi',
    'Brgy. Sumangday, Panglima Sugala, Tawi-Tawi',
    'Brgy. Tundon, Panglima Sugala, Tawi-Tawi',
    'Brgy. Ipil, Bongao, Tawi-Tawi',
    'Brgy. Kamagong, Bongao, Tawi-Tawi',
    'Brgy. Karungdong, Bongao, Tawi-Tawi',
    'Brgy. Lakit Lakit, Bongao, Tawi-Tawi',
    'Brgy. Lamion, Bongao, Tawi-Tawi',
    'Brgy. Lapid Lapid, Bongao, Tawi-Tawi',
    'Brgy. Lato Lato, Bongao, Tawi-Tawi',
    'Brgy. Luuk Pandan, Bongao, Tawi-Tawi',
    'Brgy. Luuk Tulay, Bongao, Tawi-Tawi',
    'Brgy. Malassa, Bongao, Tawi-Tawi',
    'Brgy. Mandulan, Bongao, Tawi-Tawi',
    'Brgy. Masantong, Bongao, Tawi-Tawi',
    'Brgy. Montay Montay, Bongao, Tawi-Tawi',
    'Brgy. Pababag, Bongao, Tawi-Tawi',
    'Brgy. Pagasinan, Bongao, Tawi-Tawi',
    'Brgy. Pahut, Bongao, Tawi-Tawi',
    'Brgy. Pakias, Bongao, Tawi-Tawi',
    'Brgy. Paniongan, Bongao, Tawi-Tawi',
    'Brgy. Pasiagan, Bongao, Tawi-Tawi',
    'Brgy. Bongao Poblacion, Bongao, Tawi-Tawi',
    'Brgy. Sanga-sanga, Bongao, Tawi-Tawi',
    'Brgy. Silubog, Bongao, Tawi-Tawi',
    'Brgy. Simandagit, Bongao, Tawi-Tawi',
    'Brgy. Sumangat, Bongao, Tawi-Tawi',
    'Brgy. Tarawakan, Bongao, Tawi-Tawi',
    'Brgy. Tongsinah, Bongao, Tawi-Tawi',
    'Brgy. Tubig Basag, Bongao, Tawi-Tawi',
    'Brgy. Ungus-ungus, Bongao, Tawi-Tawi',
    'Brgy. Lagasan, Bongao, Tawi-Tawi',
    'Brgy. Nalil, Bongao, Tawi-Tawi',
    'Brgy. Pagatpat, Bongao, Tawi-Tawi',
    'Brgy. Pag-asa, Bongao, Tawi-Tawi',
    'Brgy. Tubig Tanah, Bongao, Tawi-Tawi',
    'Brgy. Tubig-Boh, Bongao, Tawi-Tawi',
    'Brgy. Tubig-Mampallam, Bongao, Tawi-Tawi',
  ];

  @override
  void initState() {
    super.initState();
    _loadCart();
    _initializeAddress();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _initializeAddress() {
    final authService = Provider.of<AuthService>(context, listen: false);
    _addressController.text = authService.currentUser?.location ?? '';
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      _cartService.setAuthToken(authService.token ?? '');
      
      // Fetch cart items, summary, and active deals in parallel
      final results = await Future.wait([
        _cartService.getCartItems(),
        _cartService.getCartSummary(),
        ApiService.getActiveDeals(),
      ]);
      
      final cartItems = results[0] as List<CartItem>;
      final cartSummary = results[1] as CartSummary;
      final dealsResponse = results[2] as ApiResponse<List<Map<String, dynamic>>>;
      
      setState(() {
        _cartItems = cartItems;
        _cartSummary = cartSummary;
        if (dealsResponse.success) {
          _activeDeals = dealsResponse.data ?? [];
        }
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

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItem(item);
      return;
    }

    try {
      await _cartService.updateCartItem(item.uid, newQuantity);
      await _loadCart(); // Refresh cart and totals
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      await _cartService.removeFromCart(item.uid);
      await _loadCart(); // Refresh cart and totals
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
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
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a delivery address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Create orders for each cart item
      for (final item in _cartItems) {
        final product = item.product;
        if (product == null) continue;

        // Apply discount logic if applicable
        double finalItemPrice = item.priceAtTime;
        bool hasDiscount = false;
        String? dealId;
        
        final matchingDeal = _activeDeals.firstWhere(
          (deal) => deal['type'] == product['type'],
          orElse: () => {},
        );

        if (matchingDeal.isNotEmpty) {
          final percentage = (matchingDeal['percentage'] as num?)?.toDouble() ?? 0.0;
          if (percentage > 0) {
            finalItemPrice = item.priceAtTime * (1 - percentage / 100);
            hasDiscount = true;
            dealId = matchingDeal['deal_id'];
          }
        }
        
        final orderData = {
          'farm_product_uid': item.productUid,
          'quantity': item.quantity,
          'payment_method': _selectedPaymentMethod ?? 'Cash on Delivery',
          'buyer_address': _addressController.text.trim(),
          'buyer_name': authService.currentUser?.name ?? 'Unknown',
          'buyer_contact': authService.currentUser?.phoneNumber ?? '',
          'total_price': item.quantity * finalItemPrice,
          'seller_uid': product['seller_uid'] ?? product['seller_id'] ?? product['uid'] ?? '',
          if (hasDiscount) 'deal_id': dealId,
        };
        
        print('-----------------------------------------');
        print('🛒 PLACING ORDER FOR: ${product['name']}');
        print('💰 ORIGINAL PRICE: ₱${item.priceAtTime}');
        print('🏷️ DISCOUNTED PRICE: ₱${finalItemPrice}');
        print('🔢 QUANTITY: ${item.quantity}');
        print('💵 TOTAL SENT TO BACKEND: ₱${item.quantity * finalItemPrice}');
        print('🆔 DEAL ID: ${hasDiscount ? dealId : "None"}');
        print('📦 FULL DATA: $orderData');
        print('-----------------------------------------');
        
        final response = await ApiService.createOrder(orderData);
        
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

  Widget _buildProductImage(String? imageData, {double? width, double? height}) {
    if (imageData == null || imageData.isEmpty) {
      return Icon(Icons.image, color: Colors.grey, size: width != null ? width / 2 : 40);
    }

    if (imageData.startsWith('data:image')) {
      try {
        final base64String = imageData.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: Colors.grey, size: width != null ? width / 2 : 40),
        );
      } catch (e) {
        return Icon(Icons.broken_image, color: Colors.grey, size: width != null ? width / 2 : 40);
      }
    }

    return Image.network(
      imageData,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Icon(Icons.image, color: Colors.grey, size: width != null ? width / 2 : 40),
    );
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
    final productType = item.product?['type'];
    
    double discountedPrice = item.priceAtTime;
    bool hasDiscount = false;
    double percentage = 0;

    final matchingDeal = _activeDeals.firstWhere(
      (deal) => deal['type'] == productType,
      orElse: () => {},
    );

    if (matchingDeal.isNotEmpty) {
      percentage = (matchingDeal['percentage'] as num?)?.toDouble() ?? 0.0;
      if (percentage > 0) {
        discountedPrice = item.priceAtTime * (1 - percentage / 100);
        hasDiscount = true;
      }
    }
    
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
                    child: _buildProductImage(productImage, width: 60, height: 60),
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
                if (hasDiscount)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${percentage.toInt()}% OFF',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₱${item.priceAtTime.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                Text(
                  'Qty: ${item.quantity} x ₱${discountedPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                // Quantity Controls
                Row(
                  children: [
                    _buildQtyButton(
                      Icons.remove,
                      () => _updateQuantity(item, item.quantity - 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _buildQtyButton(
                      Icons.add,
                      () => _updateQuantity(item, item.quantity + 1),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _removeItem(item),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₱${(item.quantity * discountedPrice).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: _showAddressDialog,
                child: const Text('Select'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _addressController.text.isEmpty 
                ? 'No address provided' 
                : _addressController.text,
            style: TextStyle(
              color: _addressController.text.isEmpty ? Colors.red : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Delivery Barangay'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _barangayList.length,
            itemBuilder: (context, index) {
              final barangay = _barangayList[index];
              return ListTile(
                title: Text(barangay, style: const TextStyle(fontSize: 14)),
                onTap: () {
                  setState(() {
                    _addressController.text = barangay;
                  });
                  Navigator.pop(context);
                },
                selected: _addressController.text == barangay,
                selectedTileColor: const Color(0xFF2E7D32).withOpacity(0.1),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    double subtotal = _cartSummary?.totalAmount ?? 0;
    double totalDiscount = 0;

    for (final item in _cartItems) {
      final matchingDeal = _activeDeals.firstWhere(
        (deal) => deal['type'] == item.product?['type'],
        orElse: () => {},
      );

      if (matchingDeal.isNotEmpty) {
        final percentage = (matchingDeal['percentage'] as num?)?.toDouble() ?? 0.0;
        if (percentage > 0) {
          double originalItemTotal = item.quantity * item.priceAtTime;
          double discountedItemTotal = originalItemTotal * (1 - percentage / 100);
          totalDiscount += (originalItemTotal - discountedItemTotal);
        }
      }
    }

    double finalTotal = subtotal - totalDiscount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', subtotal),
          if (totalDiscount > 0)
            _buildSummaryRow(
              'Deal Discount', 
              -totalDiscount, 
              valueColor: Colors.red
            ),
          _buildSummaryRow('Delivery Fee', 0.0),
          const Divider(),
          _buildSummaryRow(
            'Total',
            finalTotal,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false, Color? valueColor}) {
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
            '${value < 0 ? '-' : ''}₱${value.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: valueColor ?? (isBold ? const Color(0xFF2E7D32) : Colors.grey[700]),
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
