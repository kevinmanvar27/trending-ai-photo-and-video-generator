import 'package:dio/dio.dart';
import 'api_service.dart';
import 'api_config.dart';

class SubscriptionApiService {
  final ApiService _apiService = ApiService();
  
  // Get All Subscription Plans
  Future<List<dynamic>> getSubscriptionPlans({
    bool? isActive,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      print('📋 Fetching subscription plans...');
      print('🔗 Endpoint: ${ApiConfig.subscriptionPlans}');
      print('🔗 Full URL: ${ApiConfig.baseUrl}${ApiConfig.subscriptionPlans}');
      
      final queryParams = <String, dynamic>{};
      if (isActive != null) queryParams['is_active'] = isActive ? 1 : 0; // Convert bool to 1/0
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      
      if (queryParams.isNotEmpty) {
        print('🔍 Query Parameters: $queryParams');
      } else {
        print('🔍 No query parameters (fetching all plans)');
      }
      
      final response = await _apiService.get(
        ApiConfig.subscriptionPlans,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      print('✅ Subscription plans fetched successfully');
      print('📊 Full Response: ${response.data}');
      print('📊 Response type: ${response.data.runtimeType}');
      print('📊 Data field: ${response.data['data']}');
      print('📊 Data field type: ${response.data['data'].runtimeType}');
      print('📊 Data length: ${(response.data['data'] as List).length}');
      
      final dataList = response.data['data'] as List;
      
      if (dataList.isEmpty) {
        print('⚠️ WARNING: API returned empty plans array!');
        print('⚠️ Check if:');
        print('   1. Database has plans');
        print('   2. Plans are active (is_active = 1)');
        print('   3. Auth token is valid');
      }
      
      return dataList;
    } catch (e) {
      print('❌ Error fetching subscription plans: $e');
      rethrow;
    }
  }
  
  // Get Subscription Plan by ID
  Future<Map<String, dynamic>> getSubscriptionPlanById(int id) async {
    try {
      final response = await _apiService.get(
        ApiConfig.subscriptionPlanById(id),
      );
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  // Subscribe to a Plan (Purchase Subscription)
  Future<Map<String, dynamic>> subscribe({
    required int subscriptionPlanId,
    required String paymentToken,
    String paymentMethod = 'razorpay',
  }) async {
    try {
      final data = {
        'subscription_plan_id': subscriptionPlanId,
        'payment_token': paymentToken,
        'payment_method': paymentMethod,
      };
      
      print('📤 Purchasing subscription with data: $data');
      print('🔗 Endpoint: ${ApiConfig.subscribe}');
      
      final response = await _apiService.post(
        ApiConfig.subscribe,
        data: data,
      );
      
      print('✅ Subscription purchased successfully');
      print('📊 Response: ${response.data}');
      
      // Response format:
      // {
      //   "success": true,
      //   "data": {
      //     "subscription": {
      //       "id": 5,
      //       "status": "active",
      //       "plan": { "id": 1, "name": "Basic", "coins": 10 },
      //       "expires_at": null,
      //       "remaining_coins": 10
      //     }
      //   },
      //   "message": "Subscription activated successfully"
      // }
      
      return response.data;
    } catch (e) {
      print('❌ Error purchasing subscription: $e');
      rethrow;
    }
  }
  
  // Get My Active Subscription
  Future<Map<String, dynamic>?> getMySubscription() async {
    try {
      print('🔍 Fetching my subscription...');
      print('🔗 Endpoint: ${ApiConfig.mySubscription}');
      
      final response = await _apiService.get(ApiConfig.mySubscription);
      
      print('✅ Subscription response received');
      print('📊 Full Response: ${response.data}');
      print('📊 Response type: ${response.data.runtimeType}');
      print('📊 Has data field? ${response.data.containsKey('data')}');
      print('📊 Data field: ${response.data['data']}');
      print('📊 Data type: ${response.data['data'].runtimeType}');
      
      if (response.data['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        print('📊 Data keys: ${data.keys.toList()}');
        print('📊 Has remaining_coins? ${data.containsKey('remaining_coins')}');
        print('📊 remaining_coins value: ${data['remaining_coins']}');
      }
      
      return response.data['data'];
    } catch (e) {
      print('❌ Error fetching subscription: $e');
      if (e is DioException) {
        print('   Status code: ${e.response?.statusCode}');
        print('   Response data: ${e.response?.data}');
        
        if (e.response?.statusCode == 404) {
          print('   No active subscription (404)');
          return null;
        }
      }
      rethrow;
    }
  }
  
  // Get Subscription History
  Future<List<dynamic>> getSubscriptionHistory() async {
    try {
      final response = await _apiService.get(ApiConfig.subscriptionHistory);
      return response.data['data'] as List;
    } catch (e) {
      rethrow;
    }
  }
  
  // Cancel Subscription
  Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      final response = await _apiService.post(ApiConfig.cancelSubscription);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Create Subscription Plan (Admin)
  Future<Map<String, dynamic>> createSubscriptionPlan({
    required String name,
    required double price,
    required String durationType,
    required int durationValue,
    required int coins,
    String? description,
    List<String>? features,
    bool? isActive,
  }) async {
    try {
      final data = {
        'name': name,
        'price': price,
        'duration_type': durationType,
        'duration_value': durationValue,
        'coins': coins,
        if (description != null) 'description': description,
        if (features != null) 'features': features,
        if (isActive != null) 'is_active': isActive,
      };
      
      final response = await _apiService.post(
        ApiConfig.subscriptionPlans,
        data: data,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update Subscription Plan (Admin)
  Future<Map<String, dynamic>> updateSubscriptionPlan({
    required int id,
    String? name,
    double? price,
    String? durationType,
    int? durationValue,
    int? coins,
    String? description,
    List<String>? features,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (price != null) data['price'] = price;
      if (durationType != null) data['duration_type'] = durationType;
      if (durationValue != null) data['duration_value'] = durationValue;
      if (coins != null) data['coins'] = coins;
      if (description != null) data['description'] = description;
      if (features != null) data['features'] = features;
      if (isActive != null) data['is_active'] = isActive;
      
      final response = await _apiService.put(
        ApiConfig.subscriptionPlanById(id),
        data: data,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete Subscription Plan (Admin)
  Future<void> deleteSubscriptionPlan(int id) async {
    try {
      await _apiService.delete(ApiConfig.subscriptionPlanById(id));
    } catch (e) {
      rethrow;
    }
  }
}
