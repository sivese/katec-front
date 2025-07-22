import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../config/env_config.dart';
import '../firebase_options.dart';

class FcmService {
  static late final fcmToken;
  static String get _baseUrl => EnvConfig.apiUrl;
  static Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static bool init = false;

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static bool get isAvailable => init;

  static Future<void> initFcmService() async {
    //Firebase module loading
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final notificationSettings = await FirebaseMessaging.instance
        .requestPermission(provisional: true);

    fcmToken = await FirebaseMessaging.instance
        .getToken();

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
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
    init = true;
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print("Handling a background message: ${message.messageId}");
  }

  //Push alarm request
  //Use this only for testing
  static Future<http.Response> requestMessageQueue(String uri, String message) async {
    try {
      final _uri = Uri.parse('$uri/$fcmToken');
      var res = await http.get(
        _uri,
        headers: _defaultHeaders,
      );

      return res;
    }
    catch (e) {
      print('Error sending push request: $e');

      return http.Response("failed", 500);
    }
  }
}