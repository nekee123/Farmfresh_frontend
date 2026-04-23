import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getProducts();
      
      if (mounted) {
        if (response.success) {
          setState(() {
            _products = response.data ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = response.error ?? 'Failed to load products';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading products: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteProduct(String productUid, String productName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$productName"?'),
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

    if (confirmed != true) return;

    try {
      final response = await ApiService.deleteProduct(productUid);
      
      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadProducts(); // Reload the list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete product: ${response.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _products.isEmpty
                  ? const Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: ListView.builder(
                        itemCount: _products.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: product['image'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        product['image'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.image_not_supported,
                                            size: 60,
                                            color: Colors.grey,
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 30,
                                        color: Colors.grey,
                                      ),
                                    ),
                              title: Text(
                                product['name'] ?? 'Unknown Product',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Type: ${product['type'] ?? 'N/A'}'),
                                  Text('Price: \$${product['price']?.toString() ?? '0.00'}'),
                                  Text('Quantity: ${product['quantity']?.toString() ?? '0'}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteProduct(
                                  product['uid']?.toString() ?? '',
                                  product['name'] ?? 'Unknown Product',
                                ),
                                tooltip: 'Delete Product',
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadProducts,
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Refresh',
      ),
    );
  }
}
