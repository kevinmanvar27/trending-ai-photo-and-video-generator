import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_model.dart';
import 'user_api_service.dart';

/// Service for sharing content with referral code
class ShareService extends GetxService {
  final UserApiService _userApiService = UserApiService();
  
  String? _cachedReferralCode;
  
  /// Get referral code (cached or fetch from API)
  Future<String?> getReferralCode() async {
    if (_cachedReferralCode != null) {
      return _cachedReferralCode;
    }
    
    try {
      final response = await _userApiService.getProfile();
      if (response['data'] != null) {
        final user = UserModel.fromJson(response['data']);
        _cachedReferralCode = user.referralCode;
        return _cachedReferralCode;
      }
    } catch (e) {
      print('⚠️ Failed to fetch referral code: $e');
    }
    
    return null;
  }
  
  /// Clear cached referral code
  void clearCache() {
    _cachedReferralCode = null;
  }
  
  /// Share app with referral code
  Future<void> shareApp({String? customMessage}) async {
    final referralCode = await getReferralCode();
    
    String message = customMessage ?? 'Check out TRENDS - AI Photo & Video Generator! 🎨✨';
    
    if (referralCode != null && referralCode.isNotEmpty) {
      message += '\n\nUse my referral code: $referralCode to get bonus coins! 🎁';
    }
    
    message += '\n\nDownload now: https://play.google.com/store/apps/details?id=com.rektech.trends';
    
    await Share.share(message);
  }
  
  /// Share generated content with referral code
  Future<void> shareContent({
    required List<XFile> files,
    required String contentType, // 'image' or 'video'
    String? customMessage,
  }) async {
    final referralCode = await getReferralCode();
    
    String message = customMessage ?? 'Check out my AI-generated $contentType created with TRENDS! 🎨✨';
    
    if (referralCode != null && referralCode.isNotEmpty) {
      message += '\n\nUse my code: $referralCode to get bonus coins! 🎁';
      message += '\n\nDownload TRENDS: https://play.google.com/store/apps/details?id=com.rektech.trends';
    }
    
    await Share.shareXFiles(files, text: message);
  }
  
  /// Share referral code only
  Future<void> shareReferralCode() async {
    final referralCode = await getReferralCode();
    
    if (referralCode == null || referralCode.isEmpty) {
      Get.snackbar(
        'Error',
        'Referral code not available',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    final message = '''
🎁 Join me on TRENDS - AI Photo & Video Generator!

Use my referral code: $referralCode
Get bonus coins when you sign up! 💰

Download now:
https://play.google.com/store/apps/details?id=com.rektech.trends

Create amazing AI photos and videos! 🎨✨
''';
    
    await Share.share(message);
  }
}
