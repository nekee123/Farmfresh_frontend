import 'package:flutter/material.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void showOrderNotification({
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              if (actionText != null && onAction != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        onAction();
                      },
                      child: Text(
                        actionText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: const Color(0xFF2E7D32),
          action: actionText != null
              ? SnackBarAction(
                  label: actionText,
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onAction?.call();
                  },
                )
              : null,
        ),
      );
    }
  }

  static void showSuccess(String message) {
    showOrderNotification(
      title: 'Success',
      message: message,
    );
  }

  static void showError(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static void showNewOrderNotification({
    required String productName,
    required String buyerName,
    required String totalAmount,
    VoidCallback? onViewOrders,
  }) {
    showOrderNotification(
      title: '🛒 New Order Received!',
      message: '$buyerName ordered $productName for ₱$totalAmount',
      actionText: 'View Orders',
      onAction: onViewOrders,
    );
  }
}
