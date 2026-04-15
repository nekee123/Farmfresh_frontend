
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

import '../models/user.dart';

class AuthService extends ChangeNotifier {
  static const _secureStorage = FlutterSecureStorage();
  User? _currentUser;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

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

  Future<bool> loginBuyer(String phoneNumber, String password) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔐 Attempting buyer login with phone: $phoneNumber');
      
      final loginData = {
        'phone_number': phoneNumber,
        'password': password,
      };

      print('📤 Sending login data: $loginData');
      final response = await ApiService.loginBuyer(loginData);

      print('📥 Response received: success=${response.success}, error=${response.error}');
      if (response.data != null) {
        print('📊 User data: ${response.data}');
      }

      if (response.success && response.data != null) {
        // Backend returns: {uid, name, phone_number}
        final userData = response.data!;
        _currentUser = User(
          uid: userData.uid,
          name: userData.name,
          phoneNumber: userData.phoneNumber,
          userType: 'consumer',
        );
        
        print('✅ Login successful for user: ${_currentUser!.name}');
        
        await _saveUserSession(
          uid: _currentUser!.uid,
          name: _currentUser!.name,
          phoneNumber: _currentUser!.phoneNumber,
          role: 'consumer',
        );

        notifyListeners();
        return true;
      } else {
        print('❌ Login failed: ${response.error}');
        _setError(response.error ?? 'Login failed');
        return false;
      }
    } catch (e) {
      print('💥 Login exception: $e');
      _setError('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginSeller(String phoneNumber, String password) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔐 Attempting seller login with phone: $phoneNumber');
      
      final loginData = {
        'phone_number': phoneNumber,
        'password': password,
      };

      print('📤 Sending seller login data: $loginData');
      final response = await ApiService.loginSeller(loginData);
      print('📥 Seller login response: success=${response.success}, error=${response.error}');
      if (response.data != null) {
        print('📊 Seller user data: ${response.data}');
      }

      if (response.success && response.data != null) {
        // Backend returns: {uid, name, phone_number}
        final userData = response.data!;
        _currentUser = User(
          uid: userData.uid,
          name: userData.name,
          phoneNumber: userData.phoneNumber, // User.fromJson already handles both field names
          userType: 'farmer',
        );
        
        print('✅ Login successful for seller: ${_currentUser!.name}');
        
        await _saveUserSession(
          uid: _currentUser!.uid,
          name: _currentUser!.name,
          phoneNumber: _currentUser!.phoneNumber,
          role: 'farmer',
        );

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

  Future<bool> registerBuyer(String name, String phoneNumber, String password, String location) async {
    _setLoading(true);
    _clearError();

    try {
      final registerData = {
        'full_name': name,
        'phone_number': phoneNumber,
        'password': password,
        'confirm_password': password,
        'location': location,
      };

      final response = await ApiService.registerBuyer(registerData);

      if (response.success && response.data != null) {
        _currentUser = response.data!;
        
        await _saveUserSession(
          uid: _currentUser!.uid,
          name: _currentUser!.name,
          phoneNumber: _currentUser!.phoneNumber,
          role: 'consumer',
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

  Future<bool> registerSeller(String name, String phoneNumber, String password, String location) async {
    _setLoading(true);
    _clearError();

    try {
      final registerData = {
        'name': name,
        'phone_number': phoneNumber,
        'password': password,
        'confirm_password': password,
        'location': location,
      };

      print('🔐 Attempting seller registration with data: $registerData');
      final response = await ApiService.registerSeller(registerData);
      print('📥 Seller registration response: success=${response.success}, error=${response.error}');

      if (response.success && response.data != null) {
        _currentUser = response.data!;
        
        await _saveUserSession(
          uid: _currentUser!.uid,
          name: _currentUser!.name,
          phoneNumber: _currentUser!.phoneNumber,
          role: 'farmer',
          location: _currentUser!.location,
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

  Future<void> _saveUserSession({
    required String uid,
    required String name,
    required String phoneNumber,
    required String role,
    String? location,
    String? profilePicture,
  }) async {
    await _secureStorage.write(key: 'user_uid', value: uid);
    await _secureStorage.write(key: 'user_name', value: name);
    await _secureStorage.write(key: 'user_phone', value: phoneNumber);
    await _secureStorage.write(key: 'user_role', value: role);
    if (location != null) {
      await _secureStorage.write(key: 'user_location', value: location);
    }
    if (profilePicture != null) {
      await _secureStorage.write(key: 'user_profile_picture', value: profilePicture);
    }
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

      // Update secure storage
      await _saveUserSession(
        uid: _currentUser!.uid,
        name: _currentUser!.name,
        phoneNumber: _currentUser!.phoneNumber,
        role: _currentUser!.userType,
        location: _currentUser!.location,
        profilePicture: _currentUser!.profilePicture,
      );

      notifyListeners();
    }
  }

  Future<void> loadUserSession() async {
    try {
      final uid = await _secureStorage.read(key: 'user_uid');
      final name = await _secureStorage.read(key: 'user_name');
      final phoneNumber = await _secureStorage.read(key: 'user_phone');
      final role = await _secureStorage.read(key: 'user_role');
      final location = await _secureStorage.read(key: 'user_location');
      final profilePicture = await _secureStorage.read(key: 'user_profile_picture');

      if (uid != null && name != null && phoneNumber != null && role != null) {
        _currentUser = User(
          uid: uid,
          name: name,
          phoneNumber: phoneNumber,
          location: location,
          profilePicture: profilePicture,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userType: role,
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

    await _secureStorage.write(key: 'user_name', value: updated.name);
    await _secureStorage.write(key: 'user_phone', value: updated.phoneNumber);
    if (updated.location != null) {
      await _secureStorage.write(key: 'user_location', value: updated.location);
    }
    if (updated.profilePicture != null) {
      await _secureStorage.write(key: 'user_profile_picture', value: updated.profilePicture);
    }

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
      // Update local user data first for immediate UI update
      await updateLocalUserProfile(
        name: name,
        phoneNumber: phoneNumber,
        location: location,
        profilePicture: profileImagePath,
      );

      // TODO: Add API call to update profile on backend
      // For now, just update local storage
      print('✅ Profile updated locally: name=$name, phone=$phoneNumber, location=$location');
      
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
