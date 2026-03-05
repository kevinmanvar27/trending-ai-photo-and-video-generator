import 'package:get/get.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/share_service.dart';
import '../../core/services/user_api_service.dart';
import '../../core/models/user_model.dart';

class InviteController extends GetxController {
  final contacts = <Contact>[].obs;
  final isLoading = false.obs;
  final hasPermission = false.obs;
  final searchQuery = ''.obs;

  // App details for invitation
  static const String appName = 'Trends';
  static const String playStoreLink = 'https://play.google.com/store/apps/details?id=com.rektech.trends'; // Update with your actual package name
  
  @override
  void onInit() {
    super.onInit();
    checkPermissionAndLoadContacts();
  }

  // Filtered contacts based on search query
  List<Contact> get filteredContacts {
    if (searchQuery.value.isEmpty) {
      return contacts;
    }
    return contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      final query = searchQuery.value.toLowerCase();
      return name.contains(query);
    }).toList();
  }

  // Check permission and load contacts
  Future<void> checkPermissionAndLoadContacts() async {
    debugPrint('🔐 Checking contacts permission...');
    
    final status = await Permission.contacts.status;
    debugPrint('📱 Permission status: $status');
    
    if (status.isGranted) {
      hasPermission.value = true;
      await loadContacts();
    } else if (status.isDenied) {
      await requestPermission();
    } else if (status.isPermanentlyDenied) {
      hasPermission.value = false;
      Get.snackbar(
        '⚠️ Permission Required',
        'Please enable contacts permission from settings',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Request contacts permission
  Future<void> requestPermission() async {
    debugPrint('📲 Requesting contacts permission...');
    
    final status = await Permission.contacts.request();
    debugPrint('✅ Permission result: $status');
    
    if (status.isGranted) {
      hasPermission.value = true;
      await loadContacts();
    } else if (status.isPermanentlyDenied) {
      hasPermission.value = false;
      Get.snackbar(
        '⚠️ Permission Denied',
        'Please enable contacts permission from settings',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      await openAppSettings();
    } else {
      hasPermission.value = false;
      Get.snackbar(
        '❌ Permission Denied',
        'Contacts permission is required to invite friends',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Load contacts from device
  Future<void> loadContacts() async {
    try {
      isLoading.value = true;
      debugPrint('📇 Loading contacts...');
      
      // Request permission using flutter_contacts
      if (!await FlutterContacts.requestPermission()) {
        hasPermission.value = false;
        debugPrint('❌ Contacts permission denied');
        return;
      }
      
      hasPermission.value = true;
      
      // Get all contacts with phone numbers
      final allContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      
      // Filter contacts that have phone numbers
      final contactsWithPhones = allContacts.where((contact) {
        return contact.phones.isNotEmpty;
      }).toList();
      
      // Sort by display name
      contactsWithPhones.sort((a, b) {
        return a.displayName.compareTo(b.displayName);
      });
      
      contacts.value = contactsWithPhones;
      debugPrint('✅ Loaded ${contacts.length} contacts');
      
    } catch (e) {
      debugPrint('❌ Error loading contacts: $e');
      Get.snackbar(
        '❌ Error',
        'Failed to load contacts: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Send WhatsApp invitation with referral code
  Future<void> sendWhatsAppInvite(Contact contact) async {
    try {
      if (contact.phones.isEmpty) {
        Get.snackbar(
          '⚠️ No Phone Number',
          'This contact has no phone number',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Get the first phone number and clean it
      String phoneNumber = contact.phones.first.number;
      phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), ''); // Remove all non-digit characters except +
      
      debugPrint('📱 Sending invite to: ${contact.displayName} ($phoneNumber)');

      // Get user's referral code
      final response = await UserApiService().getProfile();
      String referralCode = '';
      if (response['data'] != null) {
        final userProfile = UserModel.fromJson(response['data']);
        referralCode = userProfile.referralCode ?? '';
      }
      
      // Create invitation message with referral code
      final message = referralCode.isNotEmpty
          ? '''
Hey ${contact.displayName}! 👋

Check out $appName - an amazing app for creating AI-generated trending videos and images! 🎥✨

Download it now:
$playStoreLink

🎁 Use my code: $referralCode to get bonus coins!

You'll love it! 🚀
'''
          : '''
Hey ${contact.displayName}! 👋

Check out $appName - an amazing app for creating AI-generated trending videos and images! 🎥✨

Download it now:
$playStoreLink

You'll love it! 🚀
''';

      // Encode the message for URL
      final encodedMessage = Uri.encodeComponent(message);
      
      // Create WhatsApp URL
      final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';
      
      debugPrint('🔗 WhatsApp URL: $whatsappUrl');

      // Launch WhatsApp
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('✅ WhatsApp opened successfully');
      } else {
        debugPrint('❌ Cannot launch WhatsApp');
        Get.snackbar(
          '❌ Error',
          'WhatsApp is not installed on your device',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending WhatsApp invite: $e');
      Get.snackbar(
        '❌ Error',
        'Failed to open WhatsApp: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  // Share referral code via any app
  Future<void> shareReferralCode() async {
    final shareService = ShareService();
    await shareService.shareApp(
      customMessage: 'Hey! Check out $appName - an amazing app for creating AI-generated trending videos and images! 🎥✨',
    );
  }

  // Refresh contacts
  Future<void> refreshContacts() async {
    await loadContacts();
  }
}
