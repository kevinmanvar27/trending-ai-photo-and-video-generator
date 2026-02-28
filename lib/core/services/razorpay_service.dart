import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'credits_service.dart';

class RazorpayService extends GetxService {
  Razorpay? _razorpay;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Test credentials
  static const String keyId = 'rzp_test_Go3jN8rdNmRJ7P';
  static const String keySecret = 'sbD3JVTl7W7UJ18O43cRmtCE';
  
  // Store pending payment details
  int? _pendingCredits;
  int? _pendingAmount;

  // Initialize service
  Future<RazorpayService> init() async {
    debugPrint('🔧 RazorpayService init() called');
    initRazorpay();
    return this;
  }

  // Initialize Razorpay
  void initRazorpay() {
    debugPrint('🔧 Initializing Razorpay...');
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    debugPrint('✅ Razorpay initialized successfully');
  }

  @override
  void onClose() {
    _razorpay?.clear();
    super.onClose();
  }

  // Open Razorpay checkout
  Future<void> openCheckout({
    required int credits,
    required int amountInRupees,
  }) async {
    debugPrint('💳 Opening Razorpay checkout...');
    debugPrint('💰 Amount: ₹$amountInRupees for $credits credits');
    
    // Initialize Razorpay if not already done
    if (_razorpay == null) {
      initRazorpay();
    }
    
    // Store pending payment details
    _pendingCredits = credits;
    _pendingAmount = amountInRupees;

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ User not logged in');
      Get.snackbar(
        '❌ Error',
        'Please login to continue',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    debugPrint('👤 User: ${user.email}');

    var options = {
      'key': keyId,
      'amount': amountInRupees * 100, // Amount in paise (multiply by 100)
      'name': 'Trends App',
      'description': '$credits Credits',
      'prefill': {
        'contact': user.phoneNumber ?? '',
        'email': user.email ?? '',
      },
      'theme': {
        'color': '#6C63FF',
      },
    };

    debugPrint('🔑 Razorpay options: $options');

    try {
      debugPrint('🚀 Calling razorpay.open()...');
      _razorpay!.open(options);
      debugPrint('✅ Razorpay checkout opened');
    } catch (e, stackTrace) {
      debugPrint('❌ Error opening Razorpay: $e');
      debugPrint('Stack trace: $stackTrace');
      Get.snackbar(
        '❌ Error',
        'Failed to open payment gateway: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  // Handle successful payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ Payment Success: ${response.paymentId}');
    
    if (_pendingCredits != null && _pendingAmount != null) {
      try {
        // Get CreditsService
        final creditsService = Get.find<CreditsService>();
        
        // Save payment details to Firestore
        await _savePaymentToFirestore(
          paymentId: response.paymentId ?? '',
          orderId: response.orderId ?? '',
          signature: response.signature ?? '',
          credits: _pendingCredits!,
          amount: _pendingAmount!,
          status: 'success',
        );

        // Add credits to user account
        await creditsService.addCredits(_pendingCredits!);
        
        Get.snackbar(
          '✅ Payment Successful!',
          'You received $_pendingCredits credits',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        
        // Navigate back
        Get.back();
      } catch (e) {
        debugPrint('❌ Error processing payment: $e');
        Get.snackbar(
          '⚠️ Warning',
          'Payment successful but credits update failed. Contact support.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      }
    }
    
    // Clear pending payment
    _pendingCredits = null;
    _pendingAmount = null;
  }

  // Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) async {
    debugPrint('❌ Payment Error: ${response.code} - ${response.message}');
    
    if (_pendingCredits != null && _pendingAmount != null) {
      // Save failed payment to Firestore for tracking
      await _savePaymentToFirestore(
        paymentId: '',
        orderId: '',
        signature: '',
        credits: _pendingCredits!,
        amount: _pendingAmount!,
        status: 'failed',
        errorCode: response.code.toString(),
        errorMessage: response.message ?? 'Unknown error',
      );
    }
    
    Get.snackbar(
      '❌ Payment Failed',
      response.message ?? 'Something went wrong',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
    
    // Clear pending payment
    _pendingCredits = null;
    _pendingAmount = null;
  }

  // Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('ℹ️ External Wallet: ${response.walletName}');
    Get.snackbar(
      'ℹ️ External Wallet',
      'Payment via ${response.walletName}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Save payment details to Firestore
  Future<void> _savePaymentToFirestore({
    required String paymentId,
    required String orderId,
    required String signature,
    required int credits,
    required int amount,
    required String status,
    String? errorCode,
    String? errorMessage,
  }) async {
    final userId = _auth.currentUser?.uid;
    
    if (userId != null) {
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('payments')
            .add({
          'paymentId': paymentId,
          'orderId': orderId,
          'signature': signature,
          'credits': credits,
          'amount': amount,
          'status': status,
          'errorCode': errorCode,
          'errorMessage': errorMessage,
          'timestamp': FieldValue.serverTimestamp(),
          'platform': 'razorpay',
        });
        debugPrint('💾 Payment saved to Firestore');
      } catch (e) {
        debugPrint('❌ Error saving payment to Firestore: $e');
      }
    }
  }
}
