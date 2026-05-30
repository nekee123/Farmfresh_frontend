import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/seller.dart';
import '../../models/seller_rating.dart';
import '../../models/review.dart';
import '../products/product_list_screen.dart';
import '../products/product_detail_screen.dart';
import '../orders/consumer_orders_screen.dart';
import '../chat/chat_screen.dart';
import '../../widgets/hamburger_menu.dart';
import '../../widgets/custom_button.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final String? buyerId;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    this.buyerId,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

ImageProvider? _imageProviderFromString(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('data:image')) {
    final bytes = base64Decode(url.split(',').last);
    return MemoryImage(bytes);
  }
  if (url.startsWith('http')) return NetworkImage(url);
  // Backend may store raw base64 without the data: prefix
  final cleaned = url.trim();
  final base64Like = cleaned.length > 50 && RegExp(r'^[A-Za-z0-9+/=\s]+$').hasMatch(cleaned);
  if (base64Like) {
    try {
      return MemoryImage(base64Decode(cleaned));
    } catch (_) {
      // Ignore decode errors and fall through
    }
  }
  return null;
}

Widget _buildImageWidget(String? imageData, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
  if (imageData == null || imageData.isEmpty) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Icon(Icons.image, color: Colors.grey[600]),
    );
  }

  if (imageData.startsWith('data:image')) {
    try {
      final base64String = imageData.split(',').last;
      return Image.memory(
        base64Decode(base64String),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Icon(Icons.broken_image, color: Colors.grey[600]),
        ),
      );
    } catch (e) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Icon(Icons.broken_image, color: Colors.grey[600]),
      );
    }
  }

  return Image.network(
    imageData,
    fit: fit,
    width: width,
    height: height,
    errorBuilder: (context, error, stackTrace) => Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Icon(Icons.broken_image, color: Colors.grey[600]),
    ),
  );
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  Seller? _seller;
  SellerRating? _sellerRating;
  List<Review> _reviews = [];
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 Loading seller data for sellerId: ${widget.sellerId}');
      
      // Load seller rating
      final ratingResponse = await ApiService.getSellerRating(widget.sellerId);
      print('📊 Rating response success: ${ratingResponse.success}, data: ${ratingResponse.data}');

      // Load seller reviews
      final reviewsResponse = await ApiService.getSellerReviews(widget.sellerId);
      print('📝 Reviews response success: ${reviewsResponse.success}');
      print('📝 Reviews response data: ${reviewsResponse.data}');
      print('📝 Reviews response error: ${reviewsResponse.error}');

      // Load all products
      final productsResponse = await ApiService.getProducts();
      print('📦 Products response success: ${productsResponse.success}');

      if (mounted) {
        setState(() {
          // Extract seller info from raw product data
          final sellerProductData = productsResponse.success && productsResponse.data != null
              ? productsResponse.data!.firstWhere(
                  (product) => product['seller_uid'] == widget.sellerId,
                  orElse: () => {},
                )
              : {};
          
          final sellerName = sellerProductData['seller_name'] ?? 'Seller';
          final sellerLocation = sellerProductData['seller_location'] ?? '';
          final sellerPhone = sellerProductData['seller_contact'] ?? '';
          final sellerProfilePicture = sellerProductData['seller_profile_picture'] ?? '';
          
          _seller = Seller(
            uid: widget.sellerId,
            name: sellerName,
            location: sellerLocation,
            phoneNumber: sellerPhone,
            profilePicture: sellerProfilePicture,
          );
          print('📝 Parsing reviews...');
          _reviews = reviewsResponse.success && reviewsResponse.data != null
              ? reviewsResponse.data!.map((item) {
                  print('📝 Review item: $item');
                  return Review.fromJson(item);
                }).toList()
              : [];
          print('📝 Final reviews count: ${_reviews.length}');

          // Calculate actual average rating and review count from fetched reviews
          final actualReviewCount = _reviews.length;
          final actualAverageRating = actualReviewCount > 0
              ? _reviews.map((r) => r.rating).reduce((a, b) => a + b) / actualReviewCount
              : 0.0;

          // Count ratings by star level
          final fiveStarCount = _reviews.where((r) => r.rating == 5).length;
          final fourStarCount = _reviews.where((r) => r.rating == 4).length;
          final threeStarCount = _reviews.where((r) => r.rating == 3).length;
          final twoStarCount = _reviews.where((r) => r.rating == 2).length;
          final oneStarCount = _reviews.where((r) => r.rating == 1).length;

          print('📊 Calculated average rating: $actualAverageRating');
          print('📊 Total reviews: $actualReviewCount');
          print(' Rating breakdown: 5=$fiveStarCount, 4=$fourStarCount, 3=$threeStarCount, 2=$twoStarCount, 1=$oneStarCount');

          _sellerRating = SellerRating(
            averageRating: actualAverageRating,
            totalReviews: actualReviewCount,
            fiveStar: fiveStarCount,
            fourStar: fourStarCount,
            threeStar: threeStarCount,
            twoStar: twoStarCount,
            oneStar: oneStarCount,
          );
          
          _products = productsResponse.success && productsResponse.data != null
              ? productsResponse.data!.where((product) => product['seller_uid'] == widget.sellerId).toList()
              : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print(' Error loading seller data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load seller profile: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Text(_seller?.name ?? 'Seller Profile'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (widget.buyerId != null)
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      sellerId: widget.sellerId,
                      sellerName: _seller?.name,
                      sellerProfilePicture: _seller?.profilePicture,
                    ),
                  ),
                );
              },
              tooltip: 'Contact Seller',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
            )
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Retry',
            onPressed: _loadSellerData,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadSellerData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildSellerBio(),
            const SizedBox(height: 24),
            _buildProductsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (_seller == null) return const SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: _imageProviderFromString(_seller!.profilePicture),
                  child: _seller!.profilePicture == null || _seller!.profilePicture!.isEmpty
                      ? Icon(Icons.person, size: 40, color: Colors.grey[400])
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _seller!.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: const Color(0xFFFFD700), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _sellerRating?.averageRating.toStringAsFixed(1) ?? '0.0',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${_sellerRating?.totalReviews ?? 0} reviews)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.shopping_bag, color: Colors.grey[600], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_products.length} orders',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _seller!.location ?? 'Location not specified',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      sellerId: widget.sellerId,
                      sellerName: _seller?.name,
                      sellerProfilePicture: _seller?.profilePicture,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.message),
              label: const Text('Message Seller'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerBio() {
    if (_seller == null) return const SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About Seller',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Professional farmer specializing in fresh, high-quality agricultural products. '
              'Committed to sustainable farming practices and customer satisfaction.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Products',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        if (_products.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'No products available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return _buildProductCard(product);
            },
          ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildImageWidget(
                product['image'],
                fit: BoxFit.cover,
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['type'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '4.5',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${product['quantity'] ?? 0} sold',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱${(product['price'] ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                          fontSize: 16,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                product: product,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(80, 32),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            if (_reviews.length > 3)
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all reviews page
                },
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'No reviews yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length > 3 ? 3 : _reviews.length,
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return _buildReviewCard(review);
            },
          ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: _imageProviderFromString(review.buyerProfilePicture),
                  child: (review.buyerProfilePicture == null || review.buyerProfilePicture?.isEmpty == true)
                      ? Icon(Icons.person, size: 20, color: Colors.grey[400])
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.buyerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFFFFD700),
                            size: 16,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(review.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  review.comment,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Seller'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_seller!.phoneNumber.isNotEmpty) ...[
                const Text('Phone:'),
                const SizedBox(height: 4),
                Text(
                  _seller!.phoneNumber,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
              ],
              const Text('Message:'),
              const SizedBox(height: 4),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement messaging system
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Messaging feature coming soon!'),
                    backgroundColor: Color(0xFF2E7D32),
                  ),
                );
              },
              child: const Text('Send Message'),
            ),
          ],
        );
      },
    );
  }
}
