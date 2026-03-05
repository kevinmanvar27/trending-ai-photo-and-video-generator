import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../core/services/unified_auth_service.dart';
import '../../core/services/credits_service.dart';

class SplashController extends GetxController {
  final isCheckingAuth = true.obs;
  final isFetchingCoins = false.obs;
  
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
      
      // Use UnifiedAuthService to check both Firebase and email login
      final unifiedAuth = Get.find<UnifiedAuthService>();
      
      // Add timeout to authentication check
      final isAuthenticated = await unifiedAuth.checkAuthentication()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⏱️ Authentication check timeout - assuming not logged in');
              return false;
            },
          );
      
      if (isAuthenticated) {
        final email = unifiedAuth.getUserEmail();
        final authType = unifiedAuth.isFirebaseUser() ? 'Firebase/Google' : 'Email/Backend';
        debugPrint('✅ User already logged in: $email');
        debugPrint('🔑 Auth Type: $authType');
        
        // Fetch coins from API before navigating
        debugPrint('💰 Fetching user coins...');
        isFetchingCoins.value = true;
        
        try {
          final creditsService = Get.find<CreditsService>();
          
          // Add timeout to prevent app from hanging on network issues
          final success = await creditsService.fetchReferralCoins()
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  debugPrint('⏱️ Coins fetch timeout (5s) - continuing to home screen');
                  return false;
                },
              );
          
          if (success) {
            debugPrint('✅ Coins fetched: ${creditsService.credits.value}');
            debugPrint('📋 Plan: ${creditsService.subscriptionPlanName.value}');
          } else {
            debugPrint('⚠️ Could not fetch coins from API, will retry on home screen');
          }
        } catch (e) {
          debugPrint('❌ Error fetching coins: $e');
          // Continue anyway, coins will be fetched on home screen
        } finally {
          isFetchingCoins.value = false;
        }
        
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
