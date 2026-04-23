import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../models/review.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/api_response.dart';
import '../../widgets/custom_button.dart';

class CreateReviewScreen extends StatefulWidget {
  final Order order;

  const CreateReviewScreen({
    super.key,
    required this.order,
  });

  @override
  State<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text('Write a Review'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderInfo(),
            const SizedBox(height: 24),
            _buildRatingSection(),
            const SizedBox(height: 24),
            _buildCommentSection(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Product', widget.order.farmProductName),
            _buildDetailRow('Quantity', '${widget.order.quantity} units'),
            _buildDetailRow('Total', '₱${widget.order.totalPrice.toStringAsFixed(2)}'),
            _buildDetailRow('Order Date', _formatDate(widget.order.createdAt)),
            if (widget.order.deliveredAt != null)
              _buildDetailRow('Delivered', _formatDate(widget.order.deliveredAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate this order',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How was your experience with this order?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = starValue;
                    });
                  },
                  child: Icon(
                    starValue <= _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFD700),
                    size: 40,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              _getRatingDescription(_rating),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _getRatingColor(_rating),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Comments (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share your experience with this product and seller',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Tell us about the product quality, seller communication, delivery experience...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return CustomButton(
      text: _isSubmitting ? 'Submitting...' : 'Submit Review',
      icon: Icons.send,
      backgroundColor: const Color(0xFF2E7D32),
      onPressed: _isSubmitting ? null : _submitReview,
    );
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 5:
        return 'Excellent - Very satisfied!';
      case 4:
        return 'Good - Would order again';
      case 3:
        return 'Average - Met expectations';
      case 2:
        return 'Poor - Below expectations';
      case 1:
        return 'Very Poor - Disappointed';
      default:
        return 'Rate your experience';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final reviewRequest = ReviewCreateRequest(
        orderUid: widget.order.uid,
        buyerUid: widget.order.buyerUid,
        buyerName: currentUser.name ?? 'User',
        sellerUid: widget.order.sellerUid,
        productUid: widget.order.farmProductUid,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      final response = await _apiService.createReview(reviewRequest);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Go back to orders
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to submit review'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
