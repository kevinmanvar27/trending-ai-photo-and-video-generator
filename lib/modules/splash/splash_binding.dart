import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint('SplashBinding: Creating controller');
    Get.put<SplashController>(SplashController(), permanent: false);
  }
}
