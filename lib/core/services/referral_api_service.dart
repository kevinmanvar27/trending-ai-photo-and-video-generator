import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'api_service.dart';

class ReferralApiService {
  final ApiService _apiService = ApiService();

  // Get referral information
  Future<Map<String, dynamic>> getReferralInfo() async {
    try {
      final token = _apiService.authToken;
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('🔍 Fetching referral info...');
      print('🔗 Endpoint: ${ApiConfig.baseUrl}/referral/info');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/referral/info'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Referral info fetched successfully');
        return data;
      } else {
        throw Exception('Failed to fetch referral info: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching referral info: $e');
      rethrow;
    }
  }

  // Get list of referred users
  Future<List<Map<String, dynamic>>> getReferralList() async {
    try {
      final token = _apiService.authToken;
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('🔍 Fetching referral list...');
      print('🔗 Endpoint: ${ApiConfig.baseUrl}/referral/list');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/referral/list'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Referral list fetched successfully');
        
        if (data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Failed to fetch referral list: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching referral list: $e');
      rethrow;
    }
  }

  // Redeem referral coins (Method 1: with referral_id)
  Future<Map<String, dynamic>> redeemReferralById(int referralId) async {
    try {
      final token = _apiService.authToken;
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('💰 Redeeming referral coins...');
      print('🔗 Endpoint: ${ApiConfig.baseUrl}/referral/redeem');
      print('📝 Referral ID: $referralId');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/referral/redeem'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'referral_id': referralId,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Referral coins redeemed successfully');
        print('💰 Coins earned: ${data['data']?['coins_earned']}');
        print('💰 New balance: ${data['data']?['new_balance']}');
        return data;
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Referral already redeemed');
      } else {
        throw Exception('Failed to redeem referral: ${response.body}');
      }
    } catch (e) {
      print('❌ Error redeeming referral: $e');
      rethrow;
    }
  }

  // Redeem referral coins (Method 2: with coins amount - if API supports it)
  Future<Map<String, dynamic>> redeemReferralByCoins(String coins) async {
    try {
      final token = _apiService.authToken;
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('💰 Redeeming referral coins...');
      print('🔗 Endpoint: ${ApiConfig.baseUrl}/referral/redeem');
      print('📝 Coins: $coins');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/referral/redeem'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'coins': coins,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Referral coins redeemed successfully');
        return data;
      } else {
        throw Exception('Failed to redeem referral: ${response.body}');
      }
    } catch (e) {
      print('❌ Error redeeming referral: $e');
      rethrow;
    }
  }

  // Redeem all pending referrals
  Future<Map<String, dynamic>> redeemAllPendingReferrals() async {
    try {
      print('💰 Redeeming all pending referrals...');
      
      // Get list of referrals
      final referrals = await getReferralList();
      
      // Filter pending referrals
      final pendingReferrals = referrals.where((ref) => ref['status'] == 'pending').toList();
      
      if (pendingReferrals.isEmpty) {
        print('⚠️ No pending referrals to redeem');
        return {
          'success': true,
          'message': 'No pending referrals',
          'data': {
            'coins_earned': 0,
            'referrals_redeemed': 0,
          }
        };
      }

      print('📋 Found ${pendingReferrals.length} pending referrals');

      int totalCoinsEarned = 0;
      int successfulRedemptions = 0;

      // Redeem each pending referral
      for (var referral in pendingReferrals) {
        try {
          final result = await redeemReferralById(referral['id']);
          if (result['success'] == true) {
            totalCoinsEarned += (result['data']?['coins_earned'] ?? 0) as int;
            successfulRedemptions++;
          }
        } catch (e) {
          print('⚠️ Failed to redeem referral ${referral['id']}: $e');
          // Continue with next referral
        }
      }

      print('✅ Redeemed $successfulRedemptions referrals');
      print('💰 Total coins earned: $totalCoinsEarned');

      return {
        'success': true,
        'message': 'Referrals redeemed successfully',
        'data': {
          'coins_earned': totalCoinsEarned,
          'referrals_redeemed': successfulRedemptions,
        }
      };
    } catch (e) {
      print('❌ Error redeeming all referrals: $e');
      rethrow;
    }
  }

  // Validate referral code (before registration)
  Future<Map<String, dynamic>> validateReferralCode(String code) async {
    try {
      print('🔍 Validating referral code: $code');
      print('🔗 Endpoint: ${ApiConfig.baseUrl}/referral/validate');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/referral/validate'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'referral_code': code,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Referral code validated successfully');
        return data;
      } else {
        throw Exception('Invalid referral code');
      }
    } catch (e) {
      print('❌ Error validating referral code: $e');
      rethrow;
    }
  }

  // Apply referral code (for existing users)
  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    try {
      final token = _apiService.authToken;
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('📤 Applying referral code: $code');
      print('🔗 Endpoint: ${ApiConfig.baseUrl}/referral/apply');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/referral/apply'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'referral_code': code,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Referral code applied successfully');
        print('🎁 Bonus coins awarded: ${data['data']?['bonus_coins_awarded']}');
        return data;
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to apply referral code');
      } else {
        throw Exception('Failed to apply referral code: ${response.body}');
      }
    } catch (e) {
      print('❌ Error applying referral code: $e');
      rethrow;
    }
  }

  // Get referral statistics
  Future<Map<String, dynamic>> getReferralStats() async {
    try {
      final token = _apiService.authToken;
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('🔍 Fetching referral stats...');
      print('🔗 Endpoint: ${ApiConfig.baseUrl}/referral/stats');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/referral/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Referral stats fetched successfully');
        return data;
      } else {
        throw Exception('Failed to fetch referral stats: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching referral stats: $e');
      rethrow;
    }
  }
}
