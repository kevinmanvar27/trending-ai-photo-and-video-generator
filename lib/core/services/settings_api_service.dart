import 'api_service.dart';
import 'api_config.dart';

class SettingsApiService {
  final ApiService _apiService = ApiService();
  
  // Get All Settings
  Future<List<dynamic>> getAllSettings() async {
    try {
      final response = await _apiService.get(ApiConfig.settings);
      return response.data['data'] as List;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get Settings by Group
  Future<List<dynamic>> getSettingsByGroup(String group) async {
    try {
      final response = await _apiService.get(
        ApiConfig.settingsByGroup(group),
      );
      return response.data['data'] as List;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get Setting by Key
  Future<Map<String, dynamic>> getSettingByKey(String key) async {
    try {
      final response = await _apiService.get(ApiConfig.settingByKey(key));
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  // Create or Update Setting
  Future<Map<String, dynamic>> saveSetting({
    required String key,
    required dynamic value,
    String? type,
    String? group,
  }) async {
    try {
      final data = {
        'key': key,
        'value': value,
        if (type != null) 'type': type,
        if (group != null) 'group': group,
      };
      
      final response = await _apiService.post(
        ApiConfig.settings,
        data: data,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Bulk Update Settings
  Future<Map<String, dynamic>> bulkUpdateSettings(
    List<Map<String, dynamic>> settings,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConfig.bulkUpdateSettings,
        data: {'settings': settings},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete Setting
  Future<void> deleteSetting(String key) async {
    try {
      await _apiService.delete(ApiConfig.settingByKey(key));
    } catch (e) {
      rethrow;
    }
  }
  
  // Clear Cache
  Future<Map<String, dynamic>> clearCache() async {
    try {
      final response = await _apiService.post(ApiConfig.clearCache);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
