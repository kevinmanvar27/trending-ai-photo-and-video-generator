import 'package:dio/dio.dart';
import 'api_service.dart';
import 'api_config.dart';

class SubmissionApiService {
  final ApiService _apiService = ApiService();
  
  // Get All Submissions
  Future<Map<String, dynamic>> getSubmissions({
    String? status,
    String? outputType,
    int? templateId,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (status != null) queryParams['status'] = status;
      if (outputType != null) queryParams['output_type'] = outputType;
      if (templateId != null) queryParams['template_id'] = templateId;
      
      final response = await _apiService.get(
        ApiConfig.submissions,
        queryParameters: queryParams,
      );
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  // Get Submission by ID
  Future<Map<String, dynamic>> getSubmissionById(int id) async {
    try {
      final response = await _apiService.get(ApiConfig.submissionById(id));
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  // Create Submission
  Future<Map<String, dynamic>> createSubmission({
    required int templateId,
    required String originalImagePath,
    required String outputType,
    ProgressCallback? onUploadProgress,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'template_id': templateId,
        'output_type': outputType,
        'original_image': await MultipartFile.fromFile(
          originalImagePath,
          filename: originalImagePath.split('/').last,
        ),
      });
      
      final response = await _apiService.uploadFile(
        ApiConfig.submissions,
        formData: formData,
        onSendProgress: onUploadProgress,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update Submission Status
  Future<Map<String, dynamic>> updateSubmissionStatus({
    required int id,
    required String status,
    double? processingTime,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': status,
      };
      if (processingTime != null) data['processing_time'] = processingTime;
      
      final response = await _apiService.put(
        ApiConfig.updateSubmissionStatus(id),
        data: data,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete Submission
  Future<void> deleteSubmission(int id) async {
    try {
      await _apiService.delete(ApiConfig.submissionById(id));
    } catch (e) {
      rethrow;
    }
  }
  
  // Get Submission Statistics
  Future<Map<String, dynamic>> getSubmissionStatistics() async {
    try {
      final response = await _apiService.get(ApiConfig.submissionStatistics);
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  // Get Recent Submissions
  Future<List<dynamic>> getRecentSubmissions({int limit = 10}) async {
    try {
      final response = await _apiService.get(
        ApiConfig.recentSubmissions,
        queryParameters: {'limit': limit},
      );
      return response.data['data'] as List;
    } catch (e) {
      rethrow;
    }
  }
}
