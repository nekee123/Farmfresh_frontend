import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../users/admin_users_screen.dart';
import '../products/admin_products_screen.dart';
import '../../widgets/hamburger_menu.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _totalUsers = 0;
  int _totalProducts = 0;
  int _totalOrders = 0;
  int _totalFarmers = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final usersResponse = await ApiService.getTotalUsers();
      final productsResponse = await ApiService.getTotalProducts();
      final ordersResponse = await ApiService.getTotalOrders();
      final farmersResponse = await ApiService.getTotalFarmers();

      if (mounted) {
        setState(() {
          _totalUsers = usersResponse.success ? usersResponse.data ?? 0 : 0;
          _totalProducts = productsResponse.success ? productsResponse.data ?? 0 : 0;
          _totalOrders = ordersResponse.success ? ordersResponse.data ?? 0 : 0;
          _totalFarmers = farmersResponse.success ? farmersResponse.data ?? 0 : 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    // Role-based access control
    if (!authService.isAdmin()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('FarmFresh Admin'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Admin notifications coming soon!')),
              );
            },
          ),
          const HamburgerMenu(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
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
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'FarmFresh',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage the FarmFresh platform',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Admin Actions
            const Text(
              'Admin Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  'Manage Users',
                  Icons.people,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminUsersScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  'Products',
                  Icons.inventory,
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminProductsScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  'Orders',
                  Icons.receipt,
                  Colors.orange,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order management coming soon!'),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  'Reports',
                  Icons.analytics,
                  Colors.purple,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reports coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Platform Stats
            const Text(
              'Platform Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 4,
                    color: Colors.blue.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 30,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : Text(
                                  '$_totalUsers',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                          Text(
                            'Total Users',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    color: Colors.green.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.inventory_2,
                            size: 30,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(height: 8),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : Text(
                                  '$_totalProducts',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                          Text(
                            'Products',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 4,
                    color: Colors.orange.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.receipt,
                            size: 30,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : Text(
                                  '$_totalOrders',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                          Text(
                            'Orders',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    color: Colors.purple.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.agriculture,
                            size: 30,
                            color: Colors.purple,
                          ),
                          const SizedBox(height: 8),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : Text(
                                  '$_totalFarmers',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                          Text(
                            'Farmers',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  icon,
                  size: 25,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
