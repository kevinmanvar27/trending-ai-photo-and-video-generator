import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/services/credits_service.dart';
import '../../core/services/referral_redeem_service.dart';
import '../../core/services/user_api_service.dart';
import '../../core/services/subscription_api_service.dart';
import '../../core/services/unified_auth_service.dart';
import '../../core/services/share_service.dart';
import '../../core/services/referral_api_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/subscription_model.dart';
import '../../routes/app_routes.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CreditsService creditsService = Get.find<CreditsService>();
  final ReferralRedeemService _redeemService = Get.find<ReferralRedeemService>();
  final UserApiService _userApiService = UserApiService();
  final SubscriptionApiService _subscriptionApiService = SubscriptionApiService();
  final UnifiedAuthService _unifiedAuth = Get.find<UnifiedAuthService>();
  final ShareService _shareService = Get.put(ShareService());
  
  final userName = ''.obs;
  final userEmail = ''.obs;
  final isLoading = false.obs;
  final userProfile = Rxn<UserModel>();
  final activeSubscription = Rxn<UserSubscriptionModel>();

  final ThemeController themeController = Get.put(ThemeController());

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    loadUserProfile();
    loadActiveSubscription();
    
    // Try to redeem pending referrals on profile load
    _redeemService.redeemAllPendingReferrals().catchError((e) {
      print('⚠️ Error auto-redeeming on profile load: $e');
      return false;
    });
  }

  void _loadUserData() {
    // Use unified auth to get user data (works for both Firebase and email users)
    final email = _unifiedAuth.getUserEmail();
    final name = _unifiedAuth.getUserName();
    
    if (email != null) {
      userName.value = name ?? 'User';
      userEmail.value = email;
      print('👤 Loaded user data: $name ($email)');
    } else {
      // Fallback to Firebase auth
      final user = _auth.currentUser;
      if (user != null) {
        userName.value = user.displayName ?? 'User';
        userEmail.value = user.email ?? 'No email';
      }
    }
  }

  // Load user profile from API
  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;
      
      print('🔄 Loading user profile...');
      final response = await _userApiService.getProfile();
      
      if (response['data'] == null) {
        throw Exception('Invalid profile response');
      }
      
      print('📦 Profile response data: ${response['data']}');
      
      userProfile.value = UserModel.fromJson(response['data']);
      
      // Update local values
      if (userProfile.value != null) {
        userName.value = userProfile.value!.name;
        userEmail.value = userProfile.value!.email;
        
        print('🎫 Referral Code: ${userProfile.value!.referralCode}');
        print('💰 Referral Coins: ${userProfile.value!.referralCoins}');
        
        // Check if profile includes coins
        if (response['data']['coins'] != null) {
          final coins = response['data']['coins'] as int;
          await creditsService.syncWithBackend(coins);
          print('💰 Coins synced from profile: $coins');
        }
        
        // Check if profile includes active_subscription
        if (userProfile.value!.activeSubscription != null) {
          print('✅ User has active subscription: ${userProfile.value!.activeSubscription!.plan.name}');
        } else {
          print('⚠️ User has no active subscription');
        }
      }
      
      print('✅ User profile loaded successfully');
    } catch (e) {
      print('❌ Error loading user profile: $e');
      // Keep using Firebase data as fallback
    } finally {
      isLoading.value = false;
    }
  }

  // Load active subscription
  Future<void> loadActiveSubscription() async {
    try {
      print('🔄 Loading active subscription...');
      final response = await _subscriptionApiService.getMySubscription();
      
      if (response != null) {
        activeSubscription.value = UserSubscriptionModel.fromJson(response);
        
        // Sync coins from subscription if available
        if (response['remaining_coins'] != null) {
          final coins = response['remaining_coins'] as int;
          await creditsService.syncWithBackend(coins);
          print('💰 Coins synced from subscription: $coins');
        }
        
        print('✅ Active subscription loaded: ${activeSubscription.value?.plan?.name}');
      } else {
        print('⚠️ No active subscription found');
        activeSubscription.value = null;
      }
    } catch (e) {
      print('❌ Error loading active subscription: $e');
      activeSubscription.value = null;
    }
  }

  // Update profile
  Future<void> updateProfile({
    String? name,
    String? email,
    String? password,
    String? passwordConfirmation,
  }) async {
    try {
      isLoading.value = true;
      
      final response = await _userApiService.updateProfile(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      
      // Reload profile
      await loadUserProfile();
    } catch (e) {
      Get.snackbar(
        '❌ Error',
        'Failed to update profile: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      // Logout from backend
      try {
        await _userApiService.logout();
      } catch (e) {
        print('Backend logout error: $e');
      }
      
      // Logout from Firebase
      await _auth.signOut();
      
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Share referral code with friends
  Future<void> shareReferralCode() async {
    await _shareService.shareReferralCode();
  }

  // Refresh profile and coins
  Future<void> refreshProfile() async {
    print('🔄 Refreshing profile and coins...');
    
    // First try to redeem any pending referrals
    try {
      await _redeemService.redeemAllPendingReferrals();
    } catch (e) {
      print('⚠️ Error redeeming referrals during refresh: $e');
    }
    
    // Then refresh all data
    await Future.wait([
      loadUserProfile(),
      loadActiveSubscription(),
      creditsService.fetchReferralCoins(),
    ]);
    print('✅ Profile refreshed successfully');
  }
}
