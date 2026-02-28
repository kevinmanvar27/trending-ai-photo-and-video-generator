import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../routes/app_routes.dart';

class SplashController extends GetxController {
  final isCheckingAuth = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    debugPrint('✅ SplashController onInit called');
  }

  @override
  void onReady() {
    super.onReady();
    debugPrint('✅ SplashController onReady called');
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() async {
    try {
      debugPrint('⏳ Checking authentication status...');
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if user is already logged in
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        debugPrint('✅ User already logged in: ${user.email}');
        debugPrint('🚀 Navigating to home...');
        await Get.offAllNamed(AppRoutes.main);
      } else {
        debugPrint('❌ No user logged in');
        debugPrint('🚀 Navigating to login...');
        await Get.offAllNamed(AppRoutes.login);
      }
      
      isCheckingAuth.value = false;
      debugPrint('✅ Navigation successful!');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Navigation error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Retry once more
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint('🔄 Retrying navigation...');
        await Get.offAllNamed(AppRoutes.login);
        debugPrint('✅ Retry successful!');
      } catch (e2) {
        debugPrint('❌ Retry failed: $e2');
      }
    }
  }
  
  @override
  void onClose() {
    debugPrint('🔴 SplashController onClose called');
    super.onClose();
  }
}
