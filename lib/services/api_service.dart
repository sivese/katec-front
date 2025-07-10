import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP 클라이언트 설정
  final http.Client _client = http.Client();

  // 기본 헤더
  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // API URL 가져오기
  String get _baseUrl => EnvConfig.apiUrl;

  // 로그인 API
  Future<Map<String, dynamic>> login(String userId, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/user/login'),
        headers: _defaultHeaders,
        body: json.encode({'userId': userId, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // 서버에서 반환하는 에러 메시지가 있다면 사용
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ?? 'Login failed: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Login error: $e');
    }
  }

  // 회원가입 API
  Future<Map<String, dynamic>> register(
    String userId,
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/user/register'),
        headers: _defaultHeaders,
        body: json.encode({
          'userId': userId,
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // 서버에서 반환하는 에러 메시지가 있다면 사용
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Registration failed: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Registration error: $e');
    }
  }

  // 여행 목록 조회 예시
  Future<List<Map<String, dynamic>>> getTrips() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/trips'),
        headers: _defaultHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch trips: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get trips error: $e');
    }
  }

  // 사용자 프로필 조회 API
  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      final response = await _client.get(
        Uri.parse('$_baseUrl/user/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // 서버에서 반환하는 에러 메시지가 있다면 사용
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to fetch user profile: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Get user profile error: $e');
    }
  }

  // Health Check API
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/health'),
        headers: _defaultHeaders,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Health check error: $e');
    }
  }

  // 리소스 정리
  void dispose() {
    _client.close();
  }
}
