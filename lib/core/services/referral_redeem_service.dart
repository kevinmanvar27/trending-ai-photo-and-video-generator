import 'package:get/get.dart';
import 'referral_api_service.dart';
import 'credits_service.dart';

/// Service to handle automatic redemption of pending referral coins
/// Integrates with CreditsService to refresh coins after redemption
class ReferralRedeemService extends GetxService {
  final ReferralApiService _referralApi = ReferralApiService();
  final pendingCount = 0.obs;
  final isRedeeming = false.obs;
  
  /// Redeem all pending referral coins
  /// Returns true if any coins were redeemed, false otherwise
  Future<bool> redeemAllPendingReferrals() async {
    if (isRedeeming.value) {
      print('⚠️ Redemption already in progress, skipping...');
      return false;
    }
    
    try {
      isRedeeming.value = true;
      print('💰 [ReferralRedeemService] Starting auto-redemption...');
      
      final result = await _referralApi.redeemAllPendingReferrals();
      
      if (result['success'] == true) {
        final coinsEarned = result['data']?['coins_earned'] ?? 0;
        final redeemed = result['data']?['referrals_redeemed'] ?? 0;
        
        if (coinsEarned > 0) {
          print('✅ [ReferralRedeemService] Redeemed $redeemed referrals for $coinsEarned coins');
          
          // Refresh credits to reflect new balance
          try {
            final creditsService = Get.find<CreditsService>();
            await creditsService.fetchReferralCoins();
            print('💰 Credits refreshed after redemption');
          } catch (e) {
            print('⚠️ Could not refresh credits: $e');
          }
          
          return true;
        } else {
          print('ℹ️ [ReferralRedeemService] No pending referrals to redeem');
          return false;
        }
      }
      
      return false;
    } catch (e) {
      print('❌ [ReferralRedeemService] Error redeeming referrals: $e');
      return false;
    } finally {
      isRedeeming.value = false;
    }
  }
  
  /// Get count of pending referrals (for UI display)
  Future<int> getPendingReferralsCount() async {
    try {
      final referrals = await _referralApi.getReferralList();
      final pending = referrals.where((ref) => ref['status'] == 'pending').length;
      pendingCount.value = pending;
      return pending;
    } catch (e) {
      print('❌ Error getting pending referrals count: $e');
      return 0;
    }
  }
}
