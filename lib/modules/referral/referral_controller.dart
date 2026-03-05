import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/referral_api_service.dart';
import '../../core/services/credits_service.dart';
import '../../routes/app_routes.dart';

class ReferralController extends GetxController {
  final ReferralApiService _referralApiService = ReferralApiService();
  final CreditsService _creditsService = Get.find<CreditsService>();
  
  final referralCodeController = TextEditingController();
  final isProcessing = false.obs;
  final isValidating = false.obs;
  final errorMessage = ''.obs;
  final validatedReferrer = ''.obs;
  final bonusCoins = 0.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadBonusAmount();
    
    // Auto-validate when user types
    referralCodeController.addListener(_onReferralCodeChanged);
  }
  
  @override
  void onClose() {
    // Remove listener before disposing
    referralCodeController.removeListener(_onReferralCodeChanged);
    referralCodeController.dispose();
    super.onClose();
  }
  
  // Load bonus coins amount from backend config
  Future<void> _loadBonusAmount() async {
    try {
      // You can fetch from app config API if available
      // For now, using default value
      bonusCoins.value = 50; // Default bonus
    } catch (e) {
      debugPrint('❌ Error loading bonus amount: $e');
    }
  }
  
  // Auto-validate referral code as user types
  void _onReferralCodeChanged() {
    final code = referralCodeController.text.trim();
    
    if (code.length >= 6) {
      // Debounce validation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (referralCodeController.text.trim() == code) {
          _validateCode(code);
        }
      });
    } else {
      validatedReferrer.value = '';
      errorMessage.value = '';
    }
  }
  
  // Validate referral code
  Future<void> _validateCode(String code) async {
    if (code.isEmpty) return;
    
    try {
      isValidating.value = true;
      errorMessage.value = '';
      validatedReferrer.value = '';
      
      final response = await _referralApiService.validateReferralCode(code);
      
      if (response != null && response['success'] == true) {
        validatedReferrer.value = response['data']['referrer_name'] ?? 'Someone';
        bonusCoins.value = response['data']['bonus_coins'] ?? 50;
        debugPrint('✅ Valid referral code: $code');
      } else {
        errorMessage.value = 'Invalid referral code';
        debugPrint('❌ Invalid referral code: $code');
      }
    } catch (e) {
      errorMessage.value = 'Invalid referral code';
      debugPrint('❌ Error validating code: $e');
    } finally {
      isValidating.value = false;
    }
  }
  
  // Apply referral code and get bonus
  Future<void> applyReferralCode() async {
    final code = referralCodeController.text.trim();
    
    if (code.isEmpty) {
      errorMessage.value = 'Please enter a referral code';
      return;
    }
    
    try {
      isProcessing.value = true;
      errorMessage.value = '';
      
      debugPrint('📤 Applying referral code: $code');
      
      final response = await _referralApiService.applyReferralCode(code);
      
      if (response != null && response['success'] == true) {
        final coinsReceived = response['data']['bonus_coins_awarded'] ?? 0;
        final totalCoins = response['data']['total_referral_coins'] ?? 0;
        
        debugPrint('✅ Referral code applied successfully');
        debugPrint('🎁 Bonus coins received: $coinsReceived');
        debugPrint('💰 Total referral coins: $totalCoins');
        
        // Fetch ALL coins (referral + subscription if any)
        await _creditsService.fetchAllCoins();
        debugPrint('✅ All coins refreshed');
        
        // Show success message with coins
        Get.snackbar(
          '🎉 Success!',
          'You received $coinsReceived bonus coins! Total: ${_creditsService.credits.value} coins',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        
        // Wait a bit before navigation
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // Navigate to main screen (with bottom navigation)
        Get.offAllNamed(AppRoutes.main);
      } else {
        errorMessage.value = response?['message'] ?? 'Failed to apply referral code';
        
        Get.snackbar(
          '❌ Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('❌ Error applying referral code: $e');
      errorMessage.value = 'Failed to apply referral code';
      
      Get.snackbar(
        '❌ Error',
        'Failed to apply referral code. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isProcessing.value = false;
    }
  }
  
  // Skip referral code entry
  void skip() {
    debugPrint('⏭️ User skipped referral code entry');
    
    // Navigate to main screen (with bottom navigation)
    Get.offAllNamed(AppRoutes.main);
  }
}
