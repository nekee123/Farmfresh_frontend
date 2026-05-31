import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../models/seller.dart';
import '../models/buyer.dart';

class ApiService {
  static const String baseUrl = 'https://farmfbackend-2.onrender.com'; // Your FastAPI server URL
  static const Duration timeout = Duration(seconds: 30);

  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }


  // Generic GET request
  static Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse<T>.fromJson(data, fromJson);
      } else {
        return ApiResponse<T>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Generic POST request
  static Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final String requestBody = json.encode(data);
      print('🚀 POST REQUEST to $endpoint');
      print('📦 PAYLOAD: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: requestBody,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // If the backend doesn't provide a 'success' boolean, we assume true 
        // because the HTTP status is 200/201.
        bool isSuccess = responseData['success'] ?? true;
        
        // If the data is not wrapped in a 'data' field, we use the whole body
        dynamic dataPayload = responseData.containsKey('data') ? responseData['data'] : responseData;

        return ApiResponse<T>(
          success: isSuccess,
          data: fromJson(dataPayload),
          message: responseData['message'] ?? responseData['detail'],
        );
      } else {
        // Try to get detailed error from backend response
        String errorDetails = '';
        try {
          final Map<String, dynamic> errorResponse = json.decode(response.body);
          if (errorResponse.containsKey('detail')) {
            errorDetails = ' - ${errorResponse['detail']}';
          }
          // Also log the full response body for debugging
          print('🚨 Backend error response: ${response.body}');
        } catch (e) {
          // If parsing fails, use generic error and log raw response
          print('🚨 Raw error response: ${response.body}');
        }
        
        return ApiResponse<T>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}$errorDetails',
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Generic DELETE request
  static Future<ApiResponse<void>> delete(
    String endpoint,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Generic PUT request
  static Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: json.encode(data),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ApiResponse<T>.fromJson(responseData, fromJson);
      } else {
        return ApiResponse<T>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Create review
  static Future<ApiResponse<Map<String, dynamic>>> createReview(
    Map<String, dynamic> reviewData,
  ) async {
    try {
      print('📤 Creating review request: ${json.encode(reviewData)}');
      final response = await http.post(
        Uri.parse('$baseUrl/api/reviews/'),
        headers: _getHeaders(),
        body: json.encode(reviewData),
      );
      
      print('📥 Review creation response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: responseData,
        );
      } else {
        String errorDetails = '';
        try {
          final Map<String, dynamic> errorResponse = json.decode(response.body);
          if (errorResponse.containsKey('detail')) {
            errorDetails = ' - ${errorResponse['detail']}';
          }
          print('🚨 Backend error response: ${response.body}');
        } catch (e) {
          print('🚨 Raw error response: ${response.body}');
        }
        
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}$errorDetails',
        );
      }
    } catch (e) {
      print('🚨 Network error creating review: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // ========== AUTHENTICATION ENDPOINTS ==========

  // Verify OTP
  static Future<ApiResponse<Map<String, dynamic>>> verifyOtp(Map<String, dynamic> data) async {
    return await post('/api/auth/verify-otp', data, (json) => json);
  }

  // Resend OTP
  static Future<ApiResponse<Map<String, dynamic>>> resendOtp(Map<String, dynamic> data) async {
    return await post('/api/auth/resend-otp', data, (json) => json);
  }

  // Unified Login
  static Future<ApiResponse<Map<String, dynamic>>> login(
    Map<String, dynamic> loginData,
  ) async {
    try {
      print('🌐 Making POST request to: $baseUrl/api/auth/login');
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _getHeaders(),
        body: json.encode(loginData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
        );
      } else {
        String errorMessage = 'Login failed';
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          if (errorData.containsKey('detail')) {
            errorMessage = errorData['detail'];
          }
        } catch (e) {
          errorMessage = 'Login failed: ${response.statusCode}';
        }
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Unified Register
  static Future<ApiResponse<Map<String, dynamic>>> register(
    Map<String, dynamic> registerData,
  ) async {
    try {
      print('🌐 Making POST request to: $baseUrl/api/auth/register');
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: _getHeaders(),
        body: json.encode(registerData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
        );
      } else {
        // Try to get detailed error from backend response
        String errorDetails = '';
        try {
          final Map<String, dynamic> errorResponse = json.decode(response.body);
          if (errorResponse.containsKey('detail')) {
            errorDetails = ' - ${errorResponse['detail']}';
          }
          print('🚨 Backend error response: ${response.body}');
        } catch (e) {
          print('🚨 Raw error response: ${response.body}');
        }
        
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'Registration failed: ${response.statusCode}$errorDetails',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Update User Profile
  static Future<ApiResponse<Map<String, dynamic>>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      print('🌐 Making PUT request to: $baseUrl/api/auth/profile');
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: _getHeaders(),
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
        );
      } else {
        String errorDetails = '';
        try {
          final Map<String, dynamic> errorResponse = json.decode(response.body);
          if (errorResponse.containsKey('detail')) {
            errorDetails = ' - ${errorResponse['detail']}';
          }
        } catch (_) {}
        
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'Profile update failed${errorDetails}',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // ========== PRODUCT ENDPOINTS ==========
  
  // Create Product
  static Future<ApiResponse<Map<String, dynamic>>> createProduct(
    Map<String, dynamic> productData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/products/'),
        headers: _getHeaders(),
        body: json.encode(productData),
      );
      
      print('📤 Creating product request: ${json.encode(productData)}');
      print('📥 Product creation response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: responseData,
        );
      } else {
        // Try to get detailed error from backend response
        String errorDetails = '';
        try {
          final Map<String, dynamic> errorResponse = json.decode(response.body);
          if (errorResponse.containsKey('detail')) {
            errorDetails = ' - ${errorResponse['detail']}';
          }
          print('🚨 Backend error response: ${response.body}');
        } catch (e) {
          print('🚨 Raw error response: ${response.body}');
        }
        
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}$errorDetails',
        );
      }
    } catch (e) {
      print('🚨 Network error: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get All Products
  static Future<ApiResponse<List<Map<String, dynamic>>>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      print('🌐 Making GET request to: ${Uri.parse('$baseUrl/api/products/')}');
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);
        print('📊 Parsed data type: ${decodedResponse.runtimeType}');
        
        List<Map<String, dynamic>> productsList = [];
        
        if (decodedResponse is List) {
          // Backend returns a direct list of products
          productsList = decodedResponse.map((item) => Map<String, dynamic>.from(item)).toList();
        } else if (decodedResponse is Map<String, dynamic>) {
          // Backend might wrap the list in a 'data' field or 'products' field
          if (decodedResponse['success'] == true && decodedResponse['data'] is List) {
            productsList = (decodedResponse['data'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
          } else if (decodedResponse['products'] is List) {
            productsList = (decodedResponse['products'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
          } else if (decodedResponse['data'] is List) {
            productsList = (decodedResponse['data'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
          }
        }
        
        print('📊 Final products count: ${productsList.length}');
        
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: productsList,
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('🚨 Error in getProducts: $e');
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get Product by UID
  static Future<ApiResponse<Map<String, dynamic>>> getProduct(String productUid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/$productUid/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: Map<String, dynamic>.from(data),
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Delete Product
  static Future<ApiResponse<void>> deleteProduct(String productUid) async {
    try {
      final url = Uri.parse('$baseUrl/api/products/$productUid/');
      print('🗑️ Deleting product: $productUid');
      print('🌐 DELETE URL: $url');
      
      final response = await http.delete(
        url,
        headers: _getHeaders(),
      ).timeout(timeout);
      
      print('📥 Delete response status: ${response.statusCode}');
      // Safely handle response body encoding
      String responseBody;
      try {
        responseBody = response.body;
        print('📥 Delete response body: $responseBody');
      } catch (e) {
        responseBody = '[Encoding error: unable to decode response body]';
        print('⚠️ Response body encoding error: $e');
      }
      print('📥 Delete response reason: ${response.reasonPhrase}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Product deleted successfully');
        return ApiResponse<void>(
          success: true,
        );
      } else {
        print('❌ Delete failed with status: ${response.statusCode}');
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('🚨 Error deleting product: $e');
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Update Product
  static Future<ApiResponse<Map<String, dynamic>>> updateProduct(
    String productUid,
    Map<String, dynamic> productData,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/products/$productUid/'),
        headers: _getHeaders(),
        body: json.encode(productData),
      ).timeout(timeout);
      
      print('📝 Updating product: $productUid');
      print('📤 Update data: ${json.encode(productData)}');
      print('📥 Update response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: responseData,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('🚨 Error updating product: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // ========== ORDER ENDPOINTS ==========
  
  // Create Order
  static Future<ApiResponse<Map<String, dynamic>>> createOrder(
    Map<String, dynamic> orderData,
  ) async {
    return await post('/api/orders/', orderData, (json) => json);
  }

  // Get All Orders
  static Future<ApiResponse<List<Map<String, dynamic>>>> getAllOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<Map<String, dynamic>> orders = [];
        
        if (data is List) {
          orders = data.map((item) => Map<String, dynamic>.from(item)).toList();
        } else if (data is Map<String, dynamic> && data['data'] is List) {
          orders = (data['data'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
        }
        
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: orders,
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get Buyer Orders
  static Future<ApiResponse<List<Map<String, dynamic>>>> getBuyerOrders(
    String buyerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/buyer/$buyerId/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: data.cast<Map<String, dynamic>>(),
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get Seller Orders
  static Future<ApiResponse<List<Map<String, dynamic>>>> getSellerOrders(
    String sellerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/seller/$sellerId/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: data.cast<Map<String, dynamic>>(),
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('🚨 Error in getSellerOrders: $e');
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get seller rating
  static Future<ApiResponse<double>> getSellerRating(String sellerId) async {
    return await get('/api/sellers/$sellerId/rating/', (json) => (json['rating'] ?? 0.0).toDouble());
  }

  // ========== ADMIN STATISTICS ENDPOINTS ==========

  // Get total users count
  static Future<ApiResponse<int>> getTotalUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/stats/users/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse<int>(
          success: true,
          data: data['count'] ?? 0,
        );
      } else {
        return ApiResponse<int>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<int>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get total products count
  static Future<ApiResponse<int>> getTotalProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/stats/products/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse<int>(
          success: true,
          data: data['count'] ?? 0,
        );
      } else {
        return ApiResponse<int>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<int>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get total orders count
  static Future<ApiResponse<int>> getTotalOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/stats/orders/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse<int>(
          success: true,
          data: data['count'] ?? 0,
        );
      } else {
        return ApiResponse<int>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<int>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get total farmers count
  static Future<ApiResponse<int>> getTotalFarmers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/stats/farmers/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse<int>(
          success: true,
          data: data['count'] ?? 0,
        );
      } else {
        return ApiResponse<int>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<int>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get all users for admin
  static Future<ApiResponse<List<Map<String, dynamic>>>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/users'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: data.map((item) => Map<String, dynamic>.from(item)).toList(),
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // ========== USER MANAGEMENT ENDPOINTS ==========

  // Approve user
  static Future<ApiResponse<void>> approveUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/users/$userId/approve'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Block user
  static Future<ApiResponse<void>> blockUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/users/$userId/block'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Unblock user
  static Future<ApiResponse<void>> unblockUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/users/$userId/unblock'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get user ban status
  static Future<ApiResponse<Map<String, dynamic>>> getUserBanStatus(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/users/$userId/ban-status'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: Map<String, dynamic>.from(data),
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Update user ban status
  static Future<ApiResponse<void>> updateUserBanStatus(String userId, bool isBanned) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/users/$userId/ban-status'),
        headers: _getHeaders(),
        body: json.encode({'is_banned': isBanned}),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Delete user
  static Future<ApiResponse<void>> deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/users/$userId'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Confirm Order
  static Future<ApiResponse<void>> confirmOrder(String orderUid) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/orders/$orderUid/confirm/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Reject Order
  static Future<ApiResponse<void>> rejectOrder(String orderUid) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/orders/$orderUid/reject/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Cancel Order
  static Future<ApiResponse<void>> cancelOrder(String orderUid) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/orders/$orderUid/cancel/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Delete Order
  static Future<ApiResponse<void>> deleteOrder(String orderUid) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/orders/$orderUid/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Mark Order as Delivered
  static Future<ApiResponse<void>> markOrderAsDelivered(String orderUid) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/orders/$orderUid/delivered/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get Notifications
  static Future<ApiResponse<List<Map<String, dynamic>>>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: data.cast<Map<String, dynamic>>(),
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Mark Notification as Read
  static Future<ApiResponse<void>> markNotificationAsRead(String notificationUid) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/$notificationUid/read/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Delete Notification
  static Future<ApiResponse<void>> deleteNotification(String notificationUid) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/notifications/$notificationUid/'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get current user profile
  static Future<ApiResponse<Map<String, dynamic>>> getCurrentUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: Map<String, dynamic>.from(data),
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get product reviews
  static Future<ApiResponse<List<Map<String, dynamic>>>> getProductReviews(String productUid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reviews/product/$productUid'),
        headers: _getHeaders(),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<Map<String, dynamic>> reviews = [];
        if (data is List) {
          reviews = data.map((item) => Map<String, dynamic>.from(item)).toList();
        }
        return ApiResponse<List<Map<String, dynamic>>>(success: true, data: reviews);
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(success: false, error: 'Network error: $e');
    }
  }

  // Get product rating summary
  static Future<ApiResponse<Map<String, dynamic>>> getProductRatingSummary(String productUid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reviews/product/$productUid/summary'),
        headers: _getHeaders(),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(success: true, data: data);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(success: false, error: 'Network error: $e');
    }
  }

  // Update a review
  static Future<ApiResponse<Map<String, dynamic>>> updateReview(String reviewUid, Map<String, dynamic> reviewData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/reviews/$reviewUid'),
        headers: _getHeaders(),
        body: json.encode(reviewData),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(success: true, data: data);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(success: false, error: 'Network error: $e');
    }
  }

  // Get seller reviews
  static Future<ApiResponse<List<Map<String, dynamic>>>> getSellerReviews(String sellerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reviews/seller/$sellerId'),
        headers: _getHeaders(),
      ).timeout(timeout);

      print('🌐 Fetching reviews for seller: $sellerId');
      print('📥 Response status: ${response.statusCode}');
       
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        print('📊 Response data type: ${data.runtimeType}');
        
        List<Map<String, dynamic>> reviews = [];
        
        // Handle different response formats
        if (data is List) {
          reviews = data.map((item) => Map<String, dynamic>.from(item)).toList();
        } else if (data is Map<String, dynamic>) {
          if (data['reviews'] is List) {
            reviews = (data['reviews'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
          } else if (data['data'] is List) {
            reviews = (data['data'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
          }
        }
        
        print('📊 Reviews for seller $sellerId: ${reviews.length}');
        
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: reviews,
        );
      } else {
        print('🚨 Failed to fetch reviews: ${response.statusCode}');
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('🚨 Error in getSellerReviews: $e');
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // ========== CHAT ENDPOINTS ==========
  
  // Get messages between two users
  static Future<ApiResponse<List<Map<String, dynamic>>>> getMessages(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/$userId'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: data.cast<Map<String, dynamic>>(),
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Send a message
  static Future<ApiResponse<Map<String, dynamic>>> sendMessage(Map<String, dynamic> messageData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/messages/'),
        headers: _getHeaders(),
        body: json.encode(messageData),
      ).timeout(timeout);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get conversations for current user
  static Future<ApiResponse<List<Map<String, dynamic>>>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/conversations'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: data.cast<Map<String, dynamic>>(),
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Mark message as read
  static Future<ApiResponse<void>> markMessageAsRead(String messageUid) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/messages/$messageUid/read'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // ========== FAVORITE ENDPOINTS ==========

  // Check if product is favorited
  static Future<ApiResponse<bool>> isProductFavorited(String productUid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/favorite/check/$productUid'),
        headers: _getHeaders(),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse<bool>(
          success: true,
          data: data['is_favorited'] ?? false,
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          error: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<bool>(success: false, error: e.toString());
    }
  }

  // Add to favorites
  static Future<ApiResponse<void>> addToFavorites(String productUid) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/orders/favorite/$productUid'),
        headers: _getHeaders(),
      ).timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(success: false, error: e.toString());
    }
  }

  // Remove from favorites
  static Future<ApiResponse<void>> removeFromFavorites(String productUid) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/orders/favorite/$productUid'),
        headers: _getHeaders(),
      ).timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(success: false, error: e.toString());
    }
  }

  // Get list of favorited products
  static Future<ApiResponse<List<Map<String, dynamic>>>> getFavorites() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/get_favorites'),
        headers: _getHeaders(),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: data.cast<Map<String, dynamic>>(),
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get active deals
  static Future<ApiResponse<List<Map<String, dynamic>>>> getActiveDeals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reviews/deals'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      print('🌐 GET Deals Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<Map<String, dynamic>> deals = [];
        
        if (decoded is List) {
          deals = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            deals = (decoded['data'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
          } else if (decoded['deals'] is List) {
            deals = (decoded['deals'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
          } else {
            deals = [decoded];
          }
        }

        // Filter for active ones only
        final activeDeals = deals.where((d) => d['status']?.toString().toLowerCase() == 'active').toList();

        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: activeDeals,
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get all deals (for admin)
  static Future<ApiResponse<List<Map<String, dynamic>>>> getAllDeals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reviews/deals'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<Map<String, dynamic>> deals = [];
        
        if (decoded is List) {
          deals = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            deals = (decoded['data'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
          } else if (decoded['deals'] is List) {
            deals = (decoded['deals'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
          }
        }
        
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: deals,
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Create deal
  static Future<ApiResponse<Map<String, dynamic>>> createDeal(Map<String, dynamic> dealData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/deals'),
        headers: _getHeaders(),
        body: json.encode(dealData),
      ).timeout(timeout);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: responseData,
        );
      } else {
        String errorDetails = '';
        try {
          final Map<String, dynamic> errorResponse = json.decode(response.body);
          if (errorResponse.containsKey('detail')) {
            errorDetails = ' - ${errorResponse['detail']}';
          }
        } catch (_) {}
        
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'HTTP ${response.statusCode}$errorDetails',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Delete deal
  static Future<ApiResponse<void>> deleteDeal(String dealId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/deals/$dealId'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<void>(success: true);
      } else {
        return ApiResponse<void>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get seller categories
  static Future<ApiResponse<Map<String, dynamic>>> getSellerCategories(String sellerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/seller/$sellerId/category'),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      print('🌐 GET Seller Categories Status: ${response.statusCode}');
      print('📥 GET Seller Categories Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: Map<String, dynamic>.from(data),
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Search items (products, sellers, buyers)
  static Future<ApiResponse<List<Map<String, dynamic>>>> searchItems(String query, String searchType) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search').replace(
          queryParameters: {
            'query': query,
            'search_type': searchType,
          },
        ),
        headers: _getHeaders(),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: data.map((item) => Map<String, dynamic>.from(item)).toList(),
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }
}
