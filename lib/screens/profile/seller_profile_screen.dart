import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/api_response.dart';
import '../../models/seller.dart';
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

ImageProvider? _imageProviderFromString(String? imageData) {
  if (imageData == null || imageData.isEmpty) return null;
  if (imageData.startsWith('data:image')) {
    try {
      final base64String = imageData.split(',').last;
      return MemoryImage(base64Decode(base64String));
    } catch (_) {
      return null;
    }
  }
  return NetworkImage(imageData);
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
  double _averageRating = 0.0;
  List<Map<String, dynamic>> _products = [];
  List<String> _sellerCategories = [];
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
      
      // Fetch all data in parallel
      final results = await Future.wait([
        ApiService.getSellerRating(widget.sellerId),
        ApiService.getProducts(),
        ApiService.getSellerCategories(widget.sellerId),
      ]);

      final ratingResponse = results[0] as ApiResponse<double>;
      final productsResponse = results[1] as ApiResponse<List<Map<String, dynamic>>>;
      final categoriesResponse = results[2] as ApiResponse<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          _averageRating = ratingResponse.data ?? 0.0;

          // Extract seller info from raw product data
          final sellerProductData = (productsResponse.success && productsResponse.data != null)
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

          // Handle Categories
          print('DEBUG: categoriesResponse.success = ${categoriesResponse.success}');
          if (categoriesResponse.success && categoriesResponse.data != null) {
            final data = categoriesResponse.data!;
            print('DEBUG: Raw category data = $data');
            
            dynamic list;
            if (data.containsKey('category')) {
              list = data['category'];
            } else if (data.containsKey('categories')) {
              list = data['categories'];
            } else if (data.containsKey('data')) {
              final nestedData = data['data'];
              if (nestedData is Map) {
                list = nestedData['category'] ?? nestedData['categories'];
              } else if (nestedData is List) {
                list = nestedData;
              }
            }

            if (list is List) {
              print('DEBUG: Found list = $list');
              _sellerCategories = list.map((e) => e.toString()).toList();
            } else if (list is String) {
              _sellerCategories = [list];
            }
          }
          print('📊 Final mapped seller categories: $_sellerCategories');
          
          _products = (productsResponse.success && productsResponse.data != null)
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
                  backgroundColor: Colors.grey[200],
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
                          const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _averageRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
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
                      if (_sellerCategories.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: _sellerCategories.map((category) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
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

  void _showContactDialog() {
    // ... logic removed ...
  }
}
