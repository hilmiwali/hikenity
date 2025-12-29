import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> initializeMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request notification permissions
  NotificationSettings settings = await messaging.requestPermission();
  if (settings.authorizationStatus != AuthorizationStatus.authorized) {
    print("User denied notifications permission.");
    return; // Exit if permissions are not granted
  }

  try {
    // Fetch and save FCM token
    String? token = await messaging.getToken();
    await _saveToken(token);

    // Listen for token refresh
    messaging.onTokenRefresh.listen(_saveToken);
  } catch (e) {
    print("Error initializing Firebase Messaging: $e");
  }
}

Future<void> _saveToken(String? token) async {
  if (token == null) return;

  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
        print("FCM Token saved: $token");
      } else {
        print("User document does not exist.");
      }
    } catch (e) {
      print("Error saving FCM token: $e");
    }
  }
}
