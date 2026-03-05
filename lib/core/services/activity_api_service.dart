import 'api_service.dart';
import 'api_config.dart';

class ActivityApiService {
  final ApiService _apiService = ApiService();
  
  // Start Session
  Future<Map<String, dynamic>> startSession({
    String deviceType = 'mobile',
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.activityStart,
        data: {'device_type': deviceType},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // End Session
  Future<Map<String, dynamic>> endSession(int sessionId) async {
    try {
      final response = await _apiService.post(
        ApiConfig.activityEnd,
        data: {'session_id': sessionId},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get Activity History
  Future<Map<String, dynamic>> getActivityHistory({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.activityHistory,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
}
