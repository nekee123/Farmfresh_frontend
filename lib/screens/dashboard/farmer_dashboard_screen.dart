import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../products/add_product_screen.dart';
import '../products/product_list_screen.dart';
import '../profile/farmer_my_profile_screen.dart';
import '../orders/farmer_orders_screen.dart';
import '../notifications/notifications_screen.dart';
import '../chat/chat_list_screen.dart';
import '../../widgets/hamburger_menu.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  double _sellerRating = 0.0;
  bool _isLoadingRating = true;
  int _productCount = 0;
  bool _isLoadingProductCount = true;
  double _totalRevenue = 0.0;
  int _orderCount = 0;
  bool _isLoadingStats = true;
  List<Map<String, dynamic>> _notifications = [];
  bool _showNotificationCard = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSellerRating();
    _loadProductCount();
    _loadSellerStats();
    _loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh stats when screen regains focus
    _refreshAllStats();
  }

  Future<void> _refreshAllStats() async {
    await Future.wait([
      _loadSellerRating(),
      _loadProductCount(),
      _loadSellerStats(),
      _loadNotifications(),
    ]);
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await ApiService.getNotifications();
      if (response.success && response.data != null) {
        setState(() {
          _notifications = response.data!;
          _unreadCount = _notifications.where((n) => (n['is_read'] ?? false) == false).length;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _loadSellerStats() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser?.uid != null) {
      try {
        final response = await ApiService.getSellerOrders(authService.currentUser!.uid);
        if (response.success && response.data != null && mounted) {
          final orders = response.data!;
          double revenue = 0.0;
          int count = 0;
          
          for (var order in orders) {
            if (order['order_status']?.toString().toLowerCase() == 'delivered') {
              revenue += (order['total_price'] as num?)?.toDouble() ?? 0.0;
              count++;
            }
          }
          
          setState(() {
            _totalRevenue = revenue;
            _orderCount = count;
            _isLoadingStats = false;
          });
        } else if (mounted) {
          setState(() {
            _isLoadingStats = false;
          });
        }
      } catch (e) {
        print('Error loading seller stats: $e');
        if (mounted) {
          setState(() {
            _isLoadingStats = false;
          });
        }
      }
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
        setState(() {
          _notifications = response.data!;
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
        _notifications = response.data!;
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
                    // Navigate to Farmer Orders
                    setState(() {
                      _showNotificationCard = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FarmerOrdersScreen()),
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

  Future<void> _loadSellerRating() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser?.uid != null) {
      try {
        final response = await ApiService.getSellerRating(authService.currentUser!.uid);
        if (response.success && mounted) {
          setState(() {
            _sellerRating = response.data ?? 0.0;
            _isLoadingRating = false;
          });
        } else if (mounted) {
          setState(() {
            _isLoadingRating = false;
          });
        }
      } catch (e) {
        print('Error loading seller rating: $e');
        if (mounted) {
          setState(() {
            _isLoadingRating = false;
          });
        }
      }
    }
  }

  Future<void> _loadProductCount() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser?.uid != null) {
      try {
        final response = await ApiService.getProducts();
        if (response.success && response.data != null && mounted) {
          // Filter products by seller_uid to count only this seller's products
          final sellerProducts = response.data!.where((p) => p['seller_uid'] == authService.currentUser!.uid).toList();
          setState(() {
            _productCount = sellerProducts.length;
            _isLoadingProductCount = false;
          });
        } else if (mounted) {
          setState(() {
            _isLoadingProductCount = false;
          });
        }
      } catch (e) {
        print('Error loading product count: $e');
        if (mounted) {
          setState(() {
            _isLoadingProductCount = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    // Role-based access control
    if (!authService.isSeller()) {
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
                          'Manage your farm products',
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
              IconButton(
                icon: const Icon(Icons.chat_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatListScreen(),
                    ),
                  );
                },
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
          // Quick Stats
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Farm Overview',
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
                        child: _buildStatCard('Products', _isLoadingProductCount ? '...' : '$_productCount', Icons.inventory_2, Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('Orders', '0', Icons.shopping_bag, Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Revenue', 
                          _isLoadingStats ? 'Loading...' : '₱${_totalRevenue.toStringAsFixed(0)}', 
                          Icons.attach_money, 
                          Colors.orange
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Rating', 
                          _isLoadingRating ? 'Loading...' : '${_sellerRating.toStringAsFixed(1)}★', 
                          Icons.star, 
                          Colors.amber
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Orders', 
                          _isLoadingStats ? 'Loading...' : '$_orderCount', 
                          Icons.receipt_long, 
                          Colors.blue
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Products', 
                          _isLoadingProductCount ? 'Loading...' : '$_productCount', 
                          Icons.inventory_2, 
                          Colors.green
                        ),
                      ),
                    ],
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
                          'Add Product',
                          Icons.add_circle_outline,
                          const Color(0xFF2E7D32),
                          () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddProductScreen(
                                  sellerId: authService.currentUser?.uid ?? '',
                                ),
                              ),
                            );
                            if (result == true && mounted) {
                              // Refresh all stats after adding a product
                              _refreshAllStats();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickActionButton(
                          'My Products',
                          Icons.inventory_outlined,
                          const Color(0xFF2E7D32),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProductListScreen(),
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
                          'Orders',
                          Icons.receipt_long_outlined,
                          const Color(0xFF2E7D32),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FarmerOrdersScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickActionButton(
                          'Analytics',
                          Icons.analytics_outlined,
                          const Color(0xFF2E7D32),
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Analytics coming soon!'),
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
                              builder: (context) => const FarmerOrdersScreen(),
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
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No orders yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Orders from customers will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddProductScreen(
                                  sellerId: authService.currentUser?.uid ?? '',
                                ),
                              ),
                            );
                            if (result == true && mounted) {
                              // Refresh all stats after adding a product
                              _refreshAllStats();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Add First Product'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // Performance Chart
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 48,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Track your farm performance',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Analytics dashboard coming soon',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
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
        onTap: (index) async {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddProductScreen(
                    sellerId: authService.currentUser?.uid ?? '',
                  ),
                ),
              );
              if (result == true && mounted) {
                // Refresh product count after adding a product
                _loadProductCount();
              }
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FarmerOrdersScreen(),
                ),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FarmerMyProfileScreen(),
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
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Add',
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
