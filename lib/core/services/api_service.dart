import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Dio _dio;
  String? _authToken;
  
  // Expose Dio instance for advanced usage (e.g., upload progress)
  Dio get dio => _dio;
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ensure token is loaded before making request
        if (_authToken == null) {
          await _loadToken();
        }
        
        // Add auth token if available
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        
        // Print detailed request information
        _logRequest(options);
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Print detailed response information
        _logResponse(response);
        return handler.next(response);
      },
      onError: (error, handler) {
        // Print detailed error information
        _logError(error);
        // Handle errors globally
        _handleError(error);
        return handler.next(error);
      },
    ));
    
    // Load saved token on initialization
    _loadToken();
  }
  
  /// Log API Request Details
  void _logRequest(RequestOptions options) {
    print('\n╔════════════════════════════════════════════════════════════════');
    print('║ 📤 API REQUEST');
    print('╠════════════════════════════════════════════════════════════════');
    print('║ Method: ${options.method}');
    print('║ URL: ${options.baseUrl}${options.path}');
    print('║ Headers: ${_formatJson(options.headers)}');
    
    if (options.queryParameters.isNotEmpty) {
      print('║ Query Parameters: ${_formatJson(options.queryParameters)}');
    }
    
    if (options.data != null) {
      if (options.data is FormData) {
        print('║ Body: [FormData - File Upload]');
        final formData = options.data as FormData;
        print('║ FormData Fields:');
        for (var field in formData.fields) {
          print('║   - ${field.key}: ${field.value}');
        }
        print('║ FormData Files:');
        for (var file in formData.files) {
          print('║   - ${file.key}: ${file.value.filename}');
        }
      } else {
        print('║ Body: ${_formatJson(options.data)}');
      }
    }
    print('╚════════════════════════════════════════════════════════════════\n');
  }
  
  /// Log API Response Details
  void _logResponse(Response response) {
    print('\n╔════════════════════════════════════════════════════════════════');
    print('║ 📥 API RESPONSE');
    print('╠════════════════════════════════════════════════════════════════');
    print('║ Status Code: ${response.statusCode}');
    print('║ Status Message: ${response.statusMessage}');
    print('║ URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}');
    print('║ Response Headers: ${_formatJson(response.headers.map)}');
    print('║ Response Data: ${_formatJson(response.data)}');
    print('╚════════════════════════════════════════════════════════════════\n');
  }
  
  /// Log API Error Details
  void _logError(DioException error) {
    print('\n╔════════════════════════════════════════════════════════════════');
    print('║ ❌ API ERROR');
    print('╠════════════════════════════════════════════════════════════════');
    print('║ Error Type: ${error.type}');
    print('║ Error Message: ${error.message}');
    print('║ URL: ${error.requestOptions.baseUrl}${error.requestOptions.path}');
    
    if (error.response != null) {
      print('║ Status Code: ${error.response?.statusCode}');
      print('║ Status Message: ${error.response?.statusMessage}');
      print('║ Response Data: ${_formatJson(error.response?.data)}');
    }
    
    print('╚════════════════════════════════════════════════════════════════\n');
  }
  
  /// Format JSON for better readability
  String _formatJson(dynamic data) {
    try {
      if (data == null) return 'null';
      const encoder = JsonEncoder.withIndent('  ');
      return '\n' + encoder.convert(data).split('\n').map((line) => '║   $line').join('\n');
    } catch (e) {
      return data.toString();
    }
  }
  
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    if (_authToken != null) {
      print('🔑 Bearer Token Loaded: $_authToken');
    } else {
      print('⚠️ No bearer token found in SharedPreferences');
    }
  }
  
  /// Ensure token is loaded from SharedPreferences
  /// Call this before making authenticated API requests
  Future<void> ensureTokenLoaded() async {
    if (_authToken == null) {
      print('🔄 Reloading bearer token from SharedPreferences...');
      await _loadToken();
    } else {
      print('✅ Bearer token already loaded: $_authToken');
    }
  }
  
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print('🔑 Bearer Token Saved: $token');
  }
  
  Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    print('🗑️ Bearer Token Cleared');
  }
  
  String? get authToken => _authToken;
  
  void _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw ApiException('Connection timeout. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] ?? 'An error occurred';
        
        // Handle 401 Unauthenticated
        if (statusCode == 401) {
          print('❌ Unauthenticated: Token expired or invalid');
          // Clear token and let the app handle redirect to login
          clearAuthToken();
        }
        
        throw ApiException(message, statusCode: statusCode);
      case DioExceptionType.cancel:
        throw ApiException('Request cancelled');
      default:
        throw ApiException('Network error. Please try again.');
    }
  }
  
  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      rethrow;
    }
  }
  
  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      rethrow;
    }
  }
  
  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      rethrow;
    }
  }
  
  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      rethrow;
    }
  }
  
  // Upload file with multipart/form-data
  Future<Response> uploadFile(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      rethrow;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, {this.statusCode});
  
  @override
  String toString() => message;
}
