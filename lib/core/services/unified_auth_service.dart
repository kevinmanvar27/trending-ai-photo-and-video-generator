import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'api_service.dart';

/// Unified authentication service that handles both Firebase and email/password auth
/// Provides a single interface to check authentication status regardless of login method
class UnifiedAuthService extends GetxService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();
  
  // Observable for authentication state
  final isAuthenticated = false.obs;
  final currentUserEmail = ''.obs;
  final currentUserName = ''.obs;
  final currentUserId = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }
  
  /// Check if user is authenticated (either Firebase or backend token)
  Future<void> _checkAuthStatus() async {
    print('\n╔════════════════════════════════════════════════════════════════');
    print('║ 🔍 CHECKING AUTHENTICATION STATUS');
    print('╠════════════════════════════════════════════════════════════════');
    
    // Check Firebase auth
    final firebaseUser = _firebaseAuth.currentUser;
    print('║ Firebase User: ${firebaseUser?.email ?? 'null'}');
    
    // Check backend token
    await _apiService.ensureTokenLoaded();
    final hasBackendToken = _apiService.authToken != null;
    print('║ Backend Token: ${hasBackendToken ? 'EXISTS (${_apiService.authToken?.substring(0, 20)}...)' : 'null'}');
    
    if (firebaseUser != null) {
      // Firebase user exists (Google login)
      isAuthenticated.value = true;
      currentUserEmail.value = firebaseUser.email ?? '';
      currentUserName.value = firebaseUser.displayName ?? 'User';
      currentUserId.value = firebaseUser.uid;
      
      print('║ ✅ AUTHENTICATED via Firebase/Google');
      print('║ 👤 User Details:');
      print('║    - Email: ${firebaseUser.email}');
      print('║    - Name: ${firebaseUser.displayName}');
      print('║    - UID: ${firebaseUser.uid}');
      print('╚════════════════════════════════════════════════════════════════\n');
    } else if (hasBackendToken) {
      // Backend token exists (Email login)
      isAuthenticated.value = true;
      
      print('║ ✅ AUTHENTICATED via Email/Backend');
      print('║ 🔑 Token: ${_apiService.authToken?.substring(0, 20)}...');
      print('║ 📊 Loading user profile from backend...');
      
      // Load user data from backend profile
      await _loadBackendUserData();
      
      print('║ 👤 User Details:');
      print('║    - Email: ${currentUserEmail.value}');
      print('║    - Name: ${currentUserName.value}');
      print('║    - ID: ${currentUserId.value}');
      print('╚════════════════════════════════════════════════════════════════\n');
    } else {
      isAuthenticated.value = false;
      print('║ ❌ NOT AUTHENTICATED');
      print('║ No Firebase user and no backend token found');
      print('╚════════════════════════════════════════════════════════════════\n');
    }
  }
  
  /// Load user data from backend API when using email login
  Future<void> _loadBackendUserData() async {
    try {
      print('║ 📡 Fetching user profile from backend...');
      final response = await _apiService.get('/profile');
      if (response.data != null && response.data['data'] != null) {
        final userData = response.data['data'];
        currentUserEmail.value = userData['email'] ?? '';
        currentUserName.value = userData['name'] ?? 'User';
        currentUserId.value = userData['id']?.toString() ?? '';
        print('║ ✅ Backend user data loaded successfully');
      } else {
        print('║ ⚠️ Backend response missing user data');
      }
    } catch (e) {
      print('║ ⚠️ Failed to load backend user data: $e');
    }
  }
  
  /// Get current user email (works for both auth types)
  String? getUserEmail() {
    // Try Firebase first
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      return firebaseUser.email;
    }
    
    // Fall back to backend user data
    if (currentUserEmail.value.isNotEmpty) {
      return currentUserEmail.value;
    }
    
    return null;
  }
  
  /// Get current user name (works for both auth types)
  String? getUserName() {
    // Try Firebase first
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      return firebaseUser.displayName ?? 'User';
    }
    
    // Fall back to backend user data
    if (currentUserName.value.isNotEmpty) {
      return currentUserName.value;
    }
    
    return null;
  }
  
  /// Get current user ID (works for both auth types)
  String? getUserId() {
    // Try Firebase first
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      return firebaseUser.uid;
    }
    
    // Fall back to backend user ID
    if (currentUserId.value.isNotEmpty) {
      return currentUserId.value;
    }
    
    return null;
  }
  
  /// Get current user phone (Firebase only)
  String? getUserPhone() {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser?.phoneNumber;
  }
  
  /// Check if user is authenticated
  Future<bool> checkAuthentication() async {
    await _checkAuthStatus();
    return isAuthenticated.value;
  }
  
  /// Check if user is logged in via Firebase (Google)
  bool isFirebaseUser() {
    return _firebaseAuth.currentUser != null;
  }
  
  /// Check if user is logged in via backend (Email)
  bool isBackendUser() {
    return _apiService.authToken != null && _firebaseAuth.currentUser == null;
  }
  
  /// Refresh authentication status (call after login/logout)
  Future<void> refreshAuthStatus() async {
    await _checkAuthStatus();
  }
  
  /// Clear all authentication data
  Future<void> clearAuth() async {
    await _apiService.clearAuthToken();
    await _firebaseAuth.signOut();
    isAuthenticated.value = false;
    currentUserEmail.value = '';
    currentUserName.value = '';
    currentUserId.value = '';
    print('🚪 Authentication cleared');
  }
}
