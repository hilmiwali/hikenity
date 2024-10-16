//role_selector.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleSelector {
  static void promptRoleSelection(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Your Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Organizer'),
                onTap: () => _assignRole(context, userId, 'organizer'),
              ),
              ListTile(
                title: const Text('Participant'),
                onTap: () => _assignRole(context, userId, 'participant'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _assignRole(
      BuildContext context, String userId, String role) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'role': role,
        'email': FirebaseAuth.instance.currentUser!.email,
      });
      if (role == 'organizer') {
        Navigator.pushReplacementNamed(context, '/OrganiserTripsPage');
      } else if (role == 'participant') {
        Navigator.pushReplacementNamed(context, '/HomePage');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving role: $e')),
      );
    }
  }
}
