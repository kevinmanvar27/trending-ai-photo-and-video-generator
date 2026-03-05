import 'dart:async';
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../home/home_controller.dart';
import '../../core/services/generation_api_service.dart';
import '../../core/models/generation_model.dart';
import '../../routes/app_routes.dart';

class ProcessingController extends GetxController {
  final progress = 0.0.obs;
  final statusText = 'Initializing...'.obs;
  final GenerationApiService _generationApiService = GenerationApiService();
  
  XFile? selectedFile;
  SampleItem? selectedSample;
  int? submissionId; // CRITICAL: Use submission_id for status polling
  String? generationId; // Optional: For display/reference only
  Timer? _pollTimer;
  bool processingComplete = false;
  GenerationModel? completedGeneration;

  @override
  void onInit() {
    super.onInit();
    print('✅ ProcessingController onInit called');
    
    // Get arguments
    final args = Get.arguments;
    if (args != null) {
      selectedFile = args['file'] as XFile?;
      selectedSample = args['sample'] as SampleItem?;
      submissionId = args['submissionId'] as int?; // CRITICAL: Used for polling
      generationId = args['generationId'] as String?; // Optional
      
      print('📁 File: ${selectedFile?.path}');
      print('🎨 Sample: ${selectedSample?.title}');
      print('🆔 Submission ID: $submissionId (used for polling)');
      print('🆔 Generation ID: $generationId (reference only)');
    } else {
      print('❌ No arguments received');
    }
  }

  @override
  void onReady() {
    super.onReady();
    print('✅ ProcessingController onReady called');
    startProcessing();
  }

  void startProcessing() async {
    try {
      print('🚀 Starting processing...');
      
      if (submissionId == null) {
        print('❌ No submission ID provided');
        Get.snackbar(
          'Error',
          'Invalid submission ID',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.back();
        return;
      }
      
      // Start polling - check status until image/video is ready
      _startPolling();
      
    } catch (e, stackTrace) {
      print('❌ Processing error: $e');
      print('Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Processing failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      Get.back();
    }
  }

  void _startPolling() {
    statusText.value = 'Processing your image...';
    progress.value = 20.0;
    
    print('⏳ Starting status polling...');
    
    // Poll every 3 seconds until completed
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        print('🔄 Checking generation status... (Poll #${timer.tick})');
        print('🆔 Using submission ID: $submissionId');
        
        final response = await _generationApiService.getGenerationStatus(submissionId!);
        final generation = GenerationModel.fromJson(response);
        
        print('📊 Status: ${generation.status}');
        print('📊 Progress: ${generation.progress}%');
        print('💬 Message: ${generation.message}');
        
        // Update UI based on status
        switch (generation.status) {
          case 'pending':
            statusText.value = generation.message ?? 'Waiting in queue...';
            progress.value = (generation.progress?.toDouble() ?? 20.0).clamp(10, 40);
            break;
            
          case 'processing':
            statusText.value = generation.message ?? 'Applying AI magic...';
            progress.value = (generation.progress?.toDouble() ?? 50.0).clamp(40, 90);
            break;
            
          case 'completed':
            // STOP POLLING - Image/Video is ready!
            timer.cancel();
            statusText.value = 'Processing complete!';
            progress.value = 100.0;
            processingComplete = true;
            completedGeneration = generation;
            
            print('✅ Generation completed successfully!');
            print('🖼️ Generated output: ${generation.generatedOutput}');
            
            // Navigate to preview
            Future.delayed(const Duration(milliseconds: 500), () {
              Get.offNamed(AppRoutes.preview, arguments: {
                'file': selectedFile,
                'sample': selectedSample,
                'generation': generation,
              });
            });
            break;
            
          case 'failed':
            // STOP POLLING - Generation failed
            timer.cancel();
            statusText.value = 'Processing failed';
            progress.value = 0.0;
            
            print('❌ Generation failed: ${generation.error}');
            
            Get.snackbar(
              'Processing Failed',
              generation.error ?? 'Unknown error occurred',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
            
            Future.delayed(const Duration(seconds: 2), () {
              Get.offAllNamed(AppRoutes.main);
            });
            break;
            
          default:
            // Unknown status, keep polling
            statusText.value = 'Processing...';
            progress.value = 50.0;
        }
        
        // Timeout after 3 minutes (60 polls at 3 seconds each)
        if (timer.tick > 60 && !processingComplete) {
          print('⏰ Polling timeout after 3 minutes');
          timer.cancel();
          Get.snackbar(
            'Timeout',
            'Processing is taking longer than expected. Please check your history.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
          Get.offAllNamed(AppRoutes.main);
        }
        
      } catch (e) {
        print('❌ Polling error: $e');
        // Continue polling - network might recover
      }
    });
  }

  @override
  void onClose() {
    print('🔴 ProcessingController onClose called');
    _pollTimer?.cancel();
    super.onClose();
  }
}
