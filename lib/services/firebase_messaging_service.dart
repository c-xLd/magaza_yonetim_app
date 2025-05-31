import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/logger.dart';

// Firebase kurulumu yapılana kadar bu dosya boş bırakıldı.
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Bu kanal önemli bildirimler için kullanılır',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    try {
      await _notifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      FirebaseMessaging.onMessage.listen(_showNotification);
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    } catch (e) {
      AppLogger.e('Bildirim başlatma hatası', e);
      rethrow;
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    try {
      await _notifications.show(
        0,
        message.notification?.title ?? 'Yeni Bildirim',
        message.notification?.body ?? 'Bildirim içeriği',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          ),
        ),
      );
    } catch (e) {
      AppLogger.e('Bildirim gösterilemedi', e);
    }
  }

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    try {
      AppLogger.i('Arka planda bildirim alındı: ${message.messageId}');
      // Arka planda bildirimi göster
      await _showNotification(message);
    } catch (e) {
      AppLogger.e('Arka planda bildirim gösterilemedi', e);
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  Future<void> sendNotification({
    required String title,
    required String body,
    required String token,
    String? imageUrl,
  }) async {
    try {
      final message = <String, dynamic>{
        'notification': <String, String>{
          'title': title,
          'body': body,
        },
        'token': token,
      };

      if (imageUrl != null) {
        (message['notification'] as Map<String, String>)['image'] = imageUrl;
      }

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=YOUR_SERVER_KEY',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      AppLogger.e('Bildirim gönderme hatası', e);
    }
  }
}
