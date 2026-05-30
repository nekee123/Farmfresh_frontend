import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedRole;
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = ['Vegetables', 'Fruits', 'Grains', 'Dairy', 'Meat', 'Herbs'];

  final List<String> _barangayList = [
    'Brgy. Balimbing Proper, Panglima Sugala, Tawi-Tawi',
    'Brgy. Batu-batu (Pob.), Panglima Sugala, Tawi-Tawi',
    'Brgy. Buan, Panglima Sugala, Tawi-Tawi',
    'Brgy. Dungon, Panglima Sugala, Tawi-Tawi',
    'Brgy. Luuk Buntal, Panglima Sugala, Tawi-Tawi',
    'Brgy. Parangan, Panglima Sugala, Tawi-Tawi',
    'Brgy. Tabunan, Panglima Sugala, Tawi-Tawi',
    'Brgy. Tungbangkaw, Panglima Sugala, Tawi-Tawi',
    'Brgy. Bauno Garing, Panglima Sugala, Tawi-Tawi',
    'Brgy. Belatan Halu, Panglima Sugala, Tawi-Tawi',
    'Brgy. Karaha, Panglima Sugala, Tawi-Tawi',
    'Brgy. Kulape, Panglima Sugala, Tawi-Tawi',
    'Brgy. Liyaburan, Panglima Sugala, Tawi-Tawi',
    'Brgy. Magsaggaw, Panglima Sugala, Tawi-Tawi',
    'Brgy. Malacca, Panglima Sugala, Tawi-Tawi',
    'Brgy. Sumangday, Panglima Sugala, Tawi-Tawi',
    'Brgy. Tundon, Panglima Sugala, Tawi-Tawi',
    'Brgy. Ipil, Bongao, Tawi-Tawi',
    'Brgy. Kamagong, Bongao, Tawi-Tawi',
    'Brgy. Karungdong, Bongao, Tawi-Tawi',
    'Brgy. Lakit Lakit, Bongao, Tawi-Tawi',
    'Brgy. Lamion, Bongao, Tawi-Tawi',
    'Brgy. Lapid Lapid, Bongao, Tawi-Tawi',
    'Brgy. Lato Lato, Bongao, Tawi-Tawi',
    'Brgy. Luuk Pandan, Bongao, Tawi-Tawi',
    'Brgy. Luuk Tulay, Bongao, Tawi-Tawi',
    'Brgy. Malassa, Bongao, Tawi-Tawi',
    'Brgy. Mandulan, Bongao, Tawi-Tawi',
    'Brgy. Masantong, Bongao, Tawi-Tawi',
    'Brgy. Montay Montay, Bongao, Tawi-Tawi',
    'Brgy. Pababag, Bongao, Tawi-Tawi',
    'Brgy. Pagasinan, Bongao, Tawi-Tawi',
    'Brgy. Pahut, Bongao, Tawi-Tawi',
    'Brgy. Pakias, Bongao, Tawi-Tawi',
    'Brgy. Paniongan, Bongao, Tawi-Tawi',
    'Brgy. Pasiagan, Bongao, Tawi-Tawi',
    'Brgy. Bongao Poblacion, Bongao, Tawi-Tawi',
    'Brgy. Sanga-sanga, Bongao, Tawi-Tawi',
    'Brgy. Silubog, Bongao, Tawi-Tawi',
    'Brgy. Simandagit, Bongao, Tawi-Tawi',
    'Brgy. Sumangat, Bongao, Tawi-Tawi',
    'Brgy. Tarawakan, Bongao, Tawi-Tawi',
    'Brgy. Tongsinah, Bongao, Tawi-Tawi',
    'Brgy. Tubig Basag, Bongao, Tawi-Tawi',
    'Brgy. Ungus-ungus, Bongao, Tawi-Tawi',
    'Brgy. Lagasan, Bongao, Tawi-Tawi',
    'Brgy. Nalil, Bongao, Tawi-Tawi',
    'Brgy. Pagatpat, Bongao, Tawi-Tawi',
    'Brgy. Pag-asa, Bongao, Tawi-Tawi',
    'Brgy. Tubig Tanah, Bongao, Tawi-Tawi',
    'Brgy. Tubig-Boh, Bongao, Tawi-Tawi',
    'Brgy. Tubig-Mampallam, Bongao, Tawi-Tawi',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final success = await authService.register(
        _nameController.text,
        _phoneController.text,
        _passwordController.text,
        _locationController.text,
        role: _selectedRole!,
        category: _selectedRole == 'seller' ? _selectedCategory : '',
      );

      if (!mounted) return;

      if (success) {
        // Attempt automatic login after successful registration
        final loginSuccess = await authService.login(
          _phoneController.text,
          _passwordController.text,
        );

        if (!mounted) return;

        if (loginSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created and logged in!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to appropriate dashboard based on role
          final role = authService.getUserRole()?.toLowerCase();
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
          } else if (role == 'seller' || role == 'farmer') {
            Navigator.pushReplacementNamed(context, '/farmer_dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/consumer_dashboard');
          }
        } else {
          // If auto-login fails due to unverified account, go to OTP screen
          if (authService.errorMessage != null && 
              authService.errorMessage!.contains('verify OTP')) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OtpVerificationScreen(
                  phoneNumber: _phoneController.text.trim(),
                  password: _passwordController.text,
                ),
              ),
            );
            return;
          }

          // If auto-login fails for other reasons, fallback to manual login screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please login manually.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authService.errorMessage ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLocationPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Your Barangay'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _barangayList.length,
            itemBuilder: (context, index) {
              final barangay = _barangayList[index];
              return ListTile(
                title: Text(barangay, style: const TextStyle(fontSize: 14)),
                onTap: () {
                  setState(() {
                    _locationController.text = barangay;
                  });
                  Navigator.pop(context);
                },
                selected: _locationController.text == barangay,
                selectedTileColor: const Color(0xFF2E7D32).withOpacity(0.1),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2E7D32),
              const Color(0xFF4CAF50),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and Title in Upper Left
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FarmFresh',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Join FarmFresh Community',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Registration Title
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                // Registration Form
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Role Selection Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            hint: const Text('Select Role'),
                            decoration: InputDecoration(
                              labelText: 'I want to register as',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'buyer', child: Text('Buyer')),
                              DropdownMenuItem(value: 'seller', child: Text('Seller/Farmer')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value;
                                // Clear category if switching back to buyer
                                if (value == 'buyer') {
                                  _selectedCategory = null;
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a role';
                              }
                              return null;
                            },
                          ),
                          
                          if (_selectedRole == 'seller') ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              hint: const Text('Select Category'),
                              decoration: InputDecoration(
                                labelText: 'Primary Category',
                                prefixIcon: const Icon(Icons.category_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: _categories.map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              )).toList(),
                              onChanged: (value) {
                                setState(() => _selectedCategory = value);
                              },
                              validator: (value) {
                                if (_selectedRole == 'seller' && (value == null || value.isEmpty)) {
                                  return 'Please select a category';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onFieldSubmitted: (_) => _register(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Phone Number Field
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              hintText: '09xxxxxxxx',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onFieldSubmitted: (_) => _register(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              if (value.length != 11) {
                                return 'Phone number must be 11 digits (09xxxxxxxx)';
                              }
                              if (!value.startsWith('09')) {
                                return 'Phone number must start with 09';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Location Field
                          TextFormField(
                            controller: _locationController,
                            readOnly: true,
                            onTap: _showLocationPicker,
                            decoration: InputDecoration(
                              labelText: 'Location',
                              hintText: 'Tap to select barangay',
                              prefixIcon: const Icon(Icons.location_on),
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select your location';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onFieldSubmitted: (_) => _register(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onFieldSubmitted: (_) => _register(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Register',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(color: Colors.grey),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
