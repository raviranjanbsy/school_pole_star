import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:school_management/services/auth_service.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground messages
      if (message.notification != null) {
        // You can show a local notification here if you want
        print('Message also contained a notification: \${message.notification}');
      }
    });
  }

  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> saveFcmToken(String userId) async {
    final token = await getFcmToken();
    if (token != null) {
      await _authService.updateUserFcmToken(userId, token);
    }
  }
}