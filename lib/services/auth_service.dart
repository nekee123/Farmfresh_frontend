
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

import '../models/user.dart';

class AuthService extends ChangeNotifier {
  static const _secureStorage = FlutterSecureStorage();
  User? _currentUser;
  String? _errorMessage;
  String? _token;

  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  String? get token => _token;

  bool isAdmin() => _currentUser?.userType == 'admin';
  bool isSeller() => _currentUser?.userType == 'seller' || _currentUser?.userType == 'farmer';
  bool isBuyer() => _currentUser?.userType == 'buyer' || _currentUser?.userType == 'consumer';
  String? getUserRole() => _currentUser?.userType;

  void _setLoading(bool loading) {
    // Could add loading state management here if needed
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> login(String phoneNumber, String password) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔐 Attempting unified login for: $phoneNumber');
      
      final loginData = {
        'phone_number': phoneNumber,
        'password': password,
      };

      final response = await ApiService.login(loginData);

      if (response.success && response.data != null) {
        final data = response.data!;
        final token = data['access_token'];
        final userData = data['user'];
        
        final userId = userData['uid'].toString();
        final role = userData['role'];
        final userName = userData['full_name'] ?? userData['name'] ?? 'User';
        final userLocation = userData['location'] ?? '';
        final userProfilePicture = userData['profile_picture'];
        
        // Set token in ApiService for future requests
        if (token != null) {
          _token = token;
          ApiService.setToken(token);
        }
        
        // Initialize user object
        _currentUser = User(
          uid: userId,
          name: userName,
          phoneNumber: phoneNumber,
          userType: role,
          location: userLocation,
          profilePicture: userProfilePicture,
        );
        
        print('✅ Login successful. Role: $role, Name: $userName');
        
        // Save to secure storage
        await _secureStorage.write(key: 'access_token', value: token ?? '');
        await _secureStorage.write(key: 'user_id', value: userId);
        await _secureStorage.write(key: 'user_role', value: role);
        await _secureStorage.write(key: 'user_phone', value: phoneNumber);
        await _secureStorage.write(key: 'user_name', value: userName);
        await _secureStorage.write(key: 'user_location', value: userLocation);
        if (userProfilePicture != null) {
          await _secureStorage.write(key: 'user_profile_picture', value: userProfilePicture);
        }

        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Keep these for backward compatibility
  Future<bool> loginBuyer(String phoneNumber, String password) => login(phoneNumber, password);
  Future<bool> loginSeller(String phoneNumber, String password) => login(phoneNumber, password);

  Future<bool> register(String name, String phoneNumber, String password, String location, {String role = 'buyer', String? profilePicture}) async {
    _setLoading(true);
    _clearError();

    try {
      final registerData = {
        'phone_number': phoneNumber,
        'password': password,
        'full_name': name,
        'location': location,
        'role': role,
      };
      
      if (profilePicture != null) {
        registerData['profile_picture'] = profilePicture;
      }

      final response = await ApiService.register(registerData);

      if (response.success && response.data != null) {
        final data = response.data!;
        _currentUser = User(
          uid: data['uid'],
          name: data['full_name'] ?? name,
          phoneNumber: data['phone_number'] ?? phoneNumber,
          userType: data['role'] ?? role,
          location: data['location'] ?? location,
          profilePicture: data['profile_picture'],
        );

        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Keep these for backward compatibility
  Future<bool> registerBuyer(String name, String phoneNumber, String password, String location) async {
    return await register(name, phoneNumber, password, location, role: 'buyer');
  }

  Future<bool> registerSeller(String name, String phoneNumber, String password, String location) async {
    return await register(name, phoneNumber, password, location, role: 'seller');
  }

  Future<void> updateCurrentUser({
    required String name,
    required String phoneNumber,
    String? location,
    String? profilePicture,
  }) async {
    if (_currentUser != null) {
      _currentUser = User(
        uid: _currentUser!.uid,
        name: name,
        phoneNumber: phoneNumber,
        location: location ?? _currentUser!.location,
        profilePicture: profilePicture ?? _currentUser!.profilePicture,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
        userType: _currentUser!.userType,
      );

      notifyListeners();
    }
  }

  Future<void> loadUserSession() async {
    try {
      final token = await _secureStorage.read(key: 'access_token');
      final userId = await _secureStorage.read(key: 'user_id');
      final role = await _secureStorage.read(key: 'user_role');
      final phoneNumber = await _secureStorage.read(key: 'user_phone');
      final userName = await _secureStorage.read(key: 'user_name');
      final userLocation = await _secureStorage.read(key: 'user_location');
      final userProfilePicture = await _secureStorage.read(key: 'user_profile_picture');

      if (token != null && userId != null && role != null) {
        _token = token;
        ApiService.setToken(token);
        
        _currentUser = User(
          uid: userId,
          name: userName ?? 'User',
          phoneNumber: phoneNumber ?? '',
          userType: role,
          location: userLocation,
          profilePicture: userProfilePicture,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user session: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _secureStorage.deleteAll();
      _currentUser = null;
      _token = null;
      ApiService.clearToken();
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Future<void> updateLocalUserProfile({
    String? name,
    String? phoneNumber,
    String? location,
    String? profilePicture,
  }) async {
    if (_currentUser == null) return;

    final updated = User(
      uid: _currentUser!.uid,
      name: name ?? _currentUser!.name,
      phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
      location: location ?? _currentUser!.location,
      profilePicture: profilePicture ?? _currentUser!.profilePicture,
      createdAt: _currentUser!.createdAt,
      updatedAt: DateTime.now(),
      userType: _currentUser!.userType,
    );

    _currentUser = updated;

    // Only update phone number in storage since we're using token-based auth
    await _secureStorage.write(key: 'user_phone', value: updated.phoneNumber);

    notifyListeners();
  }

  Future<void> updateUserProfile({
    required String name,
    required String phoneNumber,
    required String location,
    String? profileImagePath,
  }) async {
    if (_currentUser == null) return;

    try {
      // Call backend API to update profile
      final profileData = {
        'full_name': name,
        'phone_number': phoneNumber,
        'location': location,
      };
      
      if (profileImagePath != null) {
        profileData['profile_picture'] = profileImagePath;
      }
      
      final response = await ApiService.updateProfile(profileData);
      
      if (response.success && response.data != null) {
        // Update local user data with backend response
        await updateLocalUserProfile(
          name: response.data!['full_name'] ?? name,
          phoneNumber: response.data!['phone_number'] ?? phoneNumber,
          location: response.data!['location'] ?? location,
          profilePicture: response.data!['profile_picture'],
        );
      } else {
        throw Exception(response.error ?? 'Failed to update profile');
      }
      
    } catch (e) {
      print('❌ Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return;

    try {
      // TODO: Add API call to change password on backend
      // For now, just simulate success
      print('✅ Password change simulated: current=****, new=****');
      
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));
      
    } catch (e) {
      print('❌ Error changing password: $e');
      throw Exception('Failed to change password: $e');
    }
  }
}
