import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreditsService extends GetxService {
  final credits = 0.obs;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Credit costs
  static const int IMAGE_COST = 1;
  static const int VIDEO_COST = 5;
  static const int INITIAL_CREDITS = 50;

  Future<CreditsService> init() async {
    await _loadCredits();
    return this;
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
          
          Get.snackbar(
            '🎉 Welcome Bonus!',
            'You received $INITIAL_CREDITS free credits!',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
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
    
    Get.snackbar(
      '✅ Credits Added!',
      'You now have ${credits.value} credits',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
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
}
