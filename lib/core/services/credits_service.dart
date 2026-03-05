import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription_api_service.dart';
import 'referral_api_service.dart';
import 'api_service.dart';

class CreditsService extends GetxService {
  final credits = 0.obs;
  final isLoading = false.obs;
  final hasActiveSubscription = false.obs;
  final subscriptionPlanName = ''.obs;
  final subscriptionDaysRemaining = 0.obs;
  final lastSyncTime = Rxn<DateTime>();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SubscriptionApiService _subscriptionApi = SubscriptionApiService();
  final ReferralApiService _referralApi = ReferralApiService();
  
  // Credit costs
  static const int IMAGE_COST = 1;
  static const int VIDEO_COST = 5;
  static const int INITIAL_CREDITS = 50;

  Future<CreditsService> init() async {
    print('🚀 Initializing CreditsService...');
    await _loadCredits();
    // Fetch all coins (referral + subscription)
    await fetchAllCoins();
    return this;
  }

  // Fetch ALL coins (referral + subscription combined)
  Future<bool> fetchAllCoins() async {
    try {
      isLoading.value = true;
      print('💰 Fetching ALL coins (referral + subscription)...');
      
      // Check if user is authenticated
      final apiService = ApiService();
      if (apiService.authToken == null) {
        print('⚠️ No auth token found, loading from Firestore');
        await _loadCredits();
        isLoading.value = false;
        return false;
      }
      
      int referralCoins = 0;
      int subscriptionCoins = 0;
      
      // 1. Fetch referral coins
      try {
        print('📍 Step 1: Fetching referral coins...');
        final referralInfo = await _referralApi.getReferralInfo();
        
        if (referralInfo != null && referralInfo['success'] == true) {
          final data = referralInfo['data'];
          final coins = data['referral_coins'] ?? data['total_coins_earned'] ?? 0;
          referralCoins = coins is int ? coins : int.parse(coins.toString());
          print('✅ Referral coins: $referralCoins');
        } else {
          print('⚠️ No referral data found');
        }
      } catch (e) {
        print('⚠️ Error fetching referral coins: $e');
      }
      
      // 2. Fetch subscription coins
      try {
        print('📍 Step 2: Fetching subscription coins...');
        final subscriptionData = await _subscriptionApi.getMySubscription();
        
        if (subscriptionData != null) {
          // Extract coins from response
          if (subscriptionData.containsKey('remaining_coins')) {
            final remainingCoins = subscriptionData['remaining_coins'];
            subscriptionCoins = remainingCoins is int ? remainingCoins : (remainingCoins as num).toInt();
          } else if (subscriptionData.containsKey('remainingCoins')) {
            final remainingCoins = subscriptionData['remainingCoins'];
            subscriptionCoins = remainingCoins is int ? remainingCoins : (remainingCoins as num).toInt();
          } else {
            // Fallback: calculate from plan
            final plan = subscriptionData['plan'];
            final coinsUsed = subscriptionData['coins_used'] ?? 0;
            if (plan != null && plan['coins'] != null) {
              final planCoins = plan['coins'];
              final totalCoins = planCoins is int ? planCoins : (planCoins as num).toInt();
              final usedCoins = coinsUsed is int ? coinsUsed : (coinsUsed as num).toInt();
              subscriptionCoins = totalCoins - usedCoins;
            }
          }
          
          // Update subscription info
          hasActiveSubscription.value = subscriptionData['status'] == 'active';
          subscriptionPlanName.value = subscriptionData['plan']?['name'] ?? '';
          subscriptionDaysRemaining.value = subscriptionData['days_remaining'] ?? 0;
          
          print('✅ Subscription coins: $subscriptionCoins');
          print('📋 Plan: ${subscriptionPlanName.value}');
          print('📅 Days remaining: ${subscriptionDaysRemaining.value}');
        } else {
          print('⚠️ No active subscription found');
          hasActiveSubscription.value = false;
          subscriptionPlanName.value = '';
          subscriptionDaysRemaining.value = 0;
        }
      } catch (e) {
        print('⚠️ Error fetching subscription coins: $e');
      }
      
      // 3. Combine both coins
      final totalCoins = referralCoins + subscriptionCoins;
      credits.value = totalCoins;
      lastSyncTime.value = DateTime.now();
      
      print('╔════════════════════════════════════════════════════════════════');
      print('║ 💰 TOTAL COINS CALCULATED');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ 🎁 Referral Coins:     $referralCoins');
      print('║ 📦 Subscription Coins: $subscriptionCoins');
      print('║ ➕ TOTAL COINS:        $totalCoins');
      print('╚════════════════════════════════════════════════════════════════\n');
      
      // Save to Firestore for offline access
      await _saveCredits();
      
      return true;
    } catch (e) {
      print('❌ Error fetching all coins: $e');
      // Load from Firestore as fallback
      await _loadCredits();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch referral coins from backend (DEPRECATED - use fetchAllCoins instead)
  // Kept for backward compatibility
  Future<bool> fetchReferralCoins() async {
    print('⚠️ fetchReferralCoins() is deprecated, calling fetchAllCoins() instead');
    return await fetchAllCoins();
  }

  // Fetch coins from subscription API (centralized method)
  Future<bool> fetchCoinsFromAPI() async {
    try {
      isLoading.value = true;
      print('🔍 Fetching coins from subscription API...');
      
      final subscriptionData = await _subscriptionApi.getMySubscription();
      
      if (subscriptionData == null) {
        print('⚠️ No active subscription found');
        hasActiveSubscription.value = false;
        credits.value = 0;
        subscriptionPlanName.value = '';
        subscriptionDaysRemaining.value = 0;
        lastSyncTime.value = DateTime.now();
        return false;
      }
      
      // Extract coins from response
      int coins = 0;
      if (subscriptionData.containsKey('remaining_coins')) {
        final remainingCoins = subscriptionData['remaining_coins'];
        coins = remainingCoins is int ? remainingCoins : (remainingCoins as num).toInt();
      } else if (subscriptionData.containsKey('remainingCoins')) {
        final remainingCoins = subscriptionData['remainingCoins'];
        coins = remainingCoins is int ? remainingCoins : (remainingCoins as num).toInt();
      } else {
        // Fallback: calculate from plan
        final plan = subscriptionData['plan'];
        final coinsUsed = subscriptionData['coins_used'] ?? 0;
        if (plan != null && plan['coins'] != null) {
          final planCoins = plan['coins'];
          final totalCoins = planCoins is int ? planCoins : (planCoins as num).toInt();
          final usedCoins = coinsUsed is int ? coinsUsed : (coinsUsed as num).toInt();
          coins = totalCoins - usedCoins;
        }
      }
      
      // Update all subscription info
      credits.value = coins;
      hasActiveSubscription.value = subscriptionData['status'] == 'active';
      subscriptionPlanName.value = subscriptionData['plan']?['name'] ?? '';
      subscriptionDaysRemaining.value = subscriptionData['days_remaining'] ?? 0;
      lastSyncTime.value = DateTime.now();
      
      print('✅ Coins fetched successfully: $coins');
      print('📋 Plan: ${subscriptionPlanName.value}');
      print('📅 Days remaining: ${subscriptionDaysRemaining.value}');
      
      // Save to Firestore for offline access
      await _saveCredits();
      
      return true;
    } catch (e) {
      print('❌ Error fetching coins from API: $e');
      // Load from Firestore as fallback
      await _loadCredits();
      isLoading.value = false;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Load credits from Firestore
  Future<void> _loadCredits() async {
    final userId = _auth.currentUser?.uid;
    
    if (userId != null) {
      try {
        final doc = await _firestore.collection('users').doc(userId).get();
        
        if (doc.exists) {
          credits.value = doc.data()?['credits'] ?? 0;
        } else {
          // User document doesn't exist, create it with 0 credits
          credits.value = 0;
        }
      } catch (e) {
        print('Error loading credits: $e');
        credits.value = 0;
      }
    }
  }

  // Save credits to Firestore
  Future<void> _saveCredits() async {
    final userId = _auth.currentUser?.uid;
    
    if (userId != null) {
      try {
        await _firestore.collection('users').doc(userId).set({
          'credits': credits.value,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error saving credits: $e');
      }
    }
  }

  // Give initial credits on first login (stored in Firestore)
  Future<void> giveInitialCredits() async {
    final userId = _auth.currentUser?.uid;
    
    if (userId != null) {
      try {
        final doc = await _firestore.collection('users').doc(userId).get();
        
        // Check if user document exists
        if (!doc.exists) {
          // New user - give initial credits
          credits.value = INITIAL_CREDITS;
          
          await _firestore.collection('users').doc(userId).set({
            'credits': INITIAL_CREDITS,
            'email': _auth.currentUser?.email,
            'displayName': _auth.currentUser?.displayName,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // Existing user - just load their credits
          credits.value = doc.data()?['credits'] ?? 0;
        }
      } catch (e) {
        print('Error giving initial credits: $e');
      }
    }
  }

  // Add credits (for purchases)
  Future<void> addCredits(int amount) async {
    credits.value += amount;
    await _saveCredits();
    
    // Also log the transaction
    await _logTransaction('purchase', amount, 'Purchased $amount credits');
  }

  // Use credits (for processing)
  Future<bool> useCredits(int amount, String type) async {
    if (credits.value >= amount) {
      credits.value -= amount;
      await _saveCredits();
      
      // Log the transaction
      await _logTransaction('usage', -amount, 'Used for $type conversion');
      
      return true;
    } else {
      Get.snackbar(
        '❌ Insufficient Credits',
        'You need $amount credits to process this $type. You have ${credits.value} credits.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
  }

  // Log transaction to Firestore (for history/audit)
  Future<void> _logTransaction(String type, int amount, String description) async {
    final userId = _auth.currentUser?.uid;
    
    if (userId != null) {
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .add({
          'type': type, // 'purchase' or 'usage'
          'amount': amount,
          'description': description,
          'timestamp': FieldValue.serverTimestamp(),
          'balanceAfter': credits.value,
        });
      } catch (e) {
        print('Error logging transaction: $e');
      }
    }
  }

  // Check if user has enough credits
  bool hasEnoughCredits(String type) {
    final required = type == 'video' ? VIDEO_COST : IMAGE_COST;
    return credits.value >= required;
  }

  // Get required credits for type
  int getRequiredCredits(String type) {
    return type == 'video' ? VIDEO_COST : IMAGE_COST;
  }

  // Update credits from backend response (sync with Laravel backend)
  void updateCredits(int newCredits) {
    credits.value = newCredits;
    _saveCredits(); // Also save to Firestore for offline access
  }

  // Sync credits with backend (for API integration)
  Future<void> syncWithBackend(int backendCoins) async {
    print('🔄 Syncing coins with backend: $backendCoins');
    credits.value = backendCoins;
    await _saveCredits();
  }

  // Get current credits value
  int getCredits() {
    return credits.value;
  }

  // Deduct credits locally (backend will handle actual deduction)
  void deductCredits(int amount) {
    if (credits.value >= amount) {
      credits.value -= amount;
      _saveCredits();
    }
  }

  // Update from subscription API response
  void updateFromSubscription(Map<String, dynamic> subscriptionData) {
    print('💰 Updating coins from subscription data...');
    
    // Extract coins
    int coins = 0;
    if (subscriptionData.containsKey('remaining_coins')) {
      final remainingCoins = subscriptionData['remaining_coins'];
      coins = remainingCoins is int ? remainingCoins : (remainingCoins as num).toInt();
    } else if (subscriptionData.containsKey('remainingCoins')) {
      final remainingCoins = subscriptionData['remainingCoins'];
      coins = remainingCoins is int ? remainingCoins : (remainingCoins as num).toInt();
    } else {
      final plan = subscriptionData['plan'];
      final coinsUsed = subscriptionData['coins_used'] ?? 0;
      if (plan != null && plan['coins'] != null) {
        final planCoins = plan['coins'];
        final totalCoins = planCoins is int ? planCoins : (planCoins as num).toInt();
        final usedCoins = coinsUsed is int ? coinsUsed : (coinsUsed as num).toInt();
        coins = totalCoins - usedCoins;
      }
    }
    
    // Update all info
    credits.value = coins;
    hasActiveSubscription.value = subscriptionData['status'] == 'active';
    subscriptionPlanName.value = subscriptionData['plan']?['name'] ?? '';
    subscriptionDaysRemaining.value = subscriptionData['days_remaining'] ?? 0;
    lastSyncTime.value = DateTime.now();
    
    print('✅ Coins updated: $coins');
    _saveCredits();
  }
  
  // Check if coins need refresh (older than 5 minutes)
  bool needsRefresh() {
    if (lastSyncTime.value == null) return true;
    final diff = DateTime.now().difference(lastSyncTime.value!);
    return diff.inMinutes >= 5;
  }
  
  // Get display text for subscription status
  String getSubscriptionStatusText() {
    if (!hasActiveSubscription.value) {
      return 'No Active Plan';
    }
    return '${subscriptionPlanName.value} • ${subscriptionDaysRemaining.value} days left';
  }
  
  // Check if user can generate (has subscription and coins)
  bool canGenerate(int requiredCoins) {
    // DEVELOPMENT MODE: Allow generation without subscription
    // TODO: Enable subscription check in production
    final bool enforceSubscription = false; // Set to true in production
    
    if (enforceSubscription && !hasActiveSubscription.value) {
      Get.snackbar(
        '🔒 Subscription Required',
        'Please subscribe to a plan to generate content',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }
    
    // Check coins (always required)
    if (credits.value < requiredCoins) {
      Get.snackbar(
        '💰 Insufficient Coins',
        'You need $requiredCoins coins but have ${credits.value} coins',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }
    
    return true;
  }
}
