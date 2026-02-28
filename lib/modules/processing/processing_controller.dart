import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../home/home_controller.dart';
import '../../core/services/credits_service.dart';
import '../../routes/app_routes.dart';

class ProcessingController extends GetxController {
  final progress = 0.0.obs;
  final statusText = 'Initializing...'.obs;
  final CreditsService creditsService = Get.find<CreditsService>();
  
  XFile? selectedFile;
  SampleItem? selectedSample;
  Timer? _progressTimer;
  bool creditsDeducted = false;

  @override
  void onInit() {
    super.onInit();
    debugPrint('✅ ProcessingController onInit called');
    
    // Get arguments
    final args = Get.arguments;
    if (args != null) {
      selectedFile = args['file'] as XFile?;
      selectedSample = args['sample'] as SampleItem?;
      debugPrint('📁 File: ${selectedFile?.path}');
      debugPrint('🎨 Sample: ${selectedSample?.title}');
    } else {
      debugPrint('❌ No arguments received');
    }
  }

  @override
  void onReady() {
    super.onReady();
    debugPrint('✅ ProcessingController onReady called');
    startProcessing();
  }

  void startProcessing() async {
    try {
      debugPrint('🚀 Starting processing...');
      
      // Deduct credits at the start of processing
      if (selectedSample != null && !creditsDeducted) {
        final type = selectedSample!.type;
        final requiredCredits = creditsService.getRequiredCredits(type);
        debugPrint('💰 Deducting $requiredCredits credits for $type');
        
        final success = await creditsService.useCredits(requiredCredits, type);
        
        if (!success) {
          debugPrint('❌ Credit deduction failed');
          Get.snackbar(
            'Error',
            'Failed to deduct credits',
            snackPosition: SnackPosition.BOTTOM,
          );
          Get.back();
          return;
        }
        creditsDeducted = true;
        debugPrint('✅ Credits deducted successfully');
      }
      
      int step = 0;
      
      _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        step++;
        progress.value = (step * 2.5).clamp(0, 100);

        // Update status text based on progress
        if (progress.value < 25) {
          statusText.value = 'Uploading file...';
        } else if (progress.value < 50) {
          statusText.value = 'Analyzing content...';
        } else if (progress.value < 75) {
          statusText.value = 'Applying AI conversion...';
        } else if (progress.value < 100) {
          statusText.value = 'Finalizing output...';
        } else {
          statusText.value = 'Processing complete!';
          timer.cancel();
          
          debugPrint('✅ Processing complete, navigating to preview...');
          // Navigate to preview after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            Get.offNamed(AppRoutes.preview, arguments: {
              'file': selectedFile,
              'sample': selectedSample,
            });
          });
        }
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Processing error: $e');
      debugPrint('Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Processing failed: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    }
  }

  @override
  void onClose() {
    debugPrint('🔴 ProcessingController onClose called');
    _progressTimer?.cancel();
    super.onClose();
  }
}
