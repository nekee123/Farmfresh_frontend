import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getNotifications();
      
      if (response.success && response.data != null) {
        setState(() {
          _notifications = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load notifications';
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

  Future<void> _markAsRead(String notificationUid) async {
    try {
      await ApiService.markNotificationAsRead(notificationUid);
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((notif) {
            if (notif['uid'] == notificationUid) {
              final updated = Map<String, dynamic>.from(notif);
              updated['is_read'] = true;
              return updated;
            }
            return notif;
          }).toList();
        });
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
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
              onPressed: _loadNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You have no notifications yet',
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
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildFloatingNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildFloatingNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    final type = notification['type'] ?? 'info';
    final senderName = notification['sender_name'] ?? 'Unknown';
    final productName = notification['product_name'] ?? 'product';
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
        message = '$senderName confirmed your order for $productName';
        icon = Icons.check_circle;
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
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!isRead) {
              _markAsRead(notificationUid);
            }
          },
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
                    ],
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
