import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FcmService {
  static late final fcmToken;

  static Future<void> initFcmService() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Unsupported platform');
    }

    fcmToken = await FirebaseMessaging.instance
        .getToken();

    if (kDebugMode) {
      print("FCM Token initialized, $fcmToken");
    }
  }

  static Future<http.Response> requestMessageQueue(String uri, String message) async {
    return await http.post(
      Uri.parse(uri),
      body: {
        'token' : fcmToken,
        'message' : message,
      }
    );
  }
}