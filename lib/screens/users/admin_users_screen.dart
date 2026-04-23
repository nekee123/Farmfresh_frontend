import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getAllUsers();
      
      if (mounted) {
        if (response.success) {
          setState(() {
            _users = response.data ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = response.error ?? 'Failed to load users';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading users: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToUserDetail(Map<String, dynamic> user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminUserDetailScreen(user: user),
      ),
    );

    // If result is true, refresh the user list
    if (result == true && mounted) {
      _loadUsers();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Color(0xFF2E7D32),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'No users registered yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Registered users will appear here',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        itemCount: _users.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final role = user['role']?.toString() ?? 'unknown';
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _navigateToUserDetail(user),
                              borderRadius: BorderRadius.circular(8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getRoleColor(role).withOpacity(0.2),
                                  child: Icon(
                                    Icons.person,
                                    color: _getRoleColor(role),
                                  ),
                                ),
                                title: Text(
                                  user['full_name'] ?? user['name'] ?? 'Unknown User',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Phone: ${user['phone_number'] ?? 'N/A'}'),
                                    if (user['location'] != null)
                                      Text('Location: ${user['location']}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
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
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers,
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Refresh',
      ),
    );
  }
}
