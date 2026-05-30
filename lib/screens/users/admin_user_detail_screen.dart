import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/api_response.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  bool _isProcessing = false;
  bool _isBanned = false;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _isBanned = widget.user['is_banned'] == true;
    _fetchBanStatus();
  }

  Future<void> _fetchBanStatus() async {
    final userId = widget.user['uid']?.toString() ?? '';
    if (userId.isEmpty) return;

    final response = await ApiService.getUserBanStatus(userId);
    if (response.success && response.data != null) {
      if (mounted) {
        setState(() {
          _isBanned = response.data!['is_banned'] == true;
          _isLoadingStatus = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingStatus = false);
      }
    }
  }

  String _getRoleDisplay(String? role) {
    switch (role?.toLowerCase()) {
      case 'seller':
        return 'Farmer';
      case 'buyer':
        return 'Consumer';
      case 'admin':
        return 'Admin';
      default:
        return role ?? 'Unknown';
    }
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'seller':
        return Colors.green;
      case 'buyer':
        return Colors.blue;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String? _getUserStatus() {
    // Check for status field if it exists
    if (_isBanned) return 'Banned';
    if (widget.user['is_blocked'] == true) return 'Blocked';
    if (widget.user['is_approved'] == false) return 'Pending';
    return 'Active';
  }

  Color _getStatusColor() {
    final status = _getUserStatus();
    switch (status) {
      case 'Banned':
        return Colors.red;
      case 'Blocked':
        return Colors.orange;
      case 'Pending':
        return Colors.yellow;
      case 'Active':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _performAction(String action, String userId) async {
    // Validate userId is not empty
    if (userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID is missing'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    ApiResponse<void> response;
    String actionName;

    switch (action) {
      case 'approve':
        response = await ApiService.approveUser(userId);
        actionName = 'approve';
        break;
      case 'block':
        response = await ApiService.blockUser(userId);
        actionName = 'block';
        break;
      case 'unblock':
        response = await ApiService.unblockUser(userId);
        actionName = 'unblock';
        break;
      case 'ban':
        response = await ApiService.updateUserBanStatus(userId, true);
        actionName = 'ban';
        break;
      case 'unban':
        response = await ApiService.updateUserBanStatus(userId, false);
        actionName = 'unban';
        break;
      case 'delete':
        response = await ApiService.deleteUser(userId);
        actionName = 'delete';
        break;
      default:
        response = ApiResponse<void>(success: false, error: 'Unknown action');
        actionName = 'perform action on';
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${actionName}d successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate user list should refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $actionName user: ${response.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.user['uid']?.toString() ?? '';
    final role = widget.user['role']?.toString() ?? 'unknown';
    final status = _getUserStatus();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage User'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: _getRoleColor(role).withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: _getRoleColor(role),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user['full_name'] ?? widget.user['name'] ?? 'Unknown User',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(_getRoleDisplay(role)),
                                    backgroundColor: _getRoleColor(role).withOpacity(0.1),
                                    labelStyle: TextStyle(
                                      color: _getRoleColor(role),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(status ?? 'Unknown'),
                                    backgroundColor: _getStatusColor().withOpacity(0.1),
                                    labelStyle: TextStyle(
                                      color: _getStatusColor(),
                                      fontWeight: FontWeight.bold,
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
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildInfoRow('User ID', userId),
                    _buildInfoRow('Phone Number', widget.user['phone_number'] ?? 'N/A'),
                    _buildInfoRow('Location', widget.user['location'] ?? 'N/A'),
                    if (widget.user['created_at'] != null)
                      _buildInfoRow('Created At', _formatDate(widget.user['created_at'])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Management Actions
            const Text(
              'Management Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              'Unblock User',
              Icons.lock_open,
              Colors.blue,
              () => _performAction('unblock', userId),
              status == 'Blocked',
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              _isBanned ? 'Unban User' : 'Ban User',
              _isBanned ? Icons.gavel : Icons.dangerous,
              _isBanned ? Colors.blue : Colors.red,
              () async {
                if (!_isBanned) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Ban User'),
                      content: Text('Are you sure you want to ban ${widget.user['full_name'] ?? widget.user['name'] ?? 'this user'}? They will not be able to log in.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Ban'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                }
                await _performAction(_isBanned ? 'unban' : 'ban', userId);
              },
              !_isLoadingStatus,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Delete User',
              Icons.delete_forever,
              Colors.red,
              () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete User'),
                    content: Text(
                      'Are you sure you want to delete ${widget.user['full_name'] ?? widget.user['name'] ?? 'this user'}? This action cannot be undone and will permanently remove all user data including orders and products.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          backgroundColor: Colors.red.withOpacity(0.1),
                        ),
                        child: const Text('Delete Permanently'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await _performAction('delete', userId);
                }
              },
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(color: Colors.grey[900]),
            ),
          ),
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
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateValue?.toString() ?? 'N/A';
    }
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    bool enabled,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled && !_isProcessing ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon),
        label: Text(_isProcessing ? 'Processing...' : label),
      ),
    );
  }
}
