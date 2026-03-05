import 'dart:io';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../core/services/credits_service.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/unified_auth_service.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Web Client ID from google-services.json (required for backend token verification)
    serverClientId: '858164631228-5r34mv7g4l32dfvei7q7aja4u0p4nsq0.apps.googleusercontent.com',
  );
  final AuthApiService _authApiService = AuthApiService();
  
  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  // Observables
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final loginMode = 'google'.obs; // 'google' or 'email'

  @override
  void onInit() {
    super.onInit();
    debugPrint('LoginController initialized');
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void switchLoginMode(String mode) {
    loginMode.value = mode;
  }

  /// Helper to check if user was created in the last 5 minutes (likely a new user)
  bool _isUserCreatedRecently(String? createdAt) {
    if (createdAt == null) return false;
    
    try {
      final createdTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(createdTime);
      
      // If account was created in the last 5 minutes, consider it a new user
      return difference.inMinutes < 5;
    } catch (e) {
      debugPrint('⚠️ Error parsing created_at: $e');
      return false;
    }
  }

  /// ============================================================================
  /// EMAIL LOGIN - Backend API Authentication
  /// ============================================================================
  Future<void> loginWithEmail() async {
    // Validate inputs
    if (emailController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      debugPrint('\n╔════════════════════════════════════════════════════════════════');
      debugPrint('║ 🔐 EMAIL LOGIN STARTED');
      debugPrint('╠════════════════════════════════════════════════════════════════');
      debugPrint('║ Email: ${emailController.text.trim()}');
      debugPrint('╚════════════════════════════════════════════════════════════════\n');

      // Step 1: Login via Backend API
      final response = await _authApiService.loginWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      debugPrint('✅ Backend login successful');
      debugPrint('📦 Response: ${response.keys.toList()}');

      // Step 2: Fetch ALL coins (referral + subscription)
      try {
        final creditsService = Get.find<CreditsService>();
        await creditsService.fetchAllCoins();
        debugPrint('✅ All coins fetched successfully');
      } catch (e) {
        debugPrint('⚠️ Credits fetch failed (non-critical): $e');
      }

      // Step 3: Update unified auth service
      try {
        final unifiedAuth = Get.find<UnifiedAuthService>();
        await unifiedAuth.refreshAuthStatus();
        debugPrint('✅ Unified auth service updated');
      } catch (e) {
        debugPrint('⚠️ Unified auth refresh failed: $e');
      }

      isLoading.value = false;
      
      // Step 4: Check if user is new and should see referral screen
      final userData = response['data'];
      final isNewUser = userData?['is_new_user'] == true || 
                        userData?['user']?['created_at'] != null &&
                        _isUserCreatedRecently(userData['user']['created_at']);
      
      // Step 5: Show success and navigate
      Get.snackbar(
        'Success',
        'Welcome back!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      debugPrint('🚀 Navigating to ${isNewUser ? "referral" : "main"} screen...\n');
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (isNewUser) {
        Get.offAllNamed(AppRoutes.referral);
      } else {
        Get.offAllNamed(AppRoutes.main);
      }
      
    } catch (e) {
      isLoading.value = false;
      debugPrint('\n╔════════════════════════════════════════════════════════════════');
      debugPrint('║ ❌ EMAIL LOGIN FAILED');
      debugPrint('╠════════════════════════════════════════════════════════════════');
      debugPrint('║ Error: $e');
      debugPrint('╚════════════════════════════════════════════════════════════════\n');
      
      String errorMessage = 'Login failed. Please try again.';
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('401') || errorString.contains('unauthorized')) {
        errorMessage = 'Invalid email or password';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorMessage = 'Network error. Check your internet connection';
      } else if (errorString.contains('timeout')) {
        errorMessage = 'Connection timeout. Please try again';
      } else if (errorString.contains('422')) {
        errorMessage = 'Invalid credentials. Please check your email and password';
      }
      
      Get.snackbar(
        'Login Failed',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// ============================================================================
  /// GOOGLE LOGIN - Firebase Authentication
  /// ============================================================================
  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      debugPrint('\n╔════════════════════════════════════════════════════════════════');
      debugPrint('║ 🔐 GOOGLE LOGIN STARTED');
      debugPrint('╚════════════════════════════════════════════════════════════════\n');

      // Step 1: Trigger Google Sign-In
      debugPrint('📱 Opening Google Sign-In dialog...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('⚠️ User canceled Google sign-in');
        isLoading.value = false;
        return;
      }

      debugPrint('✅ Google account selected: ${googleUser.email}');

      // Step 2: Get authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        throw Exception('Failed to get Google authentication tokens');
      }

      debugPrint('✅ Google tokens obtained');
      debugPrint('   - ID Token length: ${googleAuth.idToken!.length} chars');
      debugPrint('   - Access Token length: ${googleAuth.accessToken!.length} chars');
      
      // Print full tokens in console
      debugPrint('\n╔════════════════════════════════════════════════════════════════');
      debugPrint('║ 🔑 FULL ID TOKEN (Copy for Postman):');
      debugPrint('╠════════════════════════════════════════════════════════════════');
      debugPrint(googleAuth.idToken!);
      debugPrint('╠════════════════════════════════════════════════════════════════');
      debugPrint('║ 🔐 FULL ACCESS TOKEN (Copy for Postman):');
      debugPrint('╠════════════════════════════════════════════════════════════════');
      debugPrint(googleAuth.accessToken!);
      debugPrint('╚════════════════════════════════════════════════════════════════\n');

      // Save tokens to file for Postman testing
      try {
        final file = File('google_tokens.txt');
        final timestamp = DateTime.now().toString();
        final content = '''
╔════════════════════════════════════════════════════════════════
║ GOOGLE AUTHENTICATION TOKENS
║ Generated: $timestamp
╠════════════════════════════════════════════════════════════════
║ User Email: ${googleUser.email}
║ User Name: ${googleUser.displayName}
╠════════════════════════════════════════════════════════════════
║ 🔑 ID TOKEN (Full - for Postman):
╠════════════════════════════════════════════════════════════════
${googleAuth.idToken}
╠════════════════════════════════════════════════════════════════
║ 🔐 ACCESS TOKEN (Full - for Postman):
╠════════════════════════════════════════════════════════════════
${googleAuth.accessToken}
╠════════════════════════════════════════════════════════════════
║ Token Lengths:
║   - ID Token: ${googleAuth.idToken!.length} characters
║   - Access Token: ${googleAuth.accessToken!.length} characters
╚════════════════════════════════════════════════════════════════
''';
        await file.writeAsString(content);
        debugPrint('✅ Tokens saved to: ${file.absolute.path}');
      } catch (e) {
        debugPrint('⚠️ Failed to save tokens to file: $e');
      }

      // Step 3: Create Firebase credential and sign in
      debugPrint('🔥 Authenticating with Firebase...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase authentication failed');
      }

      debugPrint('\n╔════════════════════════════════════════════════════════════════');
      debugPrint('║ ✅ FIREBASE AUTHENTICATION SUCCESSFUL');
      debugPrint('╠════════════════════════════════════════════════════════════════');
      debugPrint('║ Firebase UID: ${firebaseUser.uid}');
      debugPrint('║ Email: ${firebaseUser.email}');
      debugPrint('║ Display Name: ${firebaseUser.displayName}');
      debugPrint('║ Email Verified: ${firebaseUser.emailVerified}');
      debugPrint('╚════════════════════════════════════════════════════════════════\n');

      // Step 4: Authenticate with Backend using Google ID Token
      Map<String, dynamic>? backendResponse;
      bool backendAuthSuccess = false;
      
      try {
        debugPrint('\n╔════════════════════════════════════════════════════════════════');
        debugPrint('║ 🔗 BACKEND AUTHENTICATION STARTED');
        debugPrint('╠════════════════════════════════════════════════════════════════');
        debugPrint('║ Sending Google ID token to backend...');
        debugPrint('║ Endpoint: /api/google-login');
        debugPrint('╚════════════════════════════════════════════════════════════════\n');
        
        backendResponse = await _authApiService.loginWithGoogle(
          idToken: googleAuth.idToken!,
        );
        
        if (backendResponse['success'] == true && backendResponse['data']?['token'] != null) {
          final token = backendResponse['data']['token'];
          final user = backendResponse['data']['user'];
          
          debugPrint('\n╔════════════════════════════════════════════════════════════════');
          debugPrint('║ ✅ BACKEND AUTHENTICATION SUCCESSFUL');
          debugPrint('╠════════════════════════════════════════════════════════════════');
          debugPrint('║ 🔑 Bearer Token: ${token.substring(0, 20)}...');
          debugPrint('║ 👤 User ID: ${user['id']}');
          debugPrint('║ 📧 Email: ${user['email']}');
          debugPrint('║ 🪙 Referral Coins: ${user['referral_coins']}');
          debugPrint('║ 🎫 Referral Code: ${user['referral_code']}');
          debugPrint('╚════════════════════════════════════════════════════════════════\n');
          
          backendAuthSuccess = true;
          
          // Fetch ALL coins (referral + subscription)
          try {
            final creditsService = Get.find<CreditsService>();
            await creditsService.fetchAllCoins();
            debugPrint('✅ All coins fetched successfully');
          } catch (e) {
            debugPrint('⚠️ Credits fetch failed (non-critical): $e');
          }
        } else {
          debugPrint('⚠️ Backend response missing token or success flag');
        }
      } catch (e) {
        debugPrint('\n╔════════════════════════════════════════════════════════════════');
        debugPrint('║ ⚠️ BACKEND AUTHENTICATION FAILED');
        debugPrint('╠════════════════════════════════════════════════════════════════');
        debugPrint('║ Error: $e');
        debugPrint('║ Note: User is still authenticated with Firebase');
        debugPrint('║ Backend features (coins, referrals) will not be available');
        debugPrint('╚════════════════════════════════════════════════════════════════\n');
        
        // Show warning to user but don't block login
        Get.snackbar(
          'Warning',
          'Backend connection failed. Some features may be limited.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }

      // Step 5: Update unified auth service
      try {
        final unifiedAuth = Get.find<UnifiedAuthService>();
        await unifiedAuth.refreshAuthStatus();
        debugPrint('✅ Unified auth service updated');
      } catch (e) {
        debugPrint('⚠️ Unified auth refresh failed: $e');
      }

      // Step 6: Try to fetch credits from API (will use backend token if available)
      try {
        final creditsService = Get.find<CreditsService>();
        await creditsService.fetchReferralCoins();
        debugPrint('✅ Credits fetched from API');
      } catch (e) {
        debugPrint('⚠️ Credits fetch failed (non-critical): $e');
      }

      isLoading.value = false;
      
      // Step 7: Check if user is new (check if account was just created)
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      
      // Step 8: Show success and navigate
      Get.snackbar(
        'Success',
        'Welcome ${firebaseUser.displayName ?? 'back'}!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      debugPrint('🚀 Navigating to ${isNewUser ? "referral" : "main"} screen...\n');
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (isNewUser) {
        Get.offAllNamed(AppRoutes.referral);
      } else {
        Get.offAllNamed(AppRoutes.main);
      }
      
    } catch (e) {
      isLoading.value = false;
      debugPrint('\n╔════════════════════════════════════════════════════════════════');
      debugPrint('║ ❌ GOOGLE LOGIN FAILED');
      debugPrint('╠════════════════════════════════════════════════════════════════');
      debugPrint('║ Error: $e');
      debugPrint('╚════════════════════════════════════════════════════════════════\n');
      
      String errorMessage = 'Google sign-in failed. Please try again.';
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('network') || errorString.contains('connection')) {
        errorMessage = 'Network error. Check your internet connection';
      } else if (errorString.contains('timeout')) {
        errorMessage = 'Connection timeout. Please try again';
      } else if (errorString.contains('canceled') || errorString.contains('cancelled')) {
        errorMessage = 'Sign-in was canceled';
      } else if (errorString.contains('sign_in_failed')) {
        errorMessage = 'Google sign-in failed. Please try again';
      }
      
      Get.snackbar(
        'Google Login Failed',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }
}
