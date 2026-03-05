import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../home/home_controller.dart';
import '../../core/services/credits_service.dart';
import '../../core/services/generation_api_service.dart';
import '../../core/services/subscription_api_service.dart';
import '../../routes/app_routes.dart';

class UploadController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final selectedFile = Rxn<XFile>();
  final CreditsService creditsService = Get.find<CreditsService>();
  final GenerationApiService _generationApiService = GenerationApiService();
  final SubscriptionApiService _subscriptionApiService = SubscriptionApiService();
  
  SampleItem? selectedSample;
  final isUploading = false.obs;
  final uploadProgress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // Get the selected sample from arguments or from HomeController
    final args = Get.arguments;
    if (args != null && args['selectedSample'] != null) {
      selectedSample = args['selectedSample'] as SampleItem;
    } else {
      // Fallback: get from HomeController
      try {
        final homeController = Get.find<HomeController>();
        selectedSample = homeController.selectedSample.value;
      } catch (e) {
        // HomeController not found
      }
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        selectedFile.value = image;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        selectedFile.value = video;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick video: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void clearFile() {
    selectedFile.value = null;
  }

  Future<void> processFile() async {
    if (selectedFile.value == null) {
      Get.snackbar(
        'Error',
        'Please select a file first',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (selectedSample == null) {
      Get.snackbar(
        'Error',
        'No style selected',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Use centralized CreditsService to check
    final requiredCoins = selectedSample!.coinsRequired;
    
    print('🔍 Checking if user can generate...');
    print('💰 Required coins: $requiredCoins');
    print('💰 Available coins: ${creditsService.credits.value}');
    print('📋 Has subscription: ${creditsService.hasActiveSubscription.value}');
    
    // Refresh coins from API if needed
    if (creditsService.needsRefresh()) {
      print('🔄 Refreshing coins from API...');
      await creditsService.fetchReferralCoins();
    }
    
    // Use centralized validation
    if (!creditsService.canGenerate(requiredCoins)) {
      print('❌ Cannot generate - validation failed');
      return;
    }
    
    print('✅ Validation passed, proceeding with upload');

    // Upload and create submission
    await _uploadSubmission();
  }

  // Check if user has active subscription and return subscription data
  Future<Map<String, dynamic>?> _checkSubscription() async {
    try {
      final subscription = await _subscriptionApiService.getMySubscription();
      if (subscription != null && subscription['status'] == 'active') {
        return subscription;
      }
      return null;
    } catch (e) {
      print('❌ Error checking subscription: $e');
      return null;
    }
  }

  Future<void> _uploadSubmission() async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;

      print('📤 Uploading for AI generation...');
      print('🆔 Template ID: ${selectedSample!.templateId}');
      print('📁 File path: ${selectedFile.value!.path}');
      print('🎨 Output type: ${selectedSample!.type}');

      // Use the new Generation API
      final response = await _generationApiService.uploadForGeneration(
        templateId: selectedSample!.templateId!,
        imagePath: selectedFile.value!.path,
        onUploadProgress: (sent, total) {
          uploadProgress.value = sent / total;
          print('📊 Upload progress: ${(uploadProgress.value * 100).toStringAsFixed(0)}%');
        },
      );

      print('✅ Upload successful!');
      print('📋 Response: $response');

      // Extract generation data
      final generationData = response['data'] ?? response;
      final generationId = generationData['generation_id'];
      final submissionId = generationData['submission_id']; // CRITICAL: Used for status polling
      
      if (submissionId == null) {
        throw Exception('No submission_id received from server');
      }

      // Show coins deducted info if available
      if (generationData['coins_deducted'] != null) {
        print('💰 Coins deducted: ${generationData['coins_deducted']}');
        print('💰 Remaining coins: ${generationData['remaining_coins']}');
        
        // Update local credits
        if (generationData['remaining_coins'] != null) {
          creditsService.credits.value = generationData['remaining_coins'];
        }
      }

      Get.snackbar(
        '✅ Success',
        response['message'] ?? 'Generation started successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Navigate to processing screen with SUBMISSION ID (not generation_id)
      print('🚀 Navigating to processing screen...');
      print('🆔 Generation ID: $generationId (reference only)');
      print('🆔 Submission ID: $submissionId (used for polling)');
      
      Get.toNamed(AppRoutes.processing, arguments: {
        'submissionId': submissionId, // CRITICAL: Use this for status polling
        'generationId': generationId, // Optional: For display purposes
        'file': selectedFile.value,
        'sample': selectedSample,
      });

    } on DioException catch (e) {
      print('❌ Upload error: ${e.response?.data}');
      
      // Handle specific backend errors
      if (e.response?.statusCode == 403) {
        final errorData = e.response?.data;
        if (errorData != null) {
          final errorMessage = errorData['message'] ?? errorData['error'] ?? '';
          
          // Check for subscription error
          if (errorMessage.toLowerCase().contains('subscription')) {
            _showNoSubscriptionDialog();
            return;
          } 
          // Check for insufficient coins error
          else if (errorMessage.toLowerCase().contains('insufficient coins') || 
                   errorMessage.toLowerCase().contains('not enough coins')) {
            final coinsRequired = errorData['coins_required'] ?? selectedSample!.coinsRequired;
            final coinsAvailable = errorData['coins_available'] ?? creditsService.credits.value;
            
            print('💰 Coins required: $coinsRequired');
            print('💰 Coins available: $coinsAvailable');
            
            _showInsufficientCreditsDialog(coinsRequired, coinsAvailable);
            return;
          }
          // Check for quota exceeded
          else if (errorMessage.toLowerCase().contains('quota')) {
            Get.snackbar(
              '❌ Quota Exceeded',
              errorMessage,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
            );
            return;
          }
        }
      } else if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData != null && errorData['error'] != null) {
          Get.snackbar(
            '❌ Error',
            errorData['error'],
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          return;
        }
      }
      
      // Generic error
      Get.snackbar(
        '❌ Error',
        'Failed to upload: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      print('❌ Unexpected error: $e');
      Get.snackbar(
        '❌ Error',
        'Failed to upload: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
    }
  }

  void _showNoSubscriptionDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.lock_outline, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Subscription Required'),
          ],
        ),
        content: const Text(
          'You need an active subscription to convert images and videos.\n\n'
          'Subscribe now to get started with coins and unlimited access!'
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed(AppRoutes.subscription);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }

  void _showInsufficientCreditsDialog(int required, int available) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.account_balance_wallet_outlined, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Insufficient Coins'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You don\'t have enough coins to convert this ${selectedSample?.type ?? 'file'}.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Required:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.toll, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '$required coins',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.toll, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            '$available coins',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Needed:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.add_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '${required - available} more coins',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Purchase a subscription plan to get more coins and continue converting!',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed(AppRoutes.subscription);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Buy More Coins'),
          ),
        ],
      ),
    );
  }
}
