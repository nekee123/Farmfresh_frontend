import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final status = (order['order_status'] ?? order['status'] ?? 'Pending').toString().toLowerCase();
    final productName = order['farm_product_name'] ?? 'Unknown Product';
    final sellerName = order['seller_name'] ?? 'Unknown Seller';
    
    // Determine the current step index
    int currentStep = 0;
    bool isCancelled = status == 'cancelled' || status == 'rejected';
    
    if (status == 'pending') {
      currentStep = 0;
    } else if (status == 'confirmed' || status == 'processing') {
      currentStep = 1;
    } else if (status == 'delivered') {
      currentStep = 2;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order Status'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag, color: Color(0xFF2E7D32), size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        Text(
                          'Sold by: $sellerName',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            if (isCancelled)
              _buildCancelledStatus(status)
            else
              _buildTrackingStepper(currentStep),

            const SizedBox(height: 40),
            
            // Additional Info
            const Text(
              'Order Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow('Order ID', order['uid']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'),
            _buildDetailRow('Date Placed', _formatDate(order['created_at'])),
            _buildDetailRow('Payment', order['payment_method'] ?? 'N/A'),
            _buildDetailRow('Delivery to', order['buyer_address'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingStepper(int currentStep) {
    return Column(
      children: [
        _buildStep(
          title: 'Order Placed',
          subtitle: 'We have received your order',
          icon: Icons.receipt_long,
          isActive: currentStep >= 0,
          isCompleted: currentStep > 0,
          isLast: false,
        ),
        _buildStep(
          title: 'Order Confirmed',
          subtitle: 'The seller is preparing your items',
          icon: Icons.thumb_up,
          isActive: currentStep >= 1,
          isCompleted: currentStep > 1,
          isLast: false,
        ),
        _buildStep(
          title: 'Order Delivered',
          subtitle: 'Enjoy your fresh produce!',
          icon: Icons.local_shipping,
          isActive: currentStep >= 2,
          isCompleted: currentStep >= 2,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildCancelledStatus(String status) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.cancel, color: Colors.red, size: 80),
          const SizedBox(height: 16),
          Text(
            'Order ${status.toUpperCase()}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This order will no longer be processed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required bool isCompleted,
    required bool isLast,
  }) {
    final Color color = isActive ? const Color(0xFF2E7D32) : Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF2E7D32) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                size: 20,
                color: isCompleted ? Colors.white : color,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isCompleted ? const Color(0xFF2E7D32) : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.black87 : Colors.grey,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isActive ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    try {
      DateTime date;
      if (dateValue is num) {
        date = DateTime.fromMillisecondsSinceEpoch((dateValue * 1000).toInt());
      } else {
        date = DateTime.parse(dateValue.toString());
      }
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateValue?.toString() ?? 'N/A';
    }
  }
}
