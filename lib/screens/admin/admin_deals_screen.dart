import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/api_response.dart';

class AdminDealsScreen extends StatefulWidget {
  const AdminDealsScreen({super.key});

  @override
  State<AdminDealsScreen> createState() => _AdminDealsScreenState();
}

class _AdminDealsScreenState extends State<AdminDealsScreen> {
  List<Map<String, dynamic>> _deals = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getAllDeals();
      if (mounted) {
        if (response.success) {
          setState(() {
            _deals = response.data ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = response.error ?? 'Failed to load deals';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteDeal(String dealId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deal'),
        content: const Text('Are you sure you want to delete this deal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await ApiService.deleteDeal(dealId);
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deal deleted successfully')),
          );
          _loadDeals();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete deal: ${response.error}')),
          );
        }
      }
    }
  }

  void _showCreateDealDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateDealDialog(
        existingDeals: _deals,
        onCreated: _loadDeals,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Deals'),
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
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadDeals, child: const Text('Retry')),
                    ],
                  ),
                )
              : _deals.isEmpty
                  ? const Center(child: Text('No deals found'))
                  : RefreshIndicator(
                      onRefresh: _loadDeals,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _deals.length,
                        itemBuilder: (context, index) {
                          final deal = _deals[index];
                          final isActive = deal['status']?.toString().toLowerCase() == 'active';
                          return Card(
                            elevation: isActive ? 6 : 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isActive 
                                  ? const BorderSide(color: Color(0xFF2E7D32), width: 2)
                                  : BorderSide.none,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Row(
                                children: [
                                  Text(
                                    '${deal['percentage']}% OFF - ${deal['type']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  if (isActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  if (isActive && deal['time_left'] != null)
                                    Text(
                                      'Time Left: ${deal['time_left'].toString().split('.').first}',
                                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                    ),
                                  Text('Status: ${deal['status'] ?? 'Unknown'}'),
                                  if (deal['deal_id'] != null)
                                    Text('ID: ${deal['deal_id']}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteDeal(deal['deal_id']),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDealDialog,
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class CreateDealDialog extends StatefulWidget {
  final List<Map<String, dynamic>> existingDeals;
  final VoidCallback onCreated;

  const CreateDealDialog({
    super.key, 
    required this.existingDeals, 
    required this.onCreated
  });

  @override
  State<CreateDealDialog> createState() => _CreateDealDialogState();
}

class _CreateDealDialogState extends State<CreateDealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _percentageController = TextEditingController();
  final _durationValueController = TextEditingController();
  String _selectedType = 'Fruits';
  String _selectedUnit = 'hours';
  bool _isSaving = false;

  final List<String> _types = ['Fruits', 'Vegetables', 'Grains', 'Dairy', 'Meat', 'Herbs'];
  final List<String> _units = ['hours', 'days'];

  @override
  void dispose() {
    _percentageController.dispose();
    _durationValueController.dispose();
    super.dispose();
  }

  Future<void> _createDeal() async {
    if (!_formKey.currentState!.validate()) return;

    // Check for existing active deal of the same type
    final hasActiveDeal = widget.existingDeals.any((deal) => 
      deal['type'] == _selectedType && 
      deal['status']?.toString().toLowerCase() == 'active'
    );

    if (hasActiveDeal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('There is already an active deal for $_selectedType. Please wait for it to expire or delete it.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final dealData = {
      'percentage': int.parse(_percentageController.text),
      'type': _selectedType,
      'duration_value': int.parse(_durationValueController.text),
      'duration_unit': _selectedUnit,
    };

    final response = await ApiService.createDeal(dealData);

    if (mounted) {
      setState(() => _isSaving = false);
      if (response.success) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deal created successfully'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create deal: ${response.error}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Deal'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _percentageController,
                decoration: const InputDecoration(labelText: 'Discount Percentage (%)', hintText: 'e.g. 30'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter percentage';
                  final p = int.tryParse(value);
                  if (p == null || p <= 0 || p > 100) return 'Enter a valid percentage (1-100)';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Product Type'),
                items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _durationValueController,
                      decoration: const InputDecoration(labelText: 'Duration'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: _units.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                      onChanged: (value) => setState(() => _selectedUnit = value!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _createDeal,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create'),
        ),
      ],
    );
  }
}
