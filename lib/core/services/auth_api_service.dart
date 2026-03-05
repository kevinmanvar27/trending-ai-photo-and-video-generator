import 'api_service.dart';
import 'api_config.dart';

class AuthApiService {
  final ApiService _apiService = ApiService();

  // Login with email and password (direct API login)
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('\n╔════════════════════════════════════════════════════════════════');
      print('║ 🔐 EMAIL LOGIN ATTEMPT');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ Email: $email');
      print('║ Password: ${password.replaceAll(RegExp(r'.'), '*')} (${password.length} chars)');
      print('╚════════════════════════════════════════════════════════════════\n');
      
      final response = await _apiService.post(
        ApiConfig.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      print('\n╔════════════════════════════════════════════════════════════════');
      print('║ ✅ LOGIN SUCCESSFUL');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ Response Status: ${response.statusCode}');
      print('║ Response Data Keys: ${response.data?.keys.toList()}');
      
      // Check if response has the expected structure
      if (response.data == null) {
        print('║ ❌ ERROR: Empty response from server');
        print('╚════════════════════════════════════════════════════════════════\n');
        throw Exception('Empty response from server');
      }

      if (response.data['data'] == null) {
        print('║ ❌ ERROR: Invalid response structure - missing "data" key');
        print('║ Available keys: ${response.data.keys.toList()}');
        print('╚════════════════════════════════════════════════════════════════\n');
        throw Exception('Invalid response structure');
      }

      if (response.data['data']['token'] == null) {
        print('║ ❌ ERROR: No token in response');
        print('║ Data keys: ${response.data['data'].keys.toList()}');
        print('╚════════════════════════════════════════════════════════════════\n');
        throw Exception('No token in response');
      }

      // Save the backend auth token
      final token = response.data['data']['token'];
      final userData = response.data['data']['user'];
      
      print('║ 🔑 Token Received: ${token.substring(0, 20)}...');
      print('║ 👤 User Data:');
      print('║    - ID: ${userData?['id']}');
      print('║    - Name: ${userData?['name']}');
      print('║    - Email: ${userData?['email']}');
      print('║    - Coins: ${userData?['coins']}');
      
      await _apiService.setAuthToken(token);
      
      print('║ ✅ Token saved to SharedPreferences');
      print('╚════════════════════════════════════════════════════════════════\n');

      return response.data;
    } catch (e) {
      print('\n╔════════════════════════════════════════════════════════════════');
      print('║ ❌ LOGIN FAILED');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ Error: $e');
      print('╚════════════════════════════════════════════════════════════════\n');
      rethrow;
    }
  }

  // Register user with email and password
  Future<Map<String, dynamic>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print('\n╔════════════════════════════════════════════════════════════════');
      print('║ 📝 EMAIL REGISTRATION ATTEMPT');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ Name: $name');
      print('║ Email: $email');
      print('║ Password: ${password.replaceAll(RegExp(r'.'), '*')} (${password.length} chars)');
      print('╚════════════════════════════════════════════════════════════════\n');
      
      final response = await _apiService.post(
        ApiConfig.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      print('\n╔════════════════════════════════════════════════════════════════');
      print('║ ✅ REGISTRATION SUCCESSFUL');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ Response Status: ${response.statusCode}');

      // Check if response has the expected structure
      if (response.data == null) {
        print('║ ❌ ERROR: Empty response from server');
        print('╚════════════════════════════════════════════════════════════════\n');
        throw Exception('Empty response from server');
      }

      if (response.data['data'] == null) {
        print('║ ❌ ERROR: Invalid response structure');
        print('╚════════════════════════════════════════════════════════════════\n');
        throw Exception('Invalid response structure');
      }

      if (response.data['data']['token'] == null) {
        print('║ ❌ ERROR: No token in response');
        print('╚════════════════════════════════════════════════════════════════\n');
        throw Exception('No token in response');
      }

      // Save the backend auth token
      final token = response.data['data']['token'];
      final userData = response.data['data']['user'];
      
      print('║ 🔑 Token Received: ${token.substring(0, 20)}...');
      print('║ 👤 User Data:');
      print('║    - ID: ${userData?['id']}');
      print('║    - Name: ${userData?['name']}');
      print('║    - Email: ${userData?['email']}');
      
      await _apiService.setAuthToken(token);
      
      print('║ ✅ Token saved to SharedPreferences');
      print('╚════════════════════════════════════════════════════════════════\n');

      return response.data;
    } catch (e) {
      print('\n╔════════════════════════════════════════════════════════════════');
      print('║ ❌ REGISTRATION FAILED');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ Error: $e');
      print('╚════════════════════════════════════════════════════════════════\n');
      rethrow;
    }
  }

  // Login with Google ID Token
  // This method sends the Google ID token to backend for authentication
  // Backend will verify the token with Google and create/login the user
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String? referralCode,
  }) async {
    try {
      print('\n╔════════════════════════════════════════════════════════════════');
      print('║ 🔐 GOOGLE LOGIN ATTEMPT');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ ID Token Length: ${idToken.length} characters');
      if (referralCode != null) {
        print('║ Referral Code: $referralCode');
      }
      print('╚════════════════════════════════════════════════════════════════\n');
      
      final Map<String, dynamic> requestData = {
        'id_token': idToken,
        'device_name': 'Flutter App',
      };
      
      if (referralCode != null && referralCode.isNotEmpty) {
        requestData['referral_code'] = referralCode;
      }
      
      final response = await _apiService.post(
        ApiConfig.googleLogin,
        data: requestData,
      );

      print('\n╔════════════════════════════════════════════════════════════════');
      print('║ ✅ GOOGLE LOGIN SUCCESSFUL');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ Response Status: ${response.statusCode}');
      print('║ Response Data Keys: ${response.data?.keys.toList()}');
      
      // Check if response has the expected structure
      if (response.data == null) {
        print('║ ❌ ERROR: Empty response from server');
        print('╚════════════════════════════════════════════════════════════════\n');
        throw Exception('Empty response from server');
      }

      if (response.data['data'] == null) {
        print('║ ❌ ERROR: Invalid response structure - missing "data" key');
        print('║ Available keys: ${response.data.keys.toList()}');
        print('╚════════════════════════════════════════════════════════════════\n');
        throw Exception('Invalid response structure');
      }

      if (response.data['data']['token'] == null) {
        print('║ ❌ ERROR: No token in response');
        print('║ Data keys: ${response.data['data'].keys.toList()}');
        print('╚════════════════════════════════════════════════════════════════\n');
        throw Exception('No token in response');
      }

      // Save the backend auth token
      final token = response.data['data']['token'];
      final userData = response.data['data']['user'];
      final isNewUser = response.data['data']['is_new_user'] ?? false;
      final bonusCoins = response.data['data']['bonus_coins_received'];
      
      print('║ 🔑 Token Received: ${token.substring(0, 20)}...');
      print('║ 👤 User Data:');
      print('║    - ID: ${userData?['id']}');
      print('║    - Name: ${userData?['name']}');
      print('║    - Email: ${userData?['email']}');
      print('║    - Referral Coins: ${userData?['referral_coins']}');
      print('║ 🆕 Is New User: $isNewUser');
      if (bonusCoins != null) {
        print('║ 🎁 Bonus Coins Received: $bonusCoins');
      }
      
      await _apiService.setAuthToken(token);
      
      print('║ ✅ Token saved to SharedPreferences');
      print('╚════════════════════════════════════════════════════════════════\n');

      return response.data;
    } catch (e) {
      print('\n╔════════════════════════════════════════════════════════════════');
      print('║ ❌ GOOGLE LOGIN FAILED');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ Error: $e');
      print('╚════════════════════════════════════════════════════════════════\n');
      rethrow;
    }
  }

  // Register user with backend after Firebase registration
  Future<Map<String, dynamic>> registerWithBackend({
    required String name,
    required String email,
    required String firebaseUid,
  }) async {
    try {
      // Note: This method requires Firebase Auth to be properly initialized
      // Get Firebase ID token would go here
      throw UnimplementedError('Firebase Auth integration required');
    } catch (e) {
      rethrow;
    }
  }

  // Sync Firebase login with backend
  Future<Map<String, dynamic>> syncFirebaseLogin({
    required String email,
    required String firebaseUid,
  }) async {
    try {
      // Note: This method requires Firebase Auth to be properly initialized
      throw UnimplementedError('Firebase Auth integration required');
    } catch (e) {
      rethrow;
    }
  }

  // Get or create backend token for Firebase user
  Future<String?> getBackendToken() async {
    try {
      // Check if we already have a token
      final existingToken = _apiService.authToken;
      if (existingToken != null) {
        return existingToken;
      }
      return null;
    } catch (e) {
      print('Error getting backend token: $e');
      return null;
    }
  }

  // Logout from backend
  Future<void> logout() async {
    try {
      await _apiService.post(ApiConfig.logout);
      await _apiService.clearAuthToken();
    } catch (e) {
      print('Backend logout error: $e');
      // Clear token anyway
      await _apiService.clearAuthToken();
    }
  }
}
