import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/env_config.dart';
import 'token_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static String get _baseUrl => EnvConfig.apiUrl;
  static const String _locationUpdateEndpoint = '/location/update';

  // 위치 추적 관련 변수들
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastPosition;
  bool _isTracking = false;

  // 위치 변화 감지 임계값 (미터 단위)
  static const int _locationChangeThreshold = 50; // 50미터 이상 변화 시 업데이트

  // 위치 서비스 초기화
  static Future<bool> initializeLocationService() async {
    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('Location services are disabled.');
        }
        return false;
      }

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('Location permissions are denied');
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('Location permissions are permanently denied');
        }
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing location service: $e');
      }
      return false;
    }
  }

  // 위치 추적 시작
  Future<void> startLocationTracking() async {
    if (_isTracking) {
      if (kDebugMode) {
        print('Location tracking is already active');
      }
      return;
    }

    final isInitialized = await initializeLocationService();
    if (!isInitialized) {
      throw Exception('Location service initialization failed');
    }

    try {
      // 현재 위치를 먼저 가져와서 초기 위치로 설정
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 위치 스트림 시작
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: _locationChangeThreshold, // 50미터 이상 변화 시 이벤트 발생
            ),
          ).listen(
            (Position position) {
              _onLocationChanged(position);
            },
            onError: (error) {
              if (kDebugMode) {
                print('Location stream error: $error');
              }
            },
          );

      _isTracking = true;
      if (kDebugMode) {
        print('Location tracking started');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting location tracking: $e');
      }
      throw Exception('Failed to start location tracking: $e');
    }
  }

  // 위치 추적 중지
  Future<void> stopLocationTracking() async {
    if (!_isTracking) {
      return;
    }

    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    _lastPosition = null;

    if (kDebugMode) {
      print('Location tracking stopped');
    }
  }

  // 위치 변화 처리
  Future<void> _onLocationChanged(Position position) async {
    if (_lastPosition == null) {
      _lastPosition = position;
      await _sendLocationUpdate(position);
      return;
    }

    // 위치 변화 거리 계산
    double distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    // 임계값 이상 변화 시에만 업데이트
    if (distance >= _locationChangeThreshold) {
      _lastPosition = position;
      await _sendLocationUpdate(position);
    }
  }

  // 서버에 위치 정보 전송
  Future<void> _sendLocationUpdate(Position position) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        if (kDebugMode) {
          print('No authentication token available');
        }
        return;
      }

      final requestBody = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl$_locationUpdateEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print(
            'Location updated successfully: ${position.latitude}, ${position.longitude}',
          );
        }
      } else {
        if (kDebugMode) {
          print(
            'Failed to update location: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending location update: $e');
      }
    }
  }

  // 현재 위치 한 번만 가져오기
  Future<Position?> getCurrentLocation() async {
    try {
      final isInitialized = await initializeLocationService();
      if (!isInitialized) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
      return null;
    }
  }

  // 위치 추적 상태 확인
  bool get isTracking => _isTracking;

  // 마지막으로 기록된 위치
  Position? get lastPosition => _lastPosition;

  // 서비스 정리
  void dispose() {
    stopLocationTracking();
  }
}
