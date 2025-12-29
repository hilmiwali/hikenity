//login_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../role_selector.dart';
import 'forgot_password_page.dart';
import 'participants/home_page.dart';

class LoginPage extends StatefulWidget {
  final String? redirectTo;
  const LoginPage({super.key, this.redirectTo});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState(); // Check if the user is already signed in
  }

  Future<void> _checkAuthState() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _updateFcmToken(user.uid); // Update FCM token for authenticated user
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc['role'] ?? ''; // Default to empty string if 'role' doesn't exist
        if (role == 'organizer') {
          Navigator.pushReplacementNamed(context, '/organiserMain');
        } else if (role == 'participant') {
          if (widget.redirectTo != null) {
            Navigator.pushReplacementNamed(context, widget.redirectTo!);
          } else {
            Navigator.pushReplacementNamed(context, '/participantBottomNavBar');
          }
        } else if (role == 'admin') { // Check for admin role
                Navigator.pushReplacementNamed(context, '/adminBottomNavBar');
        } else {
          // Role is undefined, prompt role selection
          RoleSelector.promptRoleSelection(context, user.uid);
        }
      } else {
        // Handle missing user document gracefully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data not found. Please contact support.')),
        );
      }
    }
  }

  Future<void> _signInWithEmailAndPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        // If email is not verified, sign out the user
        await _auth.signOut();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please verify your email before logging in.'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Update FCM token in Firestore
      await _updateFcmToken(user!.uid);

      // Check if user exists in Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc['role'] ?? ''; // Safe retrieval of role
        if (role == 'organizer') {
          Navigator.pushReplacementNamed(context, '/organiserMain');
        } else if (role == 'participant') {
          if (widget.redirectTo != null) {
            Navigator.pushReplacementNamed(context, widget.redirectTo!);
          } else {
            Navigator.pushReplacementNamed(context, '/participantBottomNavBar');
          }
        } else if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/adminBottomNavBar'); // Redirect to admin page
      }
      } else {
        RoleSelector.promptRoleSelection(context, user.uid);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        ///serverClientId:
           //   '464200726815-36h81q2gka2nf5k348npvkuj5m2e3jig.apps.googleusercontent.com',
        scopes: ['email'],
        signInOption: SignInOption.standard,  // Make sure it's set to standard to allow account picking
      );

      await googleSignIn.signOut(); // Clear any existing session
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Update FCM token
      await _updateFcmToken(userCredential.user!.uid);

      // Check user role
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return; // Check if widget is still mounted

      if (userDoc.exists) {
        String role = userDoc.get('role') as String? ?? '';
        if (!mounted) return;
        
        switch (role) {
          case 'organizer':
            Navigator.pushReplacementNamed(context, '/organiserMain');
            break;
          case 'participant':
            Navigator.pushReplacementNamed(context, 
              widget.redirectTo ?? '/participantBottomNavBar');
            break;
          case 'admin':
            Navigator.pushReplacementNamed(context, '/adminBottomNavBar');
            break;
        }
      } else {
        if (!mounted) return;
        RoleSelector.promptRoleSelection(context, userCredential.user!.uid);
      }

    } catch (e) {
      if (!mounted) return;
      print('Google Sign-In error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateFcmToken(String userId) async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': fcmToken,
        });
        print('FCM Token updated: $fcmToken');
      } else {
        print('No FCM token found');
      }
    } catch (e) {
      print('Failed to update FCM token: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Hikenity',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome Back!',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Fill in the form",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.grey[200],
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signInWithEmailAndPassword,
                        child: const Text('Sign In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ForgotPasswordPage()),
                    );
                  },
                  child: const Text('Forgot Password'),
                ),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('OR'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : OutlinedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata),
                        label: const Text('Continue with Google'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  },
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    print('Sign Up button pressed');
                    Navigator.pushNamed(
                      context, '/signup',);
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Sign Up here',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}