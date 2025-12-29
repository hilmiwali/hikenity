//role_selector.dart
// role_selector.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleSelector {
  static void promptRoleSelection(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Your Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.group_add, color: Colors.green),
                title: const Text('Organizer'),
                onTap: () => _assignRole(context, uid, 'organizer'),
              ),
              ListTile(
                leading: Icon(Icons.person_add, color: Colors.blue),
                title: const Text('Participant'),
                onTap: () => _assignRole(context, uid, 'participant'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _assignRole(
    BuildContext context,
    String uid,
    String role,
  ) async {
    try {
      // Fetch existing user data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        // Update only the role field if needed
        if (userDoc['role'] != role) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'role': role,
          });
        }
      } else {
        // Create a new user document with the role
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'role': role,
            'email': user.email,
            'fcmToken': await FirebaseMessaging.instance.getToken(),
          });
        } else {
          throw 'User session is invalid. Please sign in again.';
        }
      }

      // If the user picked 'organizer', also create a doc in 'organisers'
      if (role == 'organizer') {
        // Check if doc exists in 'organisers'; if not, create a new one
        DocumentSnapshot orgDoc = await FirebaseFirestore.instance
            .collection('organisers')
            .doc(uid)
            .get();

        if (!orgDoc.exists) {
          await FirebaseFirestore.instance
              .collection('organisers')
              .doc(uid)
              .set({
            'fullName': '',
            'phoneNumber': '',
            'profileImageUrl': '',
            'certificateUrl': '',
            'isApproved': false,
            'rejectionReason': null,
          });
        }

        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, '/organiserMain');
      } else if (role == 'participant') {
        // No doc in 'organisers' needed
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, '/participantBottomNavBar');
      }
    } catch (e) {
      // Show error message if role assignment fails
      Navigator.pop(context); // Make sure we close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
