import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'credits_service.dart';
import 'unified_auth_service.dart';
import 'api_service.dart';

class RazorpayService extends GetxService {
  Razorpay? _razorpay;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UnifiedAuthService _unifiedAuth = Get.find<UnifiedAuthService>();
  
  // Test credentials
  static const String keyId = 'rzp_test_Go3jN8rdNmRJ7P';
  static const String keySecret = 'sbD3JVTl7W7UJ18O43cRmtCE';
  
  // Store pending payment details
  int? _pendingCredits;
  int? _pendingAmount;
  bool _isSubscriptionPayment = false; // Flag to differentiate subscription vs credit purchase
  Function(String, String, String)? _onPaymentSuccess; // Callback for payment success

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
    bool isSubscription = false, // Flag to indicate if this is a subscription payment
    Function(String, String, String)? onSuccess, // Callback for payment success
  }) async {
    debugPrint('💳 Opening Razorpay checkout...');
    debugPrint('💰 Amount: ₹$amountInRupees for $credits credits');
    debugPrint('📦 Payment Type: ${isSubscription ? "Subscription" : "Credit Purchase"}');
    
    // Initialize Razorpay if not already done
    if (_razorpay == null) {
      initRazorpay();
    }
    
    // Store pending payment details
    _pendingCredits = credits;
    _pendingAmount = amountInRupees;
    _isSubscriptionPayment = isSubscription;
    _onPaymentSuccess = onSuccess;

    // Check authentication using unified auth service
    final isAuthenticated = await _unifiedAuth.checkAuthentication();
    if (!isAuthenticated) {
      debugPrint('❌ User not authenticated');
      Get.snackbar(
        '❌ Error',
        'Please login to continue',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Get user details from unified auth
    final userEmail = _unifiedAuth.getUserEmail();
    final userPhone = _unifiedAuth.getUserPhone();
    
    debugPrint('👤 User: $userEmail (Auth type: ${_unifiedAuth.isFirebaseUser() ? "Google" : "Email"})');
    
    // Log bearer token if using email auth
    if (!_unifiedAuth.isFirebaseUser()) {
      final apiService = Get.find<ApiService>();
      debugPrint('🔑 Using Bearer Token for Payment: ${apiService.authToken}');
    }

    var options = {
      'key': keyId,
      'amount': amountInRupees * 100, // Amount in paise (multiply by 100)
      'name': 'Trends App',
      'description': '$credits Credits',
      'prefill': {
        'contact': userPhone ?? '',
        'email': userEmail ?? '',
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
    debugPrint('📦 Payment Type: ${_isSubscriptionPayment ? "Subscription" : "Credit Purchase"}');
    
    if (_pendingCredits != null && _pendingAmount != null) {
      try {
        // Save payment details to Firestore
        await _savePaymentToFirestore(
          paymentId: response.paymentId ?? '',
          orderId: response.orderId ?? '',
          signature: response.signature ?? '',
          credits: _pendingCredits!,
          amount: _pendingAmount!,
          status: 'success',
        );

        if (_isSubscriptionPayment && _onPaymentSuccess != null) {
          // For subscription payments, call the callback
          debugPrint('💳 Calling subscription payment success callback...');
          await _onPaymentSuccess!(
            response.paymentId ?? '',
            response.orderId ?? '',
            response.signature ?? '',
          );
        } else {
          // For credit purchases, just add credits
          final creditsService = Get.find<CreditsService>();
          await creditsService.addCredits(_pendingCredits!);
          
          // Navigate back
          Get.back();
        }
      } catch (e) {
        debugPrint('❌ Error processing payment: $e');
        Get.snackbar(
          '⚠️ Warning',
          'Payment successful but processing failed. Contact support with payment ID: ${response.paymentId}',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      }
    }
    
    // Clear pending payment
    _pendingCredits = null;
    _pendingAmount = null;
    _isSubscriptionPayment = false;
    _onPaymentSuccess = null;
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
    // Get user ID from unified auth (works for both Firebase and email users)
    final userId = _unifiedAuth.getUserId();
    
    if (userId != null && userId.isNotEmpty) {
      try {
        // Only save to Firestore if user is Firebase user
        if (_unifiedAuth.isFirebaseUser()) {
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
        } else {
          debugPrint('ℹ️ Email user - payment tracked via backend API');
          // For email users, payment will be tracked via backend API
          // The backend subscription/payment endpoints handle this
        }
      } catch (e) {
        debugPrint('❌ Error saving payment to Firestore: $e');
      }
    } else {
      debugPrint('⚠️ No user ID available to save payment');
    }
  }
}
