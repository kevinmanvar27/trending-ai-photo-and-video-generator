import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../core/services/credits_service.dart';
import '../../core/services/referral_redeem_service.dart';
import 'dart:async';

class MainController extends GetxController with WidgetsBindingObserver {
  final currentIndex = 0.obs;
  final CreditsService _creditsService = Get.find<CreditsService>();
  final ReferralRedeemService _redeemService = Get.find<ReferralRedeemService>();
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    debugPrint('✅ MainController onInit - currentIndex: ${currentIndex.value}');
    
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    // Start periodic refresh (every 2 minutes)
    _startPeriodicRefresh();
  }

  @override
  void onReady() {
    super.onReady();
    debugPrint('✅ MainController onReady - currentIndex: ${currentIndex.value}');
    
    // Try to redeem pending referrals on app start
    _redeemService.redeemAllPendingReferrals().catchError((e) {
      debugPrint('⚠️ Error auto-redeeming on app start: $e');
      return false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - refresh coins and redeem referrals
      debugPrint('📱 App resumed - refreshing coins and checking referrals...');
      _refreshCoins();
      _redeemService.redeemAllPendingReferrals().catchError((e) {
        debugPrint('⚠️ Error auto-redeeming on app resume: $e');
        return false;
      });
    }
  }

  void _startPeriodicRefresh() {
    // Refresh coins every 2 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      debugPrint('⏰ Periodic refresh triggered');
      _refreshCoins();
    });
  }

  Future<void> _refreshCoins() async {
    try {
      if (_creditsService.needsRefresh()) {
        debugPrint('🔄 Refreshing coins from API...');
        await _creditsService.fetchReferralCoins();
        debugPrint('✅ Coins refreshed: ${_creditsService.credits.value}');
      } else {
        debugPrint('⏭️ Skipping refresh - coins are fresh');
      }
    } catch (e) {
      debugPrint('❌ Error refreshing coins: $e');
    }
  }

  void changeTab(int index) {
    debugPrint('📱 Changing tab from ${currentIndex.value} to $index');
    currentIndex.value = index;
    
    // Refresh coins and redeem referrals when switching to profile tab
    if (index == 3) {
      _refreshCoins();
      _redeemService.redeemAllPendingReferrals().catchError((e) {
        debugPrint('⚠️ Error auto-redeeming on tab switch: $e');
        return false;
      });
    }
  }

  @override
  void onClose() {
    debugPrint('🔴 MainController onClose');
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
