//notification_settings_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  _NotificationSettingsPageState createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _notificationsEnabled = false;
  bool _tripReminders = false;
  bool _newTripAlerts = false;
  String? _userRole; // To determine if the user is an organizer or participant

  @override
  void initState() {
    super.initState();
    _loadUserRoleAndSettings();
  }

  // Function to load user's role (organizer/participant) and corresponding notification settings
  Future<void> _loadUserRoleAndSettings() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Fetch user role first (assuming you store roles in a 'users' collection)
      DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(user.uid).get();

      if (userSnapshot.exists) {
        setState(() {
          _userRole = userSnapshot['role']; // Assuming user document has a 'role' field
        });

        // Load notification settings based on user role
        String collection = _userRole == 'organizer' ? 'organisers' : 'participant';
        DocumentSnapshot settingsSnapshot = await _firestore.collection(collection).doc(user.uid).get();

        if (settingsSnapshot.exists && settingsSnapshot.data() != null) {
          var data = settingsSnapshot.data() as Map<String, dynamic>;
          setState(() {
            _notificationsEnabled = data['notificationsEnabled'] ?? false;
            _tripReminders = data['tripReminders'] ?? false;
            _newTripAlerts = data['newTripAlerts'] ?? false;
          });
        }
      }
    }
  }

  // Save notification settings to Firestore
  Future<void> _saveNotificationSettings() async {
    User? user = _auth.currentUser;
    if (user != null && _userRole != null) {
      String collection = _userRole == 'organizer' ? 'organisers' : 'participant';
      await _firestore.collection(collection).doc(user.uid).update({
        'notificationsEnabled': _notificationsEnabled,
        'tripReminders': _tripReminders,
        'newTripAlerts': _newTripAlerts,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification settings updated for $_userRole')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Trip Reminders'),
              value: _tripReminders,
              onChanged: _notificationsEnabled
                  ? (bool value) {
                      setState(() {
                        _tripReminders = value;
                      });
                    }
                  : null, // Disable if notifications are not enabled
            ),
            SwitchListTile(
              title: const Text('New Trip Alerts'),
              value: _newTripAlerts,
              onChanged: _notificationsEnabled
                  ? (bool value) {
                      setState(() {
                        _newTripAlerts = value;
                      });
                    }
                  : null, // Disable if notifications are not enabled
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveNotificationSettings,
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
