//notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const String channelId = 'default_channel_id';
const String channelName = 'Default Notifications';
const String channelDescription = 'This channel is used for default notifications.';

// Initialize notification settings
Future<void> initializeNotificationSettings() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    channelId, // Channel ID
    channelName, // Channel name
    description: channelDescription, // Channel description
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  print('Notification settings initialized successfully.');
}

// Show a notification when received
Future<void> showNotification(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    print('Notification displayed: ${notification.title}');
  }
}

// Handle app-specific navigation or actions when a notification is tapped
void handleNotificationTap() {
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data['type'] == 'booking') {
      // Navigate to organiser's trip details
      print("Navigate to organiser's trip details");
    } else if (message.data['type'] == 'approval') {
      // Navigate to admin approval page
      print("Navigate to admin approval page");
    }
  });
}
