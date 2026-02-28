import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint('✅ LoginBinding: Creating LoginController');
    Get.put<LoginController>(LoginController());
  }
}
