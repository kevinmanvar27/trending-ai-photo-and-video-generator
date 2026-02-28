import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/credits_service.dart';
import 'core/services/razorpay_service.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    debugPrint('=== App Starting ===');
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
    
    // Initialize CreditsService
    await Get.putAsync(() => CreditsService().init());
    debugPrint('CreditsService initialized');
    
    // Initialize RazorpayService
    await Get.putAsync(() => RazorpayService().init());
    debugPrint('RazorpayService initialized');
    
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
    return GetMaterialApp(
      title: 'Trends',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      defaultTransition: Transition.fade,
      enableLog: true,
    );
  }
}
