import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../home/home_controller.dart';
import '../../core/models/generation_model.dart';
import '../../core/services/share_service.dart';

class PreviewController extends GetxController {
  final showBefore = true.obs;
  final isDownloading = false.obs;
  final downloadProgress = 0.0.obs;
  
  final ShareService _shareService = Get.put(ShareService());
  
  XFile? selectedFile;
  SampleItem? selectedSample;
  GenerationModel? generation;

  @override
  void onInit() {
    super.onInit();
    
    // Get arguments
    final args = Get.arguments;
    if (args != null) {
      selectedFile = args['file'] as XFile?;
      selectedSample = args['sample'] as SampleItem?;
      generation = args['generation'] as GenerationModel?;
      
      print('📁 Original file: ${selectedFile?.path}');
      print('🎨 Sample: ${selectedSample?.title}');
      print('🖼️ Generated output URL: ${generation?.generatedOutput}');
    }
  }

  Future<void> downloadResult() async {
    if (generation?.generatedOutput == null) {
      Get.snackbar(
        'Error',
        'No generated content available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;

      print('📥 Downloading from: ${generation!.generatedOutput}');

      // Get downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'generated_${DateTime.now().millisecondsSinceEpoch}.${generation!.type == "video" ? "mp4" : "jpg"}';
      final filePath = '${directory.path}/$fileName';

      // Download file
      final dio = Dio();
      await dio.download(
        generation!.generatedOutput!,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress.value = received / total;
            print('📊 Download progress: ${(downloadProgress.value * 100).toStringAsFixed(0)}%');
          }
        },
      );

      print('✅ File downloaded to: $filePath');

    } catch (e) {
      print('❌ Download error: $e');
      Get.snackbar(
        'Error',
        'Failed to download: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isDownloading.value = false;
      downloadProgress.value = 0.0;
    }
  }

  Future<void> shareResult() async {
    if (generation?.generatedOutput == null) {
      Get.snackbar(
        'Error',
        'No generated content available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      print('📤 Sharing: ${generation!.generatedOutput}');

      // Download file to temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'share_${DateTime.now().millisecondsSinceEpoch}.${generation!.type == "video" ? "mp4" : "jpg"}';
      final filePath = '${tempDir.path}/$fileName';

      final dio = Dio();
      await dio.download(generation!.generatedOutput!, filePath);

      print('✅ File ready for sharing: $filePath');

      // Share file with referral code
      await _shareService.shareContent(
        files: [XFile(filePath)],
        contentType: generation!.type ?? 'content',
      );

      print('✅ Share dialog opened');

    } catch (e) {
      print('❌ Share error: $e');
      Get.snackbar(
        'Error',
        'Failed to share: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
