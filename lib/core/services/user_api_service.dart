import 'package:dio/dio.dart';
import 'api_service.dart';
import 'api_config.dart';

class UserApiService {
  final ApiService _apiService = ApiService();
  
  // Get Profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.get(ApiConfig.profile);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update Profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? password,
    String? passwordConfirmation,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (password != null) {
        data['password'] = password;
        data['password_confirmation'] = passwordConfirmation;
      }
      
      final response = await _apiService.put(
        ApiConfig.profile,
        data: data,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _apiService.post(ApiConfig.logout);
      await _apiService.clearAuthToken();
    } catch (e) {
      rethrow;
    }
  }
}
