import 'api_service.dart';
import 'api_config.dart';

class ContactApiService {
  final ApiService _apiService = ApiService();
  
  // Sync Device Contacts
  Future<Map<String, dynamic>> syncContacts(
    List<Map<String, dynamic>> contacts,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConfig.contacts,
        data: {'contacts': contacts},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get Synced Contacts
  Future<Map<String, dynamic>> getContacts({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.contacts,
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
  
  // Delete All Contacts
  Future<Map<String, dynamic>> deleteAllContacts() async {
    try {
      final response = await _apiService.delete(ApiConfig.contacts);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
