import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Stores screen to navigate to when foreground notification is tapped
  static String? _pendingScreen;
  static String? getPendingScreen() {
    final s = _pendingScreen;
    _pendingScreen = null;
    return s;
  }

  static Future<void> initialize() async {
    // 1. Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup local notifications with tap handler
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Fired when user taps a local notification while app is open
        final screen = response.payload;
        if (screen != null) {
          _pendingScreen = screen;
        }
      },
    );

    // 3. Save FCM token
    await saveTokenToFirestore();

    // 4. Refresh token when it changes
    _messaging.onTokenRefresh.listen((_) => saveTokenToFirestore());

    // 5. Show notification when app is in foreground
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });
  }

  static Future<void> saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final role = userDoc.data()?['role'] ?? 'customer';

    await FirebaseFirestore.instance
        .collection('fcm_tokens')
        .doc(user.uid)
        .set({
      'token': token,
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'shift_schedule',
          'Shift Schedule',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      // Pass screen name as payload so tap navigation works
      payload: message.data['screen'],
    );
  }
}