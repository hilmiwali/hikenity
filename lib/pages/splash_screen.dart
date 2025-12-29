// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../initialize_messaging.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp(); // Directly initialize without using microtask
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize Firebase Messaging for notifications
      await initializeMessaging();

      // Check if the user is already logged in
      await _checkUserRoleAndNavigate();
    } catch (e) {
      print("Error during app initialization: $e");

      // Fallback to a home screen for non-login users
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          Navigator.pushReplacementNamed(context, '/home'); // Go to home screen directly
        });
      }
    }
  }

  Future<void> _checkUserRoleAndNavigate() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String role = userDoc['role'];
          if (mounted) {
            if (role == 'organizer') {
              Navigator.pushReplacementNamed(context, '/organiserMain');
            } else if (role == 'participant') {
              Navigator.pushReplacementNamed(context, '/participantBottomNavBar');
            }
            else if (role == 'admin') {
              Navigator.pushReplacementNamed(context, '/adminBottomNavBar');
            }
          }
        } else {
          // User document doesn't exist; navigate to login
          _navigateToLogin();
        }
      } else {
        // No user is signed in; proceed to the home screen
        _navigateToHome();
      }
    } catch (e) {
      print("Error during role checking: $e");
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/hutan.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/image.png', width: 150, height: 150),
              const SizedBox(height: 20),
              const Text(
                'Hikenity',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
