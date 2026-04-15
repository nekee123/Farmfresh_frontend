import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../models/seller.dart';
import '../models/buyer.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000'; // Your FastAPI server URL
  static const Duration timeout = Duration(seconds: 30);

  // Generic GET request
  static Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
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
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ApiResponse<T>.fromJson(responseData, fromJson);
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
        headers: {'Content-Type': 'application/json'},
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
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
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

  // Update buyer profile
  static Future<ApiResponse<Buyer>> updateBuyerProfile(
    String uid, {
    String? name,
    String? phoneNumber,
    String? location,
    String? profilePicture,
  }) async {
    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (location != null) body['location'] = location;
    if (profilePicture != null) body['profile_picture'] = profilePicture;

    return await put('/api/buyers/$uid/', body, Buyer.fromJson);
  }

  // Update seller profile
  static Future<ApiResponse<Seller>> updateSellerProfile(
    String uid, {
    String? name,
    String? phoneNumber,
    String? location,
    String? profilePicture,
  }) async {
    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (location != null) body['location'] = location;
    if (profilePicture != null) body['profile_picture'] = profilePicture;

    return await put('/api/sellers/$uid/', body, Seller.fromJson);
  }

  // Create review
  static Future<ApiResponse<Map<String, dynamic>>> createReview(
    Map<String, dynamic> reviewData,
  ) async {
    return await post('/api/reviews/', reviewData, (json) => json);
  }

  // ========== AUTHENTICATION ENDPOINTS ==========
  
  // Login Buyer
  static Future<ApiResponse<User>> loginBuyer(
    Map<String, dynamic> loginData,
  ) async {
    try {
      print('🌐 Making POST request to: $baseUrl/api/buyers/login/');
      print('📤 Request body: ${json.encode(loginData)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/buyers/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(loginData),
      );
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final user = User.fromJson(data);
        return ApiResponse<User>(
          success: true,
          data: user,
        );
      } else {
        return ApiResponse<User>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('💥 API exception: $e');
      return ApiResponse<User>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Login Seller  
  static Future<ApiResponse<User>> loginSeller(
    Map<String, dynamic> loginData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sellers/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(loginData),
      );
      
      print('📤 Sending seller login request: ${json.encode(loginData)}');
      print('📥 Seller login response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Convert backend response to User object
        final user = User(
          uid: responseData['uid'],
          name: responseData['name'],
          phoneNumber: responseData['phone_number'],
          userType: 'farmer',
        );
        
        return ApiResponse<User>(
          success: true,
          data: user,
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
        
        return ApiResponse<User>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}$errorDetails',
        );
      }
    } catch (e) {
      print('🚨 Network error: $e');
      return ApiResponse<User>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Register Buyer
  static Future<ApiResponse<User>> registerBuyer(
    Map<String, dynamic> registerData,
  ) async {
    return await post('/api/buyers/', registerData, User.fromJson);
  }

  // Register Seller
  static Future<ApiResponse<User>> registerSeller(
    Map<String, dynamic> registerData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sellers/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(registerData),
      );
      
      print('📤 Seller registration request: ${json.encode(registerData)}');
      print('📥 Seller registration response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Convert SellerResponse to User object
        final user = User(
          uid: responseData['uid'],
          name: responseData['name'],
          phoneNumber: responseData['phone_number'],
          userType: 'farmer',
          location: responseData['location'] ?? '',
        );
        
        return ApiResponse<User>(
          success: true,
          data: user,
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
        
        return ApiResponse<User>(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}$errorDetails',
        );
      }
    } catch (e) {
      print('🚨 Network error: $e');
      return ApiResponse<User>(
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
        headers: {'Content-Type': 'application/json'},
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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
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

  // Delete Product
  static Future<ApiResponse<void>> deleteProduct(String productUid) async {
    try {
      final url = Uri.parse('$baseUrl/api/products/$productUid/');
      print('🗑️ Deleting product: $productUid');
      print('🌐 DELETE URL: $url');
      
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
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
        headers: {'Content-Type': 'application/json'},
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

  // Get Buyer Orders
  static Future<ApiResponse<List<Map<String, dynamic>>>> getBuyerOrders(
    String buyerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/buyer/$buyerId/'),
        headers: {'Content-Type': 'application/json'},
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
        headers: {'Content-Type': 'application/json'},
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

  // Get buyer profile
  static Future<ApiResponse<Buyer>> getBuyer(String uid) async {
    return await get('/api/buyers/$uid/', Buyer.fromJson);
  }

  // Get seller profile
  static Future<ApiResponse<Seller>> getSeller(String uid) async {
    return await get('/api/sellers/$uid/', Seller.fromJson);
  }

  // Get seller profile for public view
  static Future<ApiResponse<Seller>> getSellerProfile(String sellerId) async {
    return await get('/api/sellers/$sellerId/profile/', Seller.fromJson);
  }

  // Get seller rating
  static Future<ApiResponse<double>> getSellerRating(String sellerId) async {
    return await get('/api/sellers/$sellerId/rating/', (json) => (json['rating'] ?? 0.0).toDouble());
  }

  // Get seller reviews
  static Future<ApiResponse<List<Map<String, dynamic>>>> getSellerReviews(String sellerId) async {
    return await get('/api/sellers/$sellerId/reviews/', (json) {
      if (json['reviews'] is List) {
        return (json['reviews'] as List).map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return <Map<String, dynamic>>[];
    });
  }
}
