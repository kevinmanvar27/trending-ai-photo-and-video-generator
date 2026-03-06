import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/credits_service.dart';
import 'core/services/referral_redeem_service.dart';
import 'core/services/razorpay_service.dart';
import 'core/services/unified_auth_service.dart';
import 'core/controllers/theme_controller.dart';
import 'core/api_service_initializer.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    debugPrint('=== App Starting ===');
    
    // Initialize GetStorage for theme persistence
    await GetStorage.init();
    debugPrint('GetStorage initialized');
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
    
    // Initialize ThemeController early
    Get.put(ThemeController());
    debugPrint('ThemeController initialized');
    
    // Initialize CreditsService
    await Get.putAsync(() => CreditsService().init());
    debugPrint('CreditsService initialized');
    
    // Initialize ReferralRedeemService
    Get.put(ReferralRedeemService());
    debugPrint('ReferralRedeemService initialized');
    
    // Initialize UnifiedAuthService (must be before RazorpayService)
    Get.put(UnifiedAuthService());
    debugPrint('UnifiedAuthService initialized');
    
    // Initialize RazorpayService
    await Get.putAsync(() => RazorpayService().init());
    debugPrint('RazorpayService initialized');
    
    // Initialize all API services
    ApiServiceInitializer.init();
    debugPrint('All API services initialized');
    
    // ContactService will be initialized lazily when needed (via Get.find or Get.put in binding)
    
    debugPrint('Running app...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('Fatal error in main: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Obx(() => GetMaterialApp(
      title: 'Trends',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      defaultTransition: Transition.fade,
      enableLog: true,
    ));
  }
}
