import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/credits_service.dart';
import '../../core/services/razorpay_service.dart';

class SubscriptionController extends GetxController {
  final CreditsService creditsService = Get.find<CreditsService>();
  RazorpayService? _razorpayService;
  
  final isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize Razorpay service
    _razorpayService = Get.put(RazorpayService());
    _razorpayService!.initRazorpay();
    debugPrint('🎮 SubscriptionController initialized with Razorpay');
  }

  @override
  void onClose() {
    _razorpayService?.onClose();
    super.onClose();
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
