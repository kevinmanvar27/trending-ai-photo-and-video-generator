import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _storage = GetStorage();
  final isDarkMode = false.obs;
  
  static const String _themeKey = 'isDarkMode';

  @override
  void onInit() {
    super.onInit();
    // Load saved theme preference
    isDarkMode.value = _storage.read(_themeKey) ?? false;
    // Apply the saved theme
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    // Save to storage
    _storage.write(_themeKey, isDarkMode.value);
    // Apply theme
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
}
