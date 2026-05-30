import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/api_service.dart';
import '../../models/api_response.dart';
import '../buyer/buyer_cart_screen.dart';
import '../buyer/checkout_screen.dart';
import '../profile/seller_profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isFavorited = false;
  bool _isLoadingFavorite = true;
  List<Map<String, dynamic>> _activeDeals = [];
  
  // Review fields
  List<Map<String, dynamic>> _productReviews = [];
  Map<String, dynamic>? _ratingSummary;
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _loadActiveDeals();
    _loadReviewData();
  }

  Future<void> _loadReviewData() async {
    final productUid = widget.product['uid'] ?? widget.product['id'];
    if (productUid == null) return;

    setState(() => _isLoadingReviews = true);

    try {
      final results = await Future.wait([
        ApiService.getProductReviews(productUid.toString()),
        ApiService.getProductRatingSummary(productUid.toString()),
      ]);

      final reviewsResp = results[0] as ApiResponse<List<Map<String, dynamic>>>;
      final summaryResp = results[1] as ApiResponse<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          if (reviewsResp.success) _productReviews = reviewsResp.data ?? [];
          if (summaryResp.success) _ratingSummary = summaryResp.data;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _editReview(Map<String, dynamic> review) async {
    double rating = (review['rating'] as num).toDouble();
    final commentController = TextEditingController(text: review['comment'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Your Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => rating = index + 1.0),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Edit your comment...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final response = await ApiService.updateReview(review['uid'], {
                  'rating': rating,
                  'comment': commentController.text,
                });
                if (response.success && mounted) {
                  Navigator.pop(context);
                  _loadReviewData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review updated!'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadActiveDeals() async {
    try {
      final response = await ApiService.getActiveDeals();
      if (response.success && response.data != null) {
        if (mounted) {
          setState(() {
            _activeDeals = response.data!;
          });
        }
      }
    } catch (e) {
      print('Error loading active deals: $e');
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final productUid = widget.product['uid'] ?? widget.product['id'];
    if (productUid == null) return;

    final response = await ApiService.isProductFavorited(productUid.toString());
    if (response.success && mounted) {
      setState(() {
        _isFavorited = response.data ?? false;
        _isLoadingFavorite = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final productUid = widget.product['uid'] ?? widget.product['id'];
    if (productUid == null) return;

    // Optimistic UI update
    setState(() => _isFavorited = !_isFavorited);

    ApiResponse<void> response;
    if (_isFavorited) {
      response = await ApiService.addToFavorites(productUid.toString());
    } else {
      response = await ApiService.removeFromFavorites(productUid.toString());
    }

    if (!response.success && mounted) {
      // Revert if failed
      setState(() => _isFavorited = !_isFavorited);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite: ${response.error}')),
      );
    }
  }

  Widget _buildProductImage(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return const Center(child: Icon(Icons.image, size: 80, color: Colors.grey));
    }

    if (imageData.startsWith('data:image')) {
      try {
        final base64String = imageData.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey)),
        );
      } catch (e) {
        return const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey));
      }
    }

    return Image.network(
      imageData,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image, size: 80, color: Colors.grey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final authService = Provider.of<AuthService>(context);
    final isOwner = authService.currentUser?.uid == product['seller_uid'];
    final stock = int.tryParse(product['quantity']?.toString() ?? '0') ?? 0;
    final isOutOfStock = stock <= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (!isOwner)
            _isLoadingFavorite
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))),
                  )
                : IconButton(
                    icon: Icon(
                      _isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorited ? Colors.red : Colors.white,
                    ),
                    onPressed: _toggleFavorite,
                  ),
        ],
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
                  child: _buildProductImage(product['image']),
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
            _buildPriceSection(product),
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
            const SizedBox(height: 32),
            
            // Reviews Section
            _buildReviewsSection(),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            if (!isOwner)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isOutOfStock ? null : () async {
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
                      disabledBackgroundColor: Colors.grey[200],
                    ),
                    child: Text(
                      isOutOfStock ? 'Sold Out' : 'Add to Cart',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isOutOfStock ? null : () async {
                      try {
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
                      disabledBackgroundColor: Colors.grey[400],
                      disabledForegroundColor: Colors.white70,
                    ),
                    child: Text(
                      isOutOfStock ? 'Out of Stock' : 'Buy Now',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (isOwner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
                    SizedBox(width: 8),
                    Text(
                      'This is your product',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
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

  Widget _buildPriceSection(Map<String, dynamic> product) {
    final originalPrice = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    final productType = product['type'];
    
    double discountedPrice = originalPrice;
    bool hasDiscount = false;
    double percentage = 0;

    // Find if there's an active deal for this product type
    final matchingDeal = _activeDeals.firstWhere(
      (deal) => deal['type'] == productType,
      orElse: () => {},
    );

    if (matchingDeal.isNotEmpty) {
      percentage = (matchingDeal['percentage'] as num?)?.toDouble() ?? 0.0;
      if (percentage > 0) {
        discountedPrice = originalPrice * (1 - percentage / 100);
        hasDiscount = true;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDiscount)
          Row(
            children: [
              Text(
                '₱${originalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[500],
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${percentage.toInt()}% OFF',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        Row(
          children: [
            Text(
              '₱${discountedPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: (int.tryParse(product['quantity']?.toString() ?? '0') ?? 0) <= 0 
                    ? Colors.red.withOpacity(0.1) 
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (int.tryParse(product['quantity']?.toString() ?? '0') ?? 0) <= 0 
                    ? 'Out of Stock' 
                    : '${product['quantity']?.toString() ?? '0'} in stock',
                style: TextStyle(
                  color: (int.tryParse(product['quantity']?.toString() ?? '0') ?? 0) <= 0 
                      ? Colors.red 
                      : const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
            ),
            if (_ratingSummary != null)
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${(_ratingSummary!['average_rating'] as num).toStringAsFixed(1)} (${_ratingSummary!['review_count']} reviews)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingReviews)
          const Center(child: CircularProgressIndicator())
        else if (_productReviews.isEmpty)
          const Center(child: Text('No reviews for this product yet', style: TextStyle(color: Colors.grey)))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _productReviews.length,
            itemBuilder: (context, index) {
              final review = _productReviews[index];
              final isMyReview = review['buyer_uid'] == currentUserId;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(review['buyer_name'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (isMyReview)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                              onPressed: () => _editReview(review),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (i) => Icon(
                          i < (review['rating'] as num) ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        )),
                      ),
                      const SizedBox(height: 8),
                      Text(review['comment'] ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(review['created_at']),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    try {
      DateTime date;
      if (dateValue is num) {
        date = DateTime.fromMillisecondsSinceEpoch((dateValue * 1000).toInt());
      } else {
        date = DateTime.parse(dateValue.toString());
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateValue.toString();
    }
  }
}
