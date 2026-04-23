import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../profile/seller_profile_screen.dart';

class ConsumerOrdersScreen extends StatefulWidget {
  const ConsumerOrdersScreen({super.key});

  @override
  State<ConsumerOrdersScreen> createState() => _ConsumerOrdersScreenState();
}

class _ConsumerOrdersScreenState extends State<ConsumerOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  Map<String, String?> _productImages = {}; // Cache product images by product UID
  Map<String, Map<String, dynamic>> _orderReviews = {}; // Cache reviews by order UID
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _fetchProductImages() async {
    final uniqueProductUids = _orders
        .map((order) => order['farm_product_uid'] as String?)
        .where((uid) => uid != null)
        .toSet();

    for (final productUid in uniqueProductUids) {
      try {
        final response = await ApiService.getProduct(productUid!);
        if (response.success && response.data != null) {
          final product = response.data!;
          final image = product['image'] as String?;
          if (mounted) {
            setState(() {
              _productImages[productUid] = image;
            });
          }
        }
      } catch (e) {
        print('Error fetching product image for $productUid: $e');
      }
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final buyerId = authService.currentUser?.uid;
      
      if (buyerId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.getBuyerOrders(buyerId);
      
      if (response.success && response.data != null) {
        setState(() {
          _orders = response.data!;
          _isLoading = false;
        });
        if (_orders.isNotEmpty) {
          print('📦 Order data keys: ${_orders[0].keys.toList()}');
          print('📦 First order data: ${_orders[0]}');
          // Fetch product images for all orders
          _fetchProductImages();
          // Check for existing reviews
          _checkForReviews();
        }
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load orders';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkForReviews() async {
    for (final order in _orders) {
      final orderUid = order['uid'] as String?;
      final sellerUid = order['seller_uid'] as String?;
      
      if (orderUid != null && sellerUid != null) {
        try {
          final response = await ApiService.getSellerReviews(sellerUid);
          if (response.success && response.data != null) {
            final reviews = response.data!;
            final existingReview = reviews.firstWhere(
              (review) => review['order_uid'] == orderUid,
              orElse: () => {},
            );
            if (existingReview.isNotEmpty && existingReview is Map) {
              if (mounted) {
                setState(() {
                  _orderReviews[orderUid] = existingReview;
                });
              }
            }
          }
        } catch (e) {
          print('Error checking for review: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Color(0xFF2E7D32),
            ),
            SizedBox(height: 20),
            Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start shopping to see your orders here',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['order_status'] ?? order['status'] ?? 'Unknown';
    final productName = order['farm_product_name'] ?? 'Unknown Product';
    final quantity = order['quantity'] ?? 0;
    final totalPrice = order['total_price'] ?? 0;
    final paymentMethod = order['payment_method'] ?? 'Unknown';
    final createdAt = order['created_at'] ?? '';
    final sellerName = order['seller_name'] ?? 'Unknown';
    final productUid = order['farm_product_uid'] as String?;
    final productImage = productUid != null ? _productImages[productUid] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: productImage != null && productImage.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        productImage,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image, color: Colors.grey);
                        },
                      ),
                    )
                  : const Icon(Icons.image, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            // Order Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          productName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      _buildStatusChip(status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildOrderDetail('Seller', sellerName),
                  _buildOrderDetail('Quantity', quantity.toString()),
                  _buildOrderDetail('Total Price', '₱$totalPrice'),
                  _buildOrderDetail('Payment Method', paymentMethod),
                  const SizedBox(height: 12),
                  if (status.toLowerCase() == 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _cancelOrder(order['uid']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cancel Order'),
                      ),
                    ),
                  if (status.toLowerCase() == 'delivered')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleReviewButton(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_orderReviews.containsKey(order['uid']) ? 'View Review' : 'Write a Review'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleReviewButton(Map<String, dynamic> order) {
    final orderUid = order['uid'] as String?;
    if (orderUid != null && _orderReviews.containsKey(orderUid)) {
      // Navigate to seller profile to view reviews
      final sellerUid = order['seller_uid'];
      if (sellerUid != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SellerProfileScreen(
              sellerId: sellerUid,
              buyerId: Provider.of<AuthService>(context, listen: false).currentUser?.uid,
            ),
          ),
        );
      }
    } else {
      // Create new review
      _showReviewDialog(order);
    }
  }

  Future<void> _cancelOrder(String orderUid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService.cancelOrder(orderUid);
        if (response.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order cancelled successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadOrders(); // Refresh orders
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to cancel order: ${response.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling order: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'processing':
      case 'confirmed':
        chipColor = Colors.blue;
        break;
      case 'shipped':
        chipColor = Colors.purple;
        break;
      case 'delivered':
        chipColor = Colors.green;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildOrderDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReviewDialog(Map<String, dynamic> order, {Map<String, dynamic>? existingReview}) async {
    double rating = existingReview != null ? (existingReview['rating'] as num).toDouble() : 0.0;
    final commentController = TextEditingController(text: existingReview != null ? (existingReview['comment'] ?? '') : '');
    final bool isReadOnly = existingReview != null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isReadOnly ? 'Your Review' : 'Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rate your experience with ${order['seller_name'] ?? 'the seller'}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: isReadOnly ? null : () {
                      setState(() {
                        rating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Write your review here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                readOnly: isReadOnly,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (!isReadOnly)
              ElevatedButton(
                onPressed: () {
                  if (rating > 0) {
                    Navigator.pop(context);
                    _submitReview(order, rating, commentController.text);
                  }
                },
                child: const Text('Submit'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(Map<String, dynamic> order, double rating, String comment) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      final reviewData = {
        'order_uid': order['uid'],
        'seller_uid': order['seller_uid'],
        'buyer_uid': currentUser?.uid ?? '',
        'buyer_name': currentUser?.name ?? 'Anonymous',
        'rating': rating,
        'comment': comment,
      };
      
      final response = await ApiService.createReview(reviewData);
      if (response.success) {
        if (mounted) {
          // Add the review to the map so the button text updates
          setState(() {
            _orderReviews[order['uid']] = {
              'rating': rating,
              'comment': comment,
            };
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review submitted successfully'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit review: ${response.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(dynamic dateString) {
    try {
      DateTime date;
      if (dateString is double) {
        date = DateTime.fromMillisecondsSinceEpoch(dateString.toInt());
      } else if (dateString is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dateString);
      } else {
        date = DateTime.parse(dateString.toString());
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString.toString();
    }
  }
}
