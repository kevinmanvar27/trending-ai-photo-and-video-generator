import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/credits_service.dart';
import '../../core/services/razorpay_service.dart';
import '../../core/services/subscription_api_service.dart';
import '../../core/models/subscription_model.dart';
import '../profile/profile_controller.dart';

class SubscriptionController extends GetxController {
  final CreditsService creditsService = Get.find<CreditsService>();
  final SubscriptionApiService _subscriptionApiService = SubscriptionApiService();
  RazorpayService? _razorpayService;
  
  final isProcessing = false.obs;
  final isLoading = false.obs;
  final subscriptionPlans = <SubscriptionPlanModel>[].obs;
  final mySubscription = Rxn<UserSubscriptionModel>();
  final errorMessage = ''.obs;
  
  // Store pending plan for payment callback
  SubscriptionPlanModel? _pendingPlan;

  @override
  void onInit() {
    super.onInit();
    // Initialize Razorpay service
    _razorpayService = Get.find<RazorpayService>();
    if (_razorpayService == null) {
      _razorpayService = Get.put(RazorpayService());
      _razorpayService!.initRazorpay();
    }
    debugPrint('🎮 SubscriptionController initialized with Razorpay');
    
    // Load subscription plans and user's subscription
    loadSubscriptionPlans();
    loadMySubscription();
  }

  @override
  void onClose() {
    super.onClose();
  }

  // Load subscription plans from API
  Future<void> loadSubscriptionPlans() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      debugPrint('📋 Fetching subscription plans from API...');
      debugPrint('🔗 API Endpoint: https://trends.rektech.work/api/subscription/plans');
      
      // Try fetching all plans first (without isActive filter)
      final response = await _subscriptionApiService.getSubscriptionPlans();
      
      debugPrint('📊 Raw API Response: $response');
      debugPrint('📊 Response length: ${response.length}');
      
      subscriptionPlans.value = response
          .map((json) => SubscriptionPlanModel.fromJson(json))
          .toList();
      
      debugPrint('✅ Loaded ${subscriptionPlans.length} subscription plans');
      for (var plan in subscriptionPlans) {
        debugPrint('   📦 ${plan.name} - ₹${plan.price} (${plan.coins} credits) - Active: ${plan.isActive}');
      }
    } catch (e) {
      errorMessage.value = 'Failed to load subscription plans';
      debugPrint('❌ Error loading subscription plans: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load user's active subscription
  Future<void> loadMySubscription() async {
    try {
      final response = await _subscriptionApiService.getMySubscription();
      
      if (response != null) {
        mySubscription.value = UserSubscriptionModel.fromJson(response);
        
        // Update credits service with remaining coins
        if (mySubscription.value != null) {
          creditsService.updateCredits(mySubscription.value!.remainingCoins);
        }
        
        debugPrint('✅ Loaded user subscription: ${mySubscription.value?.plan?.name}');
      } else {
        debugPrint('ℹ️ No active subscription found');
      }
    } catch (e) {
      debugPrint('❌ Error loading user subscription: $e');
    }
  }

  // Subscribe to a plan
  Future<void> subscribeToPlan(SubscriptionPlanModel plan) async {
    try {
      isProcessing.value = true;
      
      // Store pending plan for payment callback
      _pendingPlan = plan;
      
      // Show confirmation dialog
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirm Subscription'),
          content: Text(
            'Subscribe to ${plan.name} for ₹${plan.price.toStringAsFixed(0)}?\n\n'
            'You will get ${plan.coins} credits for ${plan.durationText}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Proceed to Pay'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        debugPrint('💳 Opening payment for plan: ${plan.name}');
        debugPrint('📦 Plan ID: ${plan.id}, Coins: ${plan.coins}, Price: ₹${plan.price}');
        
        // Open Razorpay checkout with callback
        await _razorpayService!.openCheckout(
          credits: plan.coins,
          amountInRupees: plan.price.toInt(),
          isSubscription: true,
          onSuccess: (paymentId, orderId, signature) async {
            await handlePaymentSuccess(paymentId, orderId, signature);
          },
        );
        
        debugPrint('💳 Payment initiated, waiting for callback...');
      } else {
        _pendingPlan = null;
      }
    } catch (e) {
      debugPrint('❌ Error subscribing to plan: $e');
      Get.snackbar(
        '❌ Error',
        'Failed to initiate payment: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      _pendingPlan = null;
    } finally {
      isProcessing.value = false;
    }
  }
  
  // Handle payment success - called after Razorpay payment
  Future<void> handlePaymentSuccess(String paymentId, String orderId, String signature) async {
    if (_pendingPlan == null) {
      debugPrint('⚠️ No pending plan found');
      return;
    }
    
    try {
      debugPrint('✅ Payment successful, activating subscription...');
      debugPrint('💳 Payment Token (ID): $paymentId');
      debugPrint('📦 Order ID: $orderId');
      debugPrint('🔐 Signature: $signature');
      debugPrint('📋 Plan ID: ${_pendingPlan!.id}');
      
      // Call backend API to activate subscription with payment token
      // API expects: { subscription_plan_id, payment_token, payment_method }
      final response = await _subscriptionApiService.subscribe(
        subscriptionPlanId: _pendingPlan!.id,
        paymentToken: paymentId, // Razorpay payment ID as token
        paymentMethod: 'razorpay',
      );
      
      debugPrint('✅ Subscription activated successfully');
      debugPrint('📊 Response: $response');
      
      // Response format:
      // {
      //   "success": true,
      //   "data": {
      //     "subscription": {
      //       "id": 5,
      //       "status": "active",
      //       "plan": { "id": 1, "name": "Basic", "coins": 10 },
      //       "expires_at": null,
      //       "remaining_coins": 10
      //     }
      //   },
      //   "message": "Subscription activated successfully"
      // }
      
      // Reload subscription data
      await loadMySubscription();
      
      // Refresh ALL coins (referral + subscription)
      await creditsService.fetchAllCoins();
      
      // Update profile controller if it exists
      try {
        final profileController = Get.find<ProfileController>();
        await profileController.loadActiveSubscription();
        debugPrint('✅ Profile subscription state updated');
      } catch (e) {
        debugPrint('⚠️ ProfileController not found or error updating: $e');
      }
      
      // Clear pending plan
      _pendingPlan = null;
      
      // Navigate back
      Get.back();
    } catch (e) {
      debugPrint('❌ Error creating subscription: $e');
      Get.snackbar(
        '⚠️ Warning',
        'Payment successful but subscription activation failed. Contact support with payment ID: $paymentId',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 10),
      );
      _pendingPlan = null;
    }
  }

  // Cancel subscription
  Future<void> cancelSubscription() async {
    try {
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Cancel Subscription'),
          content: const Text(
            'Are you sure you want to cancel your subscription?\n\n'
            'You will lose access to premium features.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Yes, Cancel'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        isProcessing.value = true;
        
        await _subscriptionApiService.cancelSubscription();
        
        // Reload subscription data
        await loadMySubscription();
      }
    } catch (e) {
      debugPrint('❌ Error cancelling subscription: $e');
      Get.snackbar(
        '❌ Error',
        'Failed to cancel subscription: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> buyCredits(int credits, int price) async {
    debugPrint('🛒 Buy Credits clicked: $credits credits for ₹$price');
    
    if (isProcessing.value) {
      debugPrint('⚠️ Already processing a payment');
      return;
    }
    
    // Show confirmation dialog
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Text('Buy $credits credits for ₹$price?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Proceed to Pay'),
          ),
        ],
      ),
    );

    debugPrint('💭 User confirmation: $confirm');

    if (confirm == true) {
      isProcessing.value = true;
      
      try {
        debugPrint('🚀 Initiating Razorpay payment...');
        
        if (_razorpayService == null) {
          debugPrint('❌ RazorpayService is null, reinitializing...');
          _razorpayService = Get.put(RazorpayService());
          _razorpayService!.initRazorpay();
        }
        
        // Open Razorpay checkout
        await _razorpayService!.openCheckout(
          credits: credits,
          amountInRupees: price,
        );
        
        debugPrint('✅ Payment initiated successfully');
      } catch (e, stackTrace) {
        debugPrint('❌ Error initiating payment: $e');
        debugPrint('Stack trace: $stackTrace');
        Get.snackbar(
          '❌ Error',
          'Failed to initiate payment: $e',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      } finally {
        isProcessing.value = false;
      }
    }
  }
}
