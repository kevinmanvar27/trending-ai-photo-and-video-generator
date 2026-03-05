import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/credits_service.dart';
import '../login/login_view.dart';
import '../login/login_binding.dart';

class RegisterController extends GetxController {
  final AuthApiService _authApiService = AuthApiService();
  
  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  // Observables
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  // Register with email and password
  Future<void> register() async {
    // Validate inputs
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

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

    // Validate email format
    if (!GetUtils.isEmail(emailController.text.trim())) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
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

    if (passwordController.text.length < 8) {
      Get.snackbar(
        'Error',
        'Password must be at least 8 characters',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar(
        'Error',
        'Passwords do not match',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      debugPrint('Starting registration...');

      // Call backend API register
      final response = await _authApiService.registerWithEmail(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      debugPrint('✅ Registration successful');
      debugPrint('Response: $response');

      // Clear the token so user has to login
      // (Backend saved token during registration, but we want user to login explicitly)
      try {
        final apiService = Get.find<ApiService>();
        await apiService.clearAuthToken();
        debugPrint('✅ Token cleared - user must login');
      } catch (e) {
        debugPrint('⚠️ Failed to clear token: $e');
      }

      // Don't sync credits here - user will login first
      // Credits will sync after login

      isLoading.value = false;
      
      // Show success message
      Get.snackbar(
        'Success',
        'Registration successful! Please login to continue.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Navigate to login screen after a short delay to allow UI to settle
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Use Get.off instead of Get.offAllNamed to avoid dispose error
      Get.off(() => const LoginView(), binding: LoginBinding());
      
    } catch (e) {
      isLoading.value = false;
      debugPrint('Registration error: $e');
      
      String errorMessage = 'Failed to register';
      
      // Parse error message from response
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('email') || errorString.contains('already')) {
        errorMessage = 'This email is already registered';
      } else if (errorString.contains('validation')) {
        errorMessage = 'Please check your input and try again';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection';
      } else if (errorString.contains('timeout')) {
        errorMessage = 'Connection timeout. Please try again';
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }
}
