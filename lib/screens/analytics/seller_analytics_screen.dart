import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/api_response.dart';
import 'package:intl/intl.dart';

class SellerAnalyticsScreen extends StatefulWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  State<SellerAnalyticsScreen> createState() => _SellerAnalyticsScreenState();
}

class _SellerAnalyticsScreenState extends State<SellerAnalyticsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];

  // Analytics data
  double _totalEarnings = 0.0;
  double _pendingEarnings = 0.0;
  Map<String, int> _productSalesCount = {};
  Map<String, double> _productRevenue = {};
  Map<DateTime, double> _monthlyRevenue = {};
  Map<DateTime, int> _monthlySales = {};
  int _selectedYear = DateTime.now().year >= 2026 ? DateTime.now().year : 2026;
  final List<int> _years = List.generate(11, (index) => 2026 + index);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final sellerId = authService.currentUser?.uid;
      
      if (sellerId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      // Fetch both orders and products in parallel
      final results = await Future.wait([
        ApiService.getSellerOrders(sellerId),
        ApiService.getProducts(),
      ]);

      final ordersResponse = results[0] as ApiResponse<List<Map<String, dynamic>>>;
      final productsResponse = results[1] as ApiResponse<List<Map<String, dynamic>>>;
      
      if (ordersResponse.success && ordersResponse.data != null) {
        _orders = ordersResponse.data!;
        
        List<Map<String, dynamic>> sellerProducts = [];
        if (productsResponse.success && productsResponse.data != null) {
          sellerProducts = productsResponse.data!
              .where((p) => p['seller_uid'] == sellerId)
              .toList();
        }

        _processAnalytics(sellerProducts);
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = ordersResponse.error ?? 'Failed to load data';
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

  void _processAnalytics(List<Map<String, dynamic>> sellerProducts) {
    _totalEarnings = 0.0;
    _pendingEarnings = 0.0;
    _productSalesCount = {};
    _productRevenue = {};
    _monthlyRevenue = {};
    _monthlySales = {};

    // Initialize all seller products with zero values
    for (var product in sellerProducts) {
      final name = product['name'] ?? 'Unknown';
      _productSalesCount[name] = 0;
      _productRevenue[name] = 0.0;
    }

    for (var order in _orders) {
      final status = (order['order_status'] ?? '').toString().toLowerCase();
      final price = (order['total_price'] as num?)?.toDouble() ?? 0.0;
      final quantity = (order['quantity'] as num?)?.toInt() ?? 0;
      final productName = order['farm_product_name'] ?? 'Unknown';
      
      // Ensure the product exists in our maps (in case order has a product not in current list)
      if (!_productSalesCount.containsKey(productName)) {
        _productSalesCount[productName] = 0;
        _productRevenue[productName] = 0.0;
      }

      // 1. Calculate Earnings
      if (status == 'delivered') {
        _totalEarnings += price;
        
        // 2. Track Product Performance (Only for successful sales)
        _productSalesCount[productName] = (_productSalesCount[productName] ?? 0) + quantity;
        _productRevenue[productName] = (_productRevenue[productName] ?? 0.0) + price;

        // 3. Monthly Revenue (Only for delivered)
        try {
          final timestamp = order['created_at'];
          DateTime date;
          if (timestamp is num) {
            date = DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt());
          } else {
            date = DateTime.parse(timestamp.toString());
          }
          // Normalize to first day of month for grouping
          final monthDate = DateTime(date.year, date.month, 1);
          _monthlyRevenue[monthDate] = (_monthlyRevenue[monthDate] ?? 0.0) + price;
          _monthlySales[monthDate] = (_monthlySales[monthDate] ?? 0) + 1;
        } catch (e) {
          print('Error parsing date: $e');
        }
      } else if (status == 'pending' || status == 'confirmed' || status == 'processing') {
        _pendingEarnings += price;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _error != null
              ? _buildErrorState()
              : _buildAnalyticsContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEarningsCard(),
            const SizedBox(height: 24),
            const Text(
              'Product Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 12),
            _buildProductsPerformanceList(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Sales Revenue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isDense: true,
                      items: _years.map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text('$year', style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedYear = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMonthlySalesChart(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Earnings (Delivered)', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            '₱${_totalEarnings.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pending Revenue', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    '₱${_pendingEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total Orders', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    '${_orders.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsPerformanceList() {
    if (_productSalesCount.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No products found', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    // Sort products by revenue
    final sortedProducts = _productRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedProducts.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        final count = _productSalesCount[product.key] ?? 0;
        final hasSales = count > 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: !hasSales ? Colors.grey[200] : (index == 0 ? Colors.amber : (index == 1 ? Colors.grey[300] : Colors.orange[200])),
              child: !hasSales 
                ? const Icon(Icons.inventory_2, size: 20, color: Colors.grey)
                : Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            title: Text(product.key, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Sold $count units'),
            trailing: Text(
              '₱${product.value.toStringAsFixed(0)}',
              style: TextStyle(
                color: hasSales ? const Color(0xFF2E7D32) : Colors.grey, 
                fontWeight: FontWeight.bold, 
                fontSize: 16
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlySalesChart() {
    // Generate 12 months for the selected year
    final List<MapEntry<DateTime, double>> displayData = List.generate(12, (index) {
      final monthDate = DateTime(_selectedYear, index + 1, 1);
      return MapEntry(monthDate, _monthlyRevenue[monthDate] ?? 0.0);
    });

    // Determine max revenue for scaling (at least 100k or the actual max)
    double maxVal = displayData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    double yAxisMax = (maxVal > 100000) ? ((maxVal / 100000).ceil() * 100000).toDouble() : 100000.0;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 24, 16, 16),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Y-Axis Labels
                  SizedBox(
                    width: 45,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _yAxisLabel(yAxisMax),
                        _yAxisLabel(yAxisMax * 0.75),
                        _yAxisLabel(yAxisMax * 0.5),
                        _yAxisLabel(yAxisMax * 0.25),
                        _yAxisLabel(0),
                        const SizedBox(height: 20), // Placeholder for Month labels alignment
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // The Bars Area
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              // Grid lines
                              Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(5, (index) => const Divider(height: 0, color: Color(0xFFEEEEEE))),
                              ),
                              // The Bars
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: displayData.map((entry) {
                                  final barHeightFactor = (entry.value / yAxisMax).clamp(0.0, 1.0);
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (entry.value > 0)
                                            FittedBox(
                                              child: Text(
                                                entry.value >= 1000 ? '${(entry.value / 1000).toStringAsFixed(1)}k' : entry.value.toStringAsFixed(0),
                                                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                              ),
                                            ),
                                          const SizedBox(height: 2),
                                          Container(
                                            height: (barHeightFactor * 180).clamp(0, 180).toDouble(),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [const Color(0xFF2E7D32), const Color(0xFF2E7D32).withOpacity(0.5)],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // X-Axis Labels (Months)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: displayData.map((entry) {
                            return Expanded(
                              child: Text(
                                DateFormat('MMM').format(entry.key).substring(0, 1),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF81C784)]),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Monthly Revenue in $_selectedYear (₱)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _yAxisLabel(double value) {
    String label;
    if (value >= 1000) {
      label = '${(value / 1000).toInt()}k';
    } else {
      label = value.toInt().toString();
    }
    return Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey));
  }
}
