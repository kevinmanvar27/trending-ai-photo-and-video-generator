import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../home/home_controller.dart';
import '../../core/services/credits_service.dart';
import '../../routes/app_routes.dart';

class UploadController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final selectedFile = Rxn<XFile>();
  final CreditsService creditsService = Get.find<CreditsService>();
  SampleItem? selectedSample;

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
        Get.snackbar(
          'Success',
          'Image selected successfully',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
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
        Get.snackbar(
          'Success',
          'Video selected successfully',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
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

  void processFile() {
    if (selectedFile.value == null) {
      Get.snackbar(
        'Error',
        'Please select a file first',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedSample == null) {
      Get.snackbar(
        'Error',
        'No style selected',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Check if user has enough credits
    final type = selectedSample!.type;
    final requiredCredits = creditsService.getRequiredCredits(type);
    
    if (!creditsService.hasEnoughCredits(type)) {
      // Show dialog to buy credits
      Get.dialog(
        AlertDialog(
          title: const Text('Insufficient Credits'),
          content: Text(
            'You need $requiredCredits credits to process this $type.\n\n'
            'Current balance: ${creditsService.credits.value} credits\n\n'
            'Would you like to buy more credits?'
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
              child: const Text('Buy Credits'),
            ),
          ],
        ),
      );
      return;
    }

    debugPrint('🚀 Navigating to processing screen...');
    debugPrint('📁 File: ${selectedFile.value?.path}');
    debugPrint('🎨 Sample: ${selectedSample?.title}');
    
    // Navigate to processing screen with file and sample data
    Get.toNamed(AppRoutes.processing, arguments: {
      'file': selectedFile.value,
      'sample': selectedSample,
    });
  }
}
