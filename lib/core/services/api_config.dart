class ApiConfig {
  // Base URL - Replace with your actual backend URL
  // Examples:
  // Production: 'https://api.yourapp.com/api'
  // Staging: 'https://staging-api.yourapp.com/api'
  // Local (Android Emulator): 'http://10.0.2.2:8000/api'
  // Local (Physical Device): 'http://YOUR_LOCAL_IP:8000/api' (e.g., 'http://192.168.1.100:8000/api')
  static const String baseUrl = 'https://trends.rektech.work/api'; // ⚠️ CHANGE THIS!
  
  
  // API Endpoints
  
  // Authentication
  static const String register = '/register';
  static const String login = '/login';
  static const String logout = '/logout';
  static const String googleLogin = '/google-login'; // Google OAuth backend authentication
  
  // User Profile
  static const String profile = '/profile';
  
  // Contacts
  static const String contacts = '/contacts';
  static const String contactsStore = '/contacts/store';
  
  // Activity Tracking
  static const String activityStart = '/activity/start';
  static const String activityEnd = '/activity/end';
  static const String activityHistory = '/activity/history';
  
  // Templates
  static const String templates = '/templates';
  static String templateById(int id) => '/templates/$id';
  static String toggleTemplateStatus(int id) => '/templates/$id/toggle-active';
  static const String popularTemplates = '/templates/popular';
  
  // Image Prompts
  static const String prompts = '/prompts';
  static String promptById(int id) => '/prompts/$id';
  static String processPrompt(int id) => '/prompts/$id/process';
  static String updatePromptStatus(int id) => '/prompts/$id/status';
  static const String promptStatistics = '/prompts/statistics';
  static const String recentPrompts = '/prompts/recent';
  
  // Image Submissions (Legacy - keeping for backward compatibility)
  static const String submissions = '/submissions';
  static String submissionById(int id) => '/submissions/$id';
  static String updateSubmissionStatus(int id) => '/submissions/$id/status';
  static const String submissionStatistics = '/submissions/statistics';
  static const String recentSubmissions = '/submissions/recent';
  
  // AI Generation (New API)
  static const String generateUpload = '/generate/upload';
  static String generateStatus(String generationId) => '/generate/status/$generationId';
  static const String generateHistory = '/generate/history';
  static String generateDownload(String generationId) => '/generate/download/$generationId';
  static String generateById(String generationId) => '/generate/$generationId';
  
  // Subscriptions
  static const String subscriptionPlans = '/subscription/plans';
  static String subscriptionPlanById(int id) => '/subscription/plans/$id';
  static const String subscribe = '/subscription/subscribe'; // Changed from /subscriptions
  static const String mySubscription = '/subscription/my-subscription';
  static const String subscriptionHistory = '/subscription/history'; // Changed from /subscriptions/history
  static const String cancelSubscription = '/subscription/cancel'; // Changed from /subscriptions/cancel
  
  // Referral System
  static const String validateReferralCode = '/referral/validate';
  static const String referralInfo = '/referral/info';
  static const String referralList = '/referral/list';
  static const String referralStats = '/referral/stats';
  static const String applyReferralCode = '/referral/apply';
  
  // Settings
  static const String settings = '/settings';
  static String settingsByGroup(String group) => '/settings/group/$group';
  static String settingByKey(String key) => '/settings/$key';
  static const String bulkUpdateSettings = '/settings/bulk-update';
  static const String clearCache = '/settings/clear-cache';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
