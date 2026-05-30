import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/consumer_dashboard_screen.dart';
import 'screens/dashboard/farmer_dashboard_screen.dart';
import 'screens/dashboard/admin_dashboard_screen.dart';
import 'screens/profile/consumer_my_profile_screen.dart';
import 'screens/profile/farmer_my_profile_screen.dart';
import 'screens/products/product_list_screen.dart';
import 'screens/products/product_detail_screen.dart';
import 'screens/products/add_product_screen.dart';
import 'screens/orders/consumer_orders_screen.dart';
import 'screens/orders/farmer_orders_screen.dart';
import 'screens/users/admin_users_screen.dart';
import 'screens/buyer/buyer_cart_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize secure storage
  await _initializeSecureStorage();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: const FarmFreshApp(),
    ),
  );
}

Future<void> _initializeSecureStorage() async {
  try {
    // Initialize FlutterSecureStorage for web compatibility
    const storage = FlutterSecureStorage();
    await storage.write(key: 'test', value: 'initialized');
    await storage.delete(key: 'test');
  } catch (e) {
    print('Secure storage initialization: $e');
  }
}

class FarmFreshApp extends StatefulWidget {
  const FarmFreshApp({super.key});

  @override
  State<FarmFreshApp> createState() => _FarmFreshAppState();
}

class _FarmFreshAppState extends State<FarmFreshApp> {
  bool _isSessionLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.loadUserSession();
    if (mounted) {
      setState(() {
        _isSessionLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return MaterialApp(
          title: 'FarmFresh',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.green,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2E7D32),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          home: _isSessionLoading ? _buildLoadingScreen() : _getInitialScreen(authService),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/verify_otp': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              return OtpVerificationScreen(phoneNumber: args['phoneNumber']);
            },
            '/consumer_dashboard': (context) => const ConsumerDashboardScreen(),
            '/farmer_dashboard': (context) => const FarmerDashboardScreen(),
            '/admin_dashboard': (context) => const AdminDashboardScreen(),
            '/consumer_profile': (context) => const ConsumerMyProfileScreen(),
            '/farmer_profile': (context) => const FarmerMyProfileScreen(),
            '/products': (context) => const ProductListScreen(),
            '/orders': (context) => const ConsumerOrdersScreen(),
            '/cart': (context) {
              return const BuyerCartScreen();
            },
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
        ),
      ),
    );
  }

  Widget _getInitialScreen(AuthService authService) {
    final user = authService.currentUser;
    
    if (user == null) {
      return const LoginScreen();
    }
    
    switch (user.userType) {
      case 'consumer':
      case 'buyer':
        return const ConsumerDashboardScreen();
      case 'farmer':
      case 'seller':
        return const FarmerDashboardScreen();
      case 'admin':
        return const AdminDashboardScreen();
      default:
        return const LoginScreen();
    }
  }
}
