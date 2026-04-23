
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/api_response.dart';
import '../../models/seller.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class AddProductScreen extends StatefulWidget {
  final String sellerId;
  final Map<String, dynamic>? product; // Optional product data for editing

  const AddProductScreen({
    super.key,
    required this.sellerId,
    this.product,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  
  String? _selectedImageBase64;
  bool _isLoading = false;
  
  // Dropdown selections
  String? _selectedCategory;
  String? _selectedPaymentMethod;

  // Category options
  final List<String> _categories = [
    'Fruits',
    'Vegetables', 
    'Grains',
    'Dairy',
    'Meat',
    'Herbs',
    'Other'
  ];

  // Payment method options
  final List<String> _paymentMethods = [
    'CASH_ON_DELIVERY',
    'MEET_UP_CASH_ON_PICKUP',
    'CASH_ON_DELIVERY,MEET_UP_CASH_ON_PICKUP'
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill form if editing an existing product
    if (widget.product != null) {
      _nameController.text = widget.product!['name'] ?? '';
      _priceController.text = widget.product!['price']?.toString() ?? '';
      _quantityController.text = widget.product!['quantity']?.toString() ?? '';
      _descriptionController.text = widget.product!['description'] ?? '';
      _selectedCategory = widget.product!['type'] ?? _categories.first;
      _selectedPaymentMethod = widget.product!['payment_methods'] ?? _paymentMethods.first;
      if (widget.product!['image'] != null && widget.product!['image'].isNotEmpty) {
        _selectedImageBase64 = widget.product!['image'];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 600,
      );

      if (image != null) {
        // Convert image to base64
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        
        setState(() {
          _selectedImageBase64 = base64String;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final sellerId = authService.currentUser?.uid ?? widget.sellerId;
      
      print('👤 Current user: ${authService.currentUser?.name}');
      print('🆔 Current user UID: ${authService.currentUser?.uid}');
      print('🆔 Seller ID from widget: ${widget.sellerId}');
      print('🆔 Final seller ID being used: $sellerId');
      
      if (sellerId == null) {
        print('❌ ERROR: Seller ID is null! Product will not have seller association.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not logged in properly. Please log out and log back in.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final productData = {
        'name': _nameController.text,
        'type': _selectedCategory ?? 'Other', // Use dropdown selection
        'price': double.parse(_priceController.text),
        'quantity': int.parse(_quantityController.text),
        'description': _descriptionController.text,
        'image': _selectedImageBase64 ?? 'default.jpg',
        'payment_methods': _selectedPaymentMethod ?? 'CASH_ON_DELIVERY', // Use dropdown selection
      };

      final isEditing = widget.product != null;
      
      print('📤 ${isEditing ? 'Updating' : 'Creating'} product with data:');
      print('   - name: ${productData['name']}');
      print('   - type: ${productData['type']}');
      print('   - price: ${productData['price']}');
      print('   - quantity: ${productData['quantity']}');
      print('   - payment_methods: ${productData['payment_methods']}');

      ApiResponse<Map<String, dynamic>> response;
      if (isEditing) {
        print('📤 Updating product with UID: ${widget.product!['uid']}');
        response = await ApiService.updateProduct(widget.product!['uid'], productData);
      } else {
        print('📤 Creating new product');
        response = await ApiService.createProduct(productData);
      }
      print('📥 Product ${isEditing ? 'update' : 'creation'} response: success=${response.success}, error=${response.error}');

      if (response.success) {
        print('✅ Product ${isEditing ? 'updated' : 'created'} successfully!');
        print('📤 Response data: ${response.data}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product ${isEditing ? 'updated' : 'added'} successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          print('🔄 Navigating back with refresh signal...');
          // Return to previous screen with success signal to trigger refresh
          Navigator.pop(context, true);
        }
      } else {
        print('❌ Product ${isEditing ? 'update' : 'creation'} failed: ${response.error}');
        
        // Check if error is due to permission issue (403 Forbidden)
        String errorMessage = response.error ?? 'Unknown error';
        if (errorMessage.contains('403') || errorMessage.toLowerCase().contains('forbidden') || 
            errorMessage.toLowerCase().contains('permission') || errorMessage.toLowerCase().contains('only sellers')) {
          errorMessage = 'Only sellers can create products. Please log in with a seller account.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isEditing ? 'update' : 'add'} product: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Product Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: _selectedImageBase64 != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    base64.decode(_selectedImageBase64!.split(',').last),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 50,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to add image',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
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
              const SizedBox(height: 16),
              // Product Name
              CustomTextField(
                label: 'Product Name',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Price
              CustomTextField(
                label: 'Price',
                controller: _priceController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Quantity
              CustomTextField(
                label: 'Quantity',
                controller: _quantityController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Category Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: const Text('Select Category'),
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Payment Method Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedPaymentMethod,
                  hint: const Text('Select Payment Method'),
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _paymentMethods.map((String method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(
                        method.replaceAll('_', ' ').replaceAll(',', ' + '),
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPaymentMethod = newValue;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Description
              CustomTextField(
                label: 'Description',
                controller: _descriptionController,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Add Product Button
              CustomButton(
                text: 'Add Product',
                onPressed: _isLoading ? () {} : _addProduct,
                isLoading: _isLoading,
                height: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
