import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../core/services/credits_service.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('LoginController initialized');
  }

  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      debugPrint('Starting Google Sign-In...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        debugPrint('User canceled sign-in');
        isLoading.value = false;
        return;
      }

      debugPrint('Google user: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      await _auth.signInWithCredential(credential);

      // Give initial credits on first login
      final creditsService = Get.find<CreditsService>();
      await creditsService.giveInitialCredits();

      isLoading.value = false;
      
      debugPrint('Sign-in successful, navigating to main screen...');
      // Navigate to main screen
      Get.offAllNamed(AppRoutes.main);
      
    } catch (e) {
      isLoading.value = false;
      debugPrint('Sign-in error: $e');
      Get.snackbar(
        'Error',
        'Failed to sign in with Google: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
