import 'package:get/get.dart';
import 'services/api_service.dart';
import 'services/auth_api_service.dart';
import 'services/user_api_service.dart';
import 'services/template_api_service.dart';
import 'services/submission_api_service.dart';
import 'services/generation_api_service.dart';
import 'services/subscription_api_service.dart';
import 'services/contact_api_service.dart';
import 'services/activity_api_service.dart';
import 'services/settings_api_service.dart';

/// Initialize all API services
/// Call this in main.dart before running the app
class ApiServiceInitializer {
  static void init() {
    // Initialize base API service (singleton)
    Get.put(ApiService(), permanent: true);
    
    // Initialize all API services
    Get.lazyPut(() => AuthApiService());
    Get.lazyPut(() => UserApiService());
    Get.lazyPut(() => TemplateApiService());
    Get.lazyPut(() => SubmissionApiService()); // Legacy
    Get.lazyPut(() => GenerationApiService()); // New API
    Get.lazyPut(() => SubscriptionApiService());
    Get.lazyPut(() => ContactApiService());
    Get.lazyPut(() => ActivityApiService());
    Get.lazyPut(() => SettingsApiService());
    
    print('✅ All API services initialized');
  }
}
