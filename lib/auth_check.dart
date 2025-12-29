//auth_check.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hikenity_app/main.dart';
import 'package:hikenity_app/pages/participants/home_page.dart';
import 'package:hikenity_app/pages/splash_screen.dart';
import '../initialize_messaging.dart'; // Adjust path as needed

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
  try {
    // First, check the user's role and navigate accordingly
    await _checkUserRoleAndNavigate();

    // Initialize Firebase Messaging for notifications
    await initializeMessaging();
  } catch (e) {
    print("Error during app initialization: $e");

    // Fallback to login in case of any error
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (role == 'organizer') {
              Navigator.pushReplacementNamed(context, '/organiserMain');
            } else if (role == 'participant') {
              Navigator.pushReplacementNamed(context, '/participantBottomNavBar');
            } else if (role == 'admin') {
              Navigator.pushReplacementNamed(context, '/adminDashboard');
            }
          });
        }
      } else {
        // User document doesn't exist; navigate to login
        _navigateToLogin();
      }
    } else {
      // No user is signed in; navigate to login
      _navigateToLogin();
    }
  } catch (e) {
    print("Error during role checking: $e");
    _navigateToLogin();
  }
}

void _navigateToLogin() {
  if (mounted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData) {
          // If the user is signed in, show the role-based screen
          return const RoleBasedRedirect();
        }

        // If the user is not signed in, show the home page or login screen based on context
        return const HomePage(); // Allow guest users to access the HomePage
      },
    );
  }
}
