import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'processing_controller.dart';

class ProcessingBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint('✅ ProcessingBinding: Creating ProcessingController');
    Get.put<ProcessingController>(ProcessingController());
  }
}
