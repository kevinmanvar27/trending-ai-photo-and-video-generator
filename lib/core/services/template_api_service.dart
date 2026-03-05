import 'package:dio/dio.dart';
import 'api_service.dart';
import 'api_config.dart';

class TemplateApiService {
  final ApiService _apiService = ApiService();
  
  // Get All Templates
  Future<List<dynamic>> getTemplates({
    String? type,
    bool? isActive,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      // Convert boolean to int (1/0) for Laravel backend
      if (isActive != null) queryParams['is_active'] = isActive ? 1 : 0;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      
      final response = await _apiService.get(
        ApiConfig.templates,
        queryParameters: queryParams,
      );
      return response.data['data'] as List;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get Template by ID
  Future<Map<String, dynamic>> getTemplateById(int id) async {
    try {
      final response = await _apiService.get(ApiConfig.templateById(id));
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  // Get Popular Templates
  Future<List<dynamic>> getPopularTemplates({int limit = 10}) async {
    try {
      final response = await _apiService.get(
        ApiConfig.popularTemplates,
        queryParameters: {'limit': limit},
      );
      return response.data['data'] as List;
    } catch (e) {
      rethrow;
    }
  }
  
  // Create Template (Admin)
  Future<Map<String, dynamic>> createTemplate({
    required String title,
    required String type,
    required String prompt,
    String? description,
    String? referenceImagePath,
    int? coinsRequired,
    bool? isActive,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'title': title,
        'type': type,
        'prompt': prompt,
        if (description != null) 'description': description,
        if (coinsRequired != null) 'coins_required': coinsRequired,
        if (isActive != null) 'is_active': isActive,
        if (referenceImagePath != null)
          'reference_image': await MultipartFile.fromFile(referenceImagePath),
      });
      
      final response = await _apiService.uploadFile(
        ApiConfig.templates,
        formData: formData,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update Template (Admin)
  Future<Map<String, dynamic>> updateTemplate({
    required int id,
    String? title,
    String? prompt,
    String? description,
    int? coinsRequired,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (prompt != null) data['prompt'] = prompt;
      if (description != null) data['description'] = description;
      if (coinsRequired != null) data['coins_required'] = coinsRequired;
      if (isActive != null) data['is_active'] = isActive;
      
      final response = await _apiService.put(
        ApiConfig.templateById(id),
        data: data,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete Template (Admin)
  Future<void> deleteTemplate(int id) async {
    try {
      await _apiService.delete(ApiConfig.templateById(id));
    } catch (e) {
      rethrow;
    }
  }
  
  // Toggle Template Status (Admin)
  Future<void> toggleTemplateStatus(int id) async {
    try {
      await _apiService.post(ApiConfig.toggleTemplateStatus(id));
    } catch (e) {
      rethrow;
    }
  }
}
