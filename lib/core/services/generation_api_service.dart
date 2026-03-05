import 'package:dio/dio.dart';
import 'api_service.dart';
import 'api_config.dart';

/// API Service for AI Image/Video Generation
/// Based on the new API documentation
class GenerationApiService {
  final ApiService _apiService = ApiService();
  
  /// Upload image for generation with template
  /// 
  /// Endpoint: POST /generate/upload
  /// 
  /// Parameters:
  /// - templateId: ID of the template to apply
  /// - imagePath: Local path to the image file
  /// - customPrompt: Optional custom instructions (if supported)
  /// - settings: Optional generation settings
  /// - onUploadProgress: Callback for upload progress
  /// 
  /// Returns: Generation data with generation_id and status
  Future<Map<String, dynamic>> uploadForGeneration({
    required int templateId,
    required String imagePath,
    String? customPrompt,
    Map<String, dynamic>? settings,
    ProgressCallback? onUploadProgress,
  }) async {
    try {
      print('📤 Uploading image for generation...');
      print('🆔 Template ID: $templateId');
      print('📁 Image path: $imagePath');
      
      final formData = FormData.fromMap({
        'template_id': templateId,
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
        if (customPrompt != null) 'custom_prompt': customPrompt,
        if (settings != null) 'settings': settings.toString(),
      });
      
      final response = await _apiService.uploadFile(
        ApiConfig.generateUpload,
        formData: formData,
        onSendProgress: onUploadProgress,
      );
      
      print('✅ Upload successful!');
      print('📋 Response: ${response.data}');
      
      return response.data;
    } catch (e) {
      print('❌ Upload failed: $e');
      rethrow;
    }
  }
  
  /// Check generation status
  /// 
  /// Endpoint: GET /generate/status/{submission_id}
  /// 
  /// IMPORTANT: Uses submission_id (integer), NOT generation_id (string)
  /// 
  /// Returns: Generation status with progress and result URLs when completed
  Future<Map<String, dynamic>> getGenerationStatus(int submissionId) async {
    try {
      print('🔍 Checking status for submission ID: $submissionId');
      final response = await _apiService.get(
        ApiConfig.generateStatus(submissionId.toString()),
      );
      return response.data;
    } catch (e) {
      print('❌ Failed to get generation status: $e');
      rethrow;
    }
  }
  
  /// Get user's generation history
  /// 
  /// Endpoint: GET /generate/history
  /// 
  /// Parameters:
  /// - page: Page number (default: 1)
  /// - limit: Items per page (default: 20, max: 100)
  /// - status: Filter by status (completed, processing, failed)
  /// - type: Filter by type (image, video)
  Future<Map<String, dynamic>> getGenerationHistory({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;
      
      final response = await _apiService.get(
        ApiConfig.generateHistory,
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      print('❌ Failed to get generation history: $e');
      rethrow;
    }
  }
  
  /// Download generated content
  /// 
  /// Endpoint: GET /generate/download/{generation_id}
  /// 
  /// Returns: Binary file stream
  Future<Response> downloadGeneration(String generationId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.generateDownload(generationId),
        options: Options(responseType: ResponseType.bytes),
      );
      return response;
    } catch (e) {
      print('❌ Failed to download generation: $e');
      rethrow;
    }
  }
  
  /// Delete a generation
  /// 
  /// Endpoint: DELETE /generate/{generation_id}
  Future<void> deleteGeneration(String generationId) async {
    try {
      await _apiService.delete(
        ApiConfig.generateById(generationId),
      );
      print('✅ Generation deleted successfully');
    } catch (e) {
      print('❌ Failed to delete generation: $e');
      rethrow;
    }
  }
}
