import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../config/env_config.dart';
import '../firebase_options.dart';

class FcmService {
  static late final fcmToken;
  static String get _baseUrl => EnvConfig.apiUrl;
  static Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initFcmService() async {
    // 웹 플랫폼에서는 FCM 기능을 지원하지 않으므로 초기화를 건너뜀
    if (kIsWeb) {
      if (kDebugMode) {
        print(
          "FCM service is not supported on web platform - using dummy implementation",
        );
      }
      // 웹에서는 더미 토큰 설정
      fcmToken = "web_dummy_token";
      return;
    }

    // 모바일 플랫폼에서만 FCM 초기화 진행
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (kDebugMode) {
        print("FCM service is only supported on Android and iOS platforms");
      }
      return;
    }

    //Firebase module loading
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final notificationSettings = await FirebaseMessaging.instance
        .requestPermission(provisional: true);

    fcmToken = await FirebaseMessaging.instance.getToken();

    if (kDebugMode) {
      print("FCM Token initialized, $fcmToken");
    }

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    //Local push alarm initialize
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel_id',
              'Default',
              channelDescription: '기본 알림 채널',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    // 웹에서는 백그라운드 메시지 핸들러를 실행하지 않음
    if (kIsWeb) return;

    await Firebase.initializeApp();
    print("Handling a background message: ${message.messageId}");
  }

  //Push alarm request
  //Use this only for testing
  static Future<http.Response> requestMessageQueue(
    String uri,
    String message,
  ) async {
    // 웹에서는 푸시 알림 요청을 지원하지 않음
    if (kIsWeb) {
      if (kDebugMode) {
        print("Push notification requests are not supported on web platform");
      }
      return http.Response("Web platform not supported", 501);
    }

    try {
      final _uri = Uri.parse('$uri/$fcmToken');
      var res = await http.get(_uri, headers: _defaultHeaders);

      return res;
    } catch (e) {
      print('Error sending push request: $e');

      return http.Response("failed", 500);
    }
  }

  // 웹에서 FCM 토큰을 가져오는 메서드 (더미 구현)
  static String? getFcmToken() {
    if (kIsWeb) {
      return "web_dummy_token";
    }
    return fcmToken;
  }

  // 웹에서 알림 권한 요청 (더미 구현)
  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb) {
      if (kDebugMode) {
        print(
          "Notification permission request is not supported on web platform",
        );
      }
      return false;
    }

    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }
}
