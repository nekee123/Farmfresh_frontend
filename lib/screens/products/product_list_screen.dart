import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/api_response.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.refreshKey});
  final int? refreshKey;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  String? _error;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    // Always fetch products when screen is first loaded
    print('🔄 Initial load, fetching products...');
    _fetchProducts();
    
    // Disabled periodic refresh to prevent conflicts
    // _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
    //   if (mounted) {
    //     print('🔄 Periodic refresh triggered');
    //     _fetchProducts();
    //   }
    // });
  }

  Timer? _refreshTimer;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we need to refresh after adding a product
    final args = ModalRoute.of(context)?.settings.arguments as bool?;
    print('🔍 didChangeDependencies: args=$args');
    if (args == true) {
      print('🔄 Refresh signal received (via arguments), fetching products...');
      _fetchProducts(); // Refresh products when returning from add product screen
      
      // Increment refresh key to force rebuild
      setState(() {
        _refreshKey++;
      });
    }
  }

  @override
  void didUpdateWidget(ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Additional refresh check
    if (widget.refreshKey != oldWidget.refreshKey) {
      print('🔄 Widget refresh key changed, fetching products...');
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🌐 Fetching products from API...');
      final response = await ApiService.getProducts();
      print('📥 API Response: success=${response.success}, error=${response.error}');
      
      if (response.success && response.data != null) {
        print('📊 Products data received: ${response.data}');
        print('📊 Products count: ${response.data!.length}');
        print('📊 Response data type: ${response.data.runtimeType}');
        
        // Log each product for debugging
        for (int i = 0; i < response.data!.length; i++) {
          final product = response.data![i];
          print('📦 Product $i: ${product['name']} (UID: ${product['uid']})');
          print('📦 Product $i type: ${product.runtimeType}');
        }
        
        setState(() {
          _products = response.data!;
          _isLoading = false;
        });
        
        print('✅ Products loaded successfully! UI should update now.');
        print('🔍 After setState - _products.length: ${_products.length}');
      } else {
        print('❌ API Error: ${response.error}');
        setState(() {
          _error = response.error ?? 'Failed to load products';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('💥 Exception caught: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshProducts() async {
    print('🔄 Manual refresh triggered by user');
    setState(() {
      _refreshKey++; // Force UI rebuild
    });
    await _fetchProducts();
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    print('🗑️ Attempting to delete product: ${product['name']}');
    print('🆔 Product UID: ${product['uid']}');
    print('📦 Full product data: $product');
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      print('📤 Calling delete API with UID: ${product['uid']}');
      
      try {
        final response = await ApiService.deleteProduct(product['uid']);
        print('📥 Delete API response: success=${response.success}, error=${response.error}');

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchProducts(); // Refresh the list
        } else {
          print('❌ Delete failed with error: ${response.error}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete product: ${response.error}'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        print('🚨 Exception during delete: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _editProduct(Map<String, dynamic> product) {
    final authService = Provider.of<AuthService>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(
          sellerId: authService.currentUser?.uid ?? '',
          product: product, // Pass product data for editing
        ),
      ),
    ).then((result) {
      if (result == true) {
        _fetchProducts(); // Refresh the list after editing
      }
    });
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2E7D32),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 80,
              color: Color(0xFF2E7D32),
            ),
            const SizedBox(height: 20),
            const Text(
              'No products available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final authService = Provider.of<AuthService>(context, listen: false);
        final isOwner = product['seller_uid'] == authService.currentUser?.uid;
        
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: product['image'] != null && product['image'].isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product['image'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.image,
                      color: Colors.grey,
                    ),
            ),
            title: Text(
              product['name'] ?? 'Unknown Product',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₱${product['price']?.toString() ?? '0'}',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock: ${product['quantity']?.toString() ?? '0'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  product['type'] ?? 'Unknown',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: isOwner
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                          onPressed: () => _editProduct(product),
                          tooltip: 'Edit',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                          onPressed: () => _deleteProduct(product),
                          tooltip: 'Delete',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ),
                    ],
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Product: ${product['name']}\nPrice: ₱${product['price']}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    print('🏗️ Building ProductListScreen:');
    print('👤 Current user: ${authService.currentUser?.name} (${authService.currentUser?.userType})');
    print('📊 _products.length: ${_products.length}');
    print('⏳ _isLoading: $_isLoading');
    print('❌ _error: $_error');
    print('🔄 _refreshKey: $_refreshKey');
    
    // Debug: Show if we're in empty state
    if (_products.isEmpty && !_isLoading && _error == null) {
      print('🚨 EMPTY STATE: No products, not loading, no error');
    }
    
    return Scaffold(
      key: ValueKey(_refreshKey),
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (authService.currentUser?.userType == 'farmer')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(context, '/add_product');
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          print('🔄 Pull-to-refresh triggered');
          await _refreshProducts();
        },
        child: Column(
          children: [
            // Temporary debug button
            Container(
              margin: const EdgeInsets.all(8),
              child: ElevatedButton(
                onPressed: () {
                  print('🐛 DEBUG: Manual refresh triggered');
                  _refreshProducts();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('DEBUG: Refresh Products'),
              ),
            ),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }
}
