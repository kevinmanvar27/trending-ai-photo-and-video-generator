import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'preview_controller.dart';

class PreviewBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint('✅ PreviewBinding: Creating PreviewController');
    Get.put<PreviewController>(PreviewController());
  }
}
