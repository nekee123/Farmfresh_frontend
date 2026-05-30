import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/api_response.dart';
import '../products/product_list_screen.dart';
import '../products/product_detail_screen.dart';
import '../buyer/buyer_cart_screen.dart';
import '../profile/consumer_my_profile_screen.dart';
import '../profile/seller_profile_screen.dart';
import '../orders/consumer_orders_screen.dart';
import '../buyer/deal_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../chat/chat_list_screen.dart';
import '../../widgets/hamburger_menu.dart';

class ConsumerDashboardScreen extends StatefulWidget {
  const ConsumerDashboardScreen({super.key});

  @override
  State<ConsumerDashboardScreen> createState() => _ConsumerDashboardScreenState();
}

class _ConsumerDashboardScreenState extends State<ConsumerDashboardScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _allProducts = [];
  bool _isLoadingProducts = false;
  bool _isSearching = false;
  String? _productsError;
  bool _showNotificationCard = false;
  int _unreadCount = 0;
  int _unreadMessageCount = 0;
  int _orderCount = 0;
  Map<String, dynamic>? _activeDeal;
  final TextEditingController _searchController = TextEditingController();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadNotifications();
    _loadUnreadMessageCount();
    _loadOrderCount();
    _loadActiveDeal();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final buyerId = authService.currentUser?.uid;
      
      final results = await Future.wait([
        ApiService.getNotifications(),
        ApiService.getConversations(),
        buyerId != null ? ApiService.getBuyerOrders(buyerId) : Future.value(null),
        ApiService.getActiveDeals(),
      ]);

      if (!mounted) return;

      setState(() {
        // 1. Update Notifications
        final notifResponse = results[0] as ApiResponse<List<Map<String, dynamic>>>;
        if (notifResponse.success && notifResponse.data != null) {
          _notifications = notifResponse.data!.where((n) => 
            n['sender_name'] != null && n['product_name'] != null).toList();
          _unreadCount = _notifications.where((n) => (n['is_read'] ?? false) == false).length;
        }

        // 2. Update Messages
        final msgResponse = results[1] as ApiResponse<List<Map<String, dynamic>>>;
        if (msgResponse.success && msgResponse.data != null) {
          int total = 0;
          for (var conv in msgResponse.data!) {
            total += (conv['unread_count'] as num? ?? 0).toInt();
          }
          _unreadMessageCount = total;
        }

        // 3. Update Orders
        if (results[2] != null) {
          final orderResponse = results[2] as ApiResponse<List<Map<String, dynamic>>>;
          if (orderResponse.success && orderResponse.data != null) {
            _orderCount = orderResponse.data!.length;
          }
        }

        // 4. Update Deals
        final dealResponse = results[3] as ApiResponse<List<Map<String, dynamic>>>;
        if (dealResponse.success && dealResponse.data != null && dealResponse.data!.isNotEmpty) {
          _activeDeal = dealResponse.data!.first;
        } else {
          _activeDeal = null;
        }
      });
    } catch (e) {
      print('Error polling dashboard data: $e');
    }
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _loadOrderCount() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final buyerId = authService.currentUser?.uid;
      if (buyerId != null) {
        final response = await ApiService.getBuyerOrders(buyerId);
        if (response.success && response.data != null) {
          if (mounted) {
            setState(() {
              _orderCount = response.data!.length;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading order count: $e');
    }
  }

  Future<void> _loadActiveDeal() async {
    try {
      final response = await ApiService.getActiveDeals();
      if (response.success && response.data != null && response.data!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _activeDeal = response.data!.first;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _activeDeal = null;
          });
        }
      }
    } catch (e) {
      print('Error loading active deal: $e');
    }
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final response = await ApiService.getConversations();
      if (response.success && response.data != null) {
        int total = 0;
        for (var conv in response.data!) {
          total += (conv['unread_count'] as num? ?? 0).toInt();
        }
        if (mounted) {
          setState(() {
            _unreadMessageCount = total;
          });
        }
      }
    } catch (e) {
      print('Error loading unread message count: $e');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await ApiService.getNotifications();
      if (response.success && response.data != null) {
        final List<Map<String, dynamic>> allNotifications = response.data!;
        
        // Filter out notifications with null sender_name or product_name
        final validNotifications = allNotifications.where((n) {
          return n['sender_name'] != null && n['product_name'] != null;
        }).toList();

        setState(() {
          _notifications = validNotifications;
          _unreadCount = _notifications.where((n) => (n['is_read'] ?? false) == false).length;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _toggleNotificationCard() async {
    if (_showNotificationCard) {
      setState(() {
        _showNotificationCard = false;
      });
      return;
    }

    // Load notifications
    try {
      final response = await ApiService.getNotifications();
      if (response.success && response.data != null) {
        final List<Map<String, dynamic>> allNotifications = response.data!;
        
        // Filter out notifications with null sender_name or product_name
        final validNotifications = allNotifications.where((n) {
          return n['sender_name'] != null && n['product_name'] != null;
        }).toList();

        setState(() {
          _notifications = validNotifications;
          _unreadCount = _notifications.where((n) => (n['is_read'] ?? false) == false).length;
          _showNotificationCard = true;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _showNotificationBottomSheet(BuildContext context) async {
    // Load notifications
    try {
      final response = await ApiService.getNotifications();
      if (response.success && response.data != null) {
        final List<Map<String, dynamic>> allNotifications = response.data!;
        
        // Filter out notifications with null sender_name or product_name
        _notifications = allNotifications.where((n) {
          return n['sender_name'] != null && n['product_name'] != null;
        }).toList();
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotificationBottomSheet(),
    );
  }

  Widget _buildNotificationBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Notifications list
          Flexible(
            child: _notifications.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 80,
                            color: Color(0xFF2E7D32),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildFloatingNotificationCard(notification);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    final type = notification['type'] ?? 'info';
    final senderName = notification['sender_name'] ?? 'Unknown';
    final productName = notification['product_name'] ?? 'product';
    final createdAt = notification['created_at'];
    final notificationUid = notification['uid'];

    String title;
    String message;
    IconData icon;
    Color iconColor;

    switch (type.toLowerCase()) {
      case 'order_placed':
        title = 'New Order';
        message = '$senderName ordered $productName';
        icon = Icons.shopping_cart;
        iconColor = Colors.blue;
        break;
      case 'order_confirmed':
        title = 'Order Confirmed';
        message = 'The seller $senderName has confirmed your order for $productName';
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'order_rejected':
        title = 'Order Rejected';
        message = 'The seller $senderName has rejected your order for $productName';
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'order_delivered':
        title = 'Order Delivered';
        message = 'The seller $senderName has marked your order for $productName as delivered';
        icon = Icons.local_shipping;
        iconColor = Colors.green;
        break;
      case 'new_review':
        title = 'New Review';
        message = '$senderName left a review for $productName';
        icon = Icons.star;
        iconColor = Colors.amber;
        break;
      default:
        title = 'Notification';
        message = 'You have a new notification';
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isRead ? Colors.black.withOpacity(0.05) : Colors.black.withOpacity(0.15),
            blurRadius: isRead ? 8 : 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: isRead ? null : const Border(
          left: BorderSide(color: Color(0xFF2E7D32), width: 4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (!isRead) {
                      ApiService.markNotificationAsRead(notificationUid);
                      setState(() {
                        final index = _notifications.indexWhere((n) => n['uid'] == notificationUid);
                        if (index != -1) {
                          _notifications[index]['is_read'] = true;
                          _unreadCount = _notifications.where((n) => (n['is_read'] ?? false) == false).length;
                        }
                      });
                    }
                    // Navigate to My Orders
                    setState(() {
                      _showNotificationCard = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ConsumerOrdersScreen()),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                          fontSize: 16,
                          color: isRead ? Colors.grey[700] : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: isRead ? Colors.grey[600] : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) async {
                  if (value == 'mark_read') {
                    if (!isRead) {
                      ApiService.markNotificationAsRead(notificationUid);
                      setState(() {
                        final index = _notifications.indexWhere((n) => n['uid'] == notificationUid);
                        if (index != -1) {
                          _notifications[index]['is_read'] = true;
                          _unreadCount = _notifications.where((n) => (n['is_read'] ?? false) == false).length;
                        }
                      });
                    }
                  } else if (value == 'delete') {
                    final response = await ApiService.deleteNotification(notificationUid);
                    if (response.success) {
                      setState(() {
                        _notifications.removeWhere((n) => n['uid'] == notificationUid);
                        _unreadCount = _notifications.where((n) => (n['is_read'] ?? false) == false).length;
                      });
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_read',
                    child: Row(
                      children: [
                        Icon(
                          isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                          color: isRead ? Colors.grey : const Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 8),
                        Text(isRead ? 'Mark as unread' : 'Mark as read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    try {
      DateTime date;
      if (dateValue is double) {
        date = DateTime.fromMillisecondsSinceEpoch(dateValue.toInt());
      } else if (dateValue is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else {
        date = DateTime.parse(dateValue.toString());
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateValue.toString();
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });

    try {
      final response = await ApiService.getProducts();
      
      if (response.success && response.data != null) {
        setState(() {
          _products = response.data!;
          _allProducts = response.data!;
          _isLoadingProducts = false;
        });
      } else {
        setState(() {
          _productsError = response.error ?? 'Failed to load products';
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      setState(() {
        _productsError = 'Error: $e';
        _isLoadingProducts = false;
      });
    }
  }

  Widget _buildSearchResultCard(Map<String, dynamic> result) {
    final resultType = result['result_type'] ?? 'product';
    
    if (resultType == 'seller') {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF2E7D32),
            child: Icon(Icons.person, color: Colors.white),
          ),
          title: Text(result['name'] ?? 'Unknown Seller'),
          subtitle: Text(result['location'] ?? ''),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Navigate to seller profile
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SellerProfileScreen(
                  sellerId: result['uid'] ?? result['id'] ?? '',
                ),
              ),
            );
          },
        ),
      );
    } else {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: result['image'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildProductImage(result['image']),
                  )
                : Icon(Icons.image, color: Colors.grey),
          ),
          title: Text(result['name'] ?? 'Unknown Product'),
          subtitle: Text('₱${result['price'] ?? '0'}'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Navigate to product detail
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(
                  product: result,
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _products = _allProducts;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Search products locally
      final productResults = _allProducts.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();
        final sellerName = (product['seller_name'] ?? '').toString().toLowerCase();
        final type = (product['type'] ?? '').toString().toLowerCase();
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery) || 
               sellerName.contains(searchQuery) ||
               type.contains(searchQuery);
      }).toList();

      // Also call backend search for sellers
      final sellerResponse = await ApiService.searchItems(query, 'sellers');
      final productResponse = await ApiService.searchItems(query, 'products');

      List<Map<String, dynamic>> combinedResults = [];
      
      // Add product results
      if (productResponse.success && productResponse.data != null) {
        combinedResults.addAll(productResponse.data!.map((item) => {
          ...item,
          'result_type': 'product',
        }).toList());
      }
      
      // Add seller results
      if (sellerResponse.success && sellerResponse.data != null) {
        combinedResults.addAll(sellerResponse.data!.map((item) => {
          ...item,
          'result_type': 'seller',
        }).toList());
      }

      // Add local product results
      combinedResults.addAll(productResults.map((item) => {
        ...item,
        'result_type': 'product',
      }).toList());

      setState(() {
        _searchResults = combinedResults;
        _isSearching = false;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  Widget _buildProductImage(String? imageData, {double? width, double? height}) {
    if (imageData == null || imageData.isEmpty) {
      return Icon(Icons.image, color: Colors.grey, size: width != null ? width / 2 : 40);
    }

    if (imageData.startsWith('data:image')) {
      return Image.memory(
        base64Decode(imageData.split(',').last),
        width: width,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: true, // This prevents the flicker during rebuilds
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: Colors.grey, size: width != null ? width / 2 : 40),
      );
    }

    return Image.network(
      imageData,
      width: width,
      height: height,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => Icon(Icons.image, color: Colors.grey, size: width != null ? width / 2 : 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    // Role-based access control
    if (!authService.isBuyer()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          CustomScrollView(
        slivers: [
          // App Bar with Search
          SliverAppBar(
            floating: true,
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2E7D32),
                      Color(0xFF4CAF50),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.eco,
                                size: 30,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'FarmFresh',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Fresh from farm to your table',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_outlined),
                    onPressed: () async {
                      _stopPolling();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatListScreen(),
                        ),
                      );
                      _startPolling();
                    },
                  ),
                  if (_unreadMessageCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          _unreadMessageCount > 9 ? '9+' : _unreadMessageCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      _toggleNotificationCard();
                    },
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const HamburgerMenu(),
            ],
          ),
          // Search Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _performSearch(value),
                decoration: InputDecoration(
                  hintText: 'Search products and sellers...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.tune, color: Colors.white, size: 20),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          // Search Results
          if (_isSearching)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                ),
              ),
            ),
          if (_searchResults.isNotEmpty && !_isSearching)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._searchResults.map((result) => _buildSearchResultCard(result)),
                  ],
                ),
              ),
            ),
          // Categories
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      TextButton(
                        onPressed: _showAllCategoriesBottomSheet,
                        child: const Text(
                          'See all',
                          style: TextStyle(color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildCategoryCard('Vegetables', Icons.eco, Colors.green),
                      const SizedBox(width: 12),
                      _buildCategoryCard('Fruits', Icons.apple, Colors.red),
                      const SizedBox(width: 12),
                      _buildCategoryCard('Dairy', Icons.egg, Colors.blue),
                      const SizedBox(width: 12),
                      _buildCategoryCard('Grains', Icons.grain, Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // Special Offers
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Special Offers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DealListScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'See all',
                          style: TextStyle(color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_activeDeal != null && (_activeDeal!['status']?.toString().toLowerCase() == 'active'))
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1B5E20).withOpacity(0.8),
                          const Color(0xFF2E7D32).withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 20,
                          top: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _activeDeal!['deal_name'] ?? 'Fresh Deal',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_activeDeal!['percentage']}% OFF on all ${_activeDeal!['type']}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              if (_activeDeal!['time_left'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Ends in: ${_activeDeal!['time_left'].toString().split('.').first}',
                                    style: const TextStyle(
                                      color: Colors.yellowAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ProductListScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF2E7D32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Shop Now'),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 20,
                          bottom: 20,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Icon(
                              Icons.eco,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  else
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[300],
                      ),
                      child: const Center(
                        child: Text(
                          'No active offers at the moment',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // Quick Actions
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          'Browse Products',
                          Icons.shopping_cart_outlined,
                          const Color(0xFF2E7D32),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProductListScreen(
                                  isGridView: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickActionButton(
                          'Orders',
                          Icons.receipt_long_outlined,
                          const Color(0xFF2E7D32),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ConsumerOrdersScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          'Favorites',
                          Icons.favorite_outline,
                          const Color(0xFF2E7D32),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProductListScreen(
                                  showOnlyFavorites: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickActionButton(
                          'Track Order',
                          Icons.location_on_outlined,
                          const Color(0xFF2E7D32),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ConsumerOrdersScreen(
                                  isTrackingMode: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // Available Products
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProductListScreen(
                                isGridView: true,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'View all',
                          style: TextStyle(color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingProducts)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                      ),
                    )
                  else if (_productsError != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Error loading products: $_productsError',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else if (_products.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'No products available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _products.take(5).length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return GestureDetector(
                            key: ValueKey(product['uid'] ?? index),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailScreen(product: product),
                                ),
                              );
                            },
                            child: Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                      ),
                                      child: product['image'] != null && product['image'].isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                              child: _buildProductImage(
                                                product['image'],
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.image,
                                              color: Colors.grey,
                                              size: 40,
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₱${product['price']?.toString() ?? '0'}',
                                          style: const TextStyle(
                                            color: Color(0xFF2E7D32),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product['type'] ?? 'Unknown',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // Recent Orders
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ConsumerOrdersScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'View all',
                          style: TextStyle(color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _orderCount > 0 ? Icons.inventory_2 : Icons.inventory_2_outlined,
                          size: 48,
                          color: const Color(0xFF2E7D32),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No. of orders: $_orderCount',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _orderCount > 0 
                            ? 'You have active orders in progress' 
                            : 'Start shopping to see your orders here',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_orderCount == 0)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProductListScreen(isGridView: true),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Start Shopping'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
          if (_showNotificationCard)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showNotificationCard = false;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // Prevent tap from dismissing
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E7D32),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.notifications, color: Colors.white, size: 28),
                                const SizedBox(width: 12),
                                const Text(
                                  'Notifications',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _showNotificationCard = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          // Notifications list
                          Flexible(
                            child: _notifications.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(40),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.notifications_none,
                                            size: 80,
                                            color: Color(0xFF2E7D32),
                                          ),
                                          SizedBox(height: 20),
                                          Text(
                                            'No notifications',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _notifications.length,
                                    itemBuilder: (context, index) {
                                      final notification = _notifications[index];
                                      return _buildFloatingNotificationCard(notification);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              final authService = Provider.of<AuthService>(context, listen: false);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BuyerCartScreen(),
                ),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConsumerOrdersScreen(),
                ),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConsumerMyProfileScreen(),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_outlined),
            activeIcon: Icon(Icons.receipt),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductListScreen(
                category: title,
                isGridView: true,
              ),
            ),
          );
        },
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllCategoriesBottomSheet() {
    final categories = [
      {'name': 'Vegetables', 'icon': Icons.eco, 'color': Colors.green},
      {'name': 'Fruits', 'icon': Icons.apple, 'color': Colors.red},
      {'name': 'Grains', 'icon': Icons.grain, 'color': Colors.orange},
      {'name': 'Dairy', 'icon': Icons.egg, 'color': Colors.blue},
      {'name': 'Meat', 'icon': Icons.kebab_dining, 'color': Colors.brown},
      {'name': 'Herbs', 'icon': Icons.psychology_alt, 'color': Colors.teal},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductListScreen(
                            category: cat['name'] as String,
                            isGridView: true,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (cat['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            cat['icon'] as IconData,
                            color: cat['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat['name'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
