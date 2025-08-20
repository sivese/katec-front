import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mercury_front/services/fcm_service.dart';
import '../config/env_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP client configuration
  final http.Client _client = http.Client();

  // Default headers
  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get API URL
  String get _baseUrl => EnvConfig.apiUrl;

  // Login API
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
        // Use server error message if available
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

  // Registration API
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
        // Use server error message if available
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

  // Get trips list example
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

  // Get user profile API
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
        // Use server error message if available
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

  // Update user profile API (name only)
  Future<Map<String, dynamic>> updateUserProfile(
    String token,
    String name,
  ) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      final requestBody = {'name': name};

      final response = await _client.put(
        Uri.parse('$_baseUrl/user/profile'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Use server error message if available
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to update user profile: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Update user profile error: $e');
    }
  }

  // Change password API
  Future<Map<String, dynamic>> changePassword(
    String token,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      final requestBody = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };

      final response = await _client.put(
        Uri.parse('$_baseUrl/user/profile'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Use server error message if available
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to change password: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Change password error: $e');
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

  // Push Message API
  Future<Map<String, dynamic>> pushMessage(
    String title,
    String message,
    DateTime pushTime,
  ) async {
    if (FcmService.isAvailable == false) {
      throw Exception("Platform doesn't support Firebase Cloud Messaging");
    }

    try {
      final token = FcmService.fcmToken;
      final requestBody = {
        'Title': title,
        'Message': message,
        'PushTime': pushTime.toUtc().toIso8601String(),
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/push_message/$token'),
        headers: _defaultHeaders,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to push message alarm: ${response.statusCode}';

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }

      throw Exception('Push message error: $e');
    }
  }

  Future<Map<String, dynamic>> createTrip(
    String token,
    String tripName,
    DateTime startDate,
    DateTime endDate,
    String destination,
  ) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      final requestBody = {
        'tripName': tripName,
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
        'destination': destination,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/trip/create'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Use server error message if available
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to create trip: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Create trip error: $e');
    }
  }

  // Get Trip List API
  Future<Map<String, dynamic>> getTripList(String token) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      final response = await _client.get(
        Uri.parse('$_baseUrl/trip/list'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Debug: Print response data
        print('=== Trip List API Response ===');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('Parsed Data: $responseData');

        // id 필드 구조 상세 분석
        final trips = responseData['trips'] as List<dynamic>? ?? [];
        for (int i = 0; i < trips.length; i++) {
          final trip = trips[i] as Map<String, dynamic>;
          print('Trip $i ID structure: ${trip['id']}');
          print('Trip $i ID type: ${trip['id'].runtimeType}');
          if (trip['id'] is Map) {
            final idMap = trip['id'] as Map;
            print('Trip $i ID keys: ${idMap.keys.toList()}');
            print('Trip $i ID values: ${idMap.values.toList()}');
          }
        }

        return responseData;
      } else {
        // Use server error message if available
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to fetch trip list: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Get trip list error: $e');
    }
  }

  // Delete Trip API
  Future<Map<String, dynamic>> deleteTrip(String token, String tripId) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      final response = await _client.delete(
        Uri.parse('$_baseUrl/trip/remove/$tripId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Use server error message if available
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to delete trip: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Delete trip error: $e');
    }
  }

  // Create Accommodation API
  Future<Map<String, dynamic>> createAccommodation(
    String token,
    String tripId,
    DateTime date,
    String accommodationName,
    String? description,
    String? bookingReference,
    DateTime checkInDate,
    DateTime checkOutDate,
  ) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      final requestBody = {
        'tripId': tripId,
        'date': date.toUtc().toIso8601String(),
        'accommodationName': accommodationName,
        'description': description ?? '',
        'bookingReference': bookingReference ?? '',
        'checkInDate': checkInDate.toUtc().toIso8601String(),
        'checkOutDate': checkOutDate.toUtc().toIso8601String(),
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/accommodation/create'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Use server error message if available
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to create accommodation: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Create accommodation error: $e');
    }
  }

  // Trip 상세 조회 API
  Future<Map<String, dynamic>> getTripDetails(
    String token,
    String tripId,
  ) async {
    final headers = Map<String, String>.from(_defaultHeaders);
    headers['Authorization'] = 'Bearer $token';

    final response = await _client.get(
      Uri.parse('$_baseUrl/trip/$tripId/details'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorBody = json.decode(response.body);
      final errorMessage =
          errorBody['message'] ??
          'Failed to fetch trip details:  {response.statusCode}';
      throw Exception(errorMessage);
    }
  }

  // Delete Accommodation API
  Future<Map<String, dynamic>> deleteAccommodation(
    String token,
    String accommodationId,
  ) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      final response = await _client.delete(
        Uri.parse('$_baseUrl/accommodation/$accommodationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Use server error message if available
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to delete accommodation: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Delete accommodation error: $e');
    }
  }

  // Update Accommodation API
  Future<Map<String, dynamic>> updateAccommodation(
    String token,
    String accommodationId, {
    required String tripId,
    required String accommodationName,
    String? description,
    String? bookingReference,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required DateTime date,
  }) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      final requestBody = {
        'tripId': tripId,
        'accommodationName': accommodationName,
        'description': description ?? '',
        'bookingReference': bookingReference ?? '',
        'checkInDate': checkInDate.toUtc().toIso8601String(),
        'checkOutDate': checkOutDate.toUtc().toIso8601String(),
        'date': date.toUtc().toIso8601String(),
      };

      final response = await _client.put(
        Uri.parse('$_baseUrl/accommodation/$accommodationId'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to update accommodation:  {response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Update accommodation error: $e');
    }
  }

  // Transportation 생성 API
  Future<Map<String, dynamic>> createTransportation(
    String token,
    String tripId,
    String transportationType,
    String departure,
    String destination,
    DateTime departureDateTime,
    DateTime arrivalDateTime,
    String? bookingReference,
  ) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      final requestBody = {
        'transportationType': transportationType,
        'departure': departure,
        'destination': destination,
        'departureDateTime': departureDateTime.toUtc().toIso8601String(),
        'arrivalDateTime': arrivalDateTime.toUtc().toIso8601String(),
        'bookingReference': bookingReference ?? '',
        'tripId': tripId,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/transportation/create'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // 서버에서 반환하는 에러 메시지가 있다면 사용
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to create transportation: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Create transportation error: $e');
    }
  }

  // Transportation 수정 API
  Future<Map<String, dynamic>> updateTransportation(
    String token,
    String transportationId,
    String transportationType,
    String departure,
    String destination,
    DateTime departureDateTime,
    DateTime arrivalDateTime,
    String? bookingReference,
    String tripId,
  ) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      final requestBody = {
        'transportationType': transportationType,
        'departure': departure,
        'destination': destination,
        'departureDateTime': departureDateTime.toUtc().toIso8601String(),
        'arrivalDateTime': arrivalDateTime.toUtc().toIso8601String(),
        'bookingReference': bookingReference ?? '',
        'tripId': tripId,
        'date':
            '${departureDateTime.year}-${departureDateTime.month.toString().padLeft(2, '0')}-${departureDateTime.day.toString().padLeft(2, '0')}T00:00:00',
      };

      final response = await _client.put(
        Uri.parse('$_baseUrl/transportation/$transportationId'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to update transportation: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Update transportation error: $e');
    }
  }

  // Transportation 삭제 API
  Future<void> deleteTransportation(
    String token,
    String transportationId,
  ) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';
      final response = await _client.delete(
        Uri.parse('$_baseUrl/transportation/$transportationId'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to delete transportation:  {response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Delete transportation error: $e');
    }
  }

  // Other 스케줄 생성 API
  Future<Map<String, dynamic>> createOtherSchedule(
    String token,
    String tripId,
    String title,
    String location,
    DateTime date,
    String startTime,
    String endTime,
    String? description,
  ) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      final requestBody = {
        'title': title,
        'location': location,
        'date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'startTime': startTime,
        'endTime': endTime,
        'description': description ?? '',
        'tripId': tripId,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/subtrips/other/create'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // 서버에서 반환하는 에러 메시지가 있다면 사용
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to create other schedule: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Create other schedule error: $e');
    }
  }

  // Other Trip(기타 일정) 수정 API
  Future<Map<String, dynamic>> updateOtherSchedule(
    String token,
    String otherSubTripId,
    String title,
    String location,
    DateTime date,
    String startTime,
    String endTime,
    String? description,
    String tripId,
  ) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';
      final requestBody = {
        'title': title,
        'location': location,
        'date': date.toUtc().toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'description': description ?? '',
        'tripId': tripId,
      };
      final response = await _client.put(
        Uri.parse('$_baseUrl/subtrips/other/$otherSubTripId'),
        headers: headers,
        body: json.encode(requestBody),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to update other schedule: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Update other schedule error: $e');
    }
  }

  // Other Trip(기타 일정) 삭제 API
  Future<void> deleteOtherSchedule(String token, String otherSubTripId) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';
      final response = await _client.delete(
        Uri.parse('$_baseUrl/subtrips/other/$otherSubTripId'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to delete other schedule: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Delete other schedule error: $e');
    }
  }

  // Dining 스케줄 생성 API
  Future<Map<String, dynamic>> createDiningSchedule(
    String token,
    String tripId,
    String title,
    String location,
    DateTime date,
    String startTime,
    String endTime,
    String? description,
  ) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      final requestBody = {
        'title': title,
        'location': location,
        'date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'startTime': startTime,
        'endTime': endTime,
        'description': description ?? '',
        'tripId': tripId,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/subtrips/dining/create'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // 서버에서 반환하는 에러 메시지가 있다면 사용
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to create dining schedule: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Create dining schedule error: $e');
    }
  }

  // Dining Trip(식당 일정) 수정 API
  Future<Map<String, dynamic>> updateDiningSchedule(
    String token,
    String diningSubTripId,
    String title,
    String location,
    DateTime date,
    String startTime,
    String endTime,
    String? description,
    String tripId,
  ) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';
      final requestBody = {
        'title': title,
        'location': location,
        'date': date.toUtc().toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'description': description ?? '',
        'tripId': tripId,
      };
      final response = await _client.put(
        Uri.parse('$_baseUrl/subtrips/dining/$diningSubTripId'),
        headers: headers,
        body: json.encode(requestBody),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to update dining schedule: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Update dining schedule error: $e');
    }
  }

  // Dining Trip(식당 일정) 삭제 API
  Future<void> deleteDiningSchedule(
    String token,
    String diningSubTripId,
  ) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';
      final response = await _client.delete(
        Uri.parse('$_baseUrl/subtrips/dining/$diningSubTripId'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to delete dining schedule: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Delete dining schedule error: $e');
    }
  }

  // Trip 정보 업데이트 API
  Future<Map<String, dynamic>> updateTrip(
    String token,
    String tripId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      final response = await _client.put(
        Uri.parse('$_baseUrl/trip/$tripId'),
        headers: headers,
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Failed to update trip: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Update trip error: $e');
    }
  }

  // 리소스 정리
  void dispose() {
    _client.close();
  }
}
