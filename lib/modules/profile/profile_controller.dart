import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/services/credits_service.dart';
import '../../routes/app_routes.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CreditsService creditsService = Get.find<CreditsService>();
  
  final userName = ''.obs;
  final userEmail = ''.obs;

  final ThemeController themeController = Get.put(ThemeController());

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  void _loadUserData() {
    final user = _auth.currentUser;
    if (user != null) {
      userName.value = user.displayName ?? 'User';
      userEmail.value = user.email ?? 'No email';
    }
  }

  Future<void> logout() async {
    try {
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
}
