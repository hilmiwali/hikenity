//main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth to check login status
//import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hikenity_app/pages/forgot_password_page.dart';
import 'package:hikenity_app/pages/participants/bookmarked_trips_page.dart';
import 'package:hikenity_app/pages/participants/participant_bottom_nav_bar.dart';

import 'firebase_options.dart'; 
import 'pages/participants/participant_completed_trips_details_page.dart';
import 'pages/participants/participant_ongoing_trips_details_page.dart';
import 'pages/participants/participant_profile_page.dart';
import 'pages/participants/participant_trips_page.dart';
import 'pages/splash_screen.dart';
import 'pages/login_page.dart';
import 'pages/sign_up_page.dart';
import 'pages/participants/home_page.dart';
import 'pages/organisers/organiser_create_trips.dart';
import 'pages/organisers/organiser_main_page.dart';
import 'pages/organisers/organiser_profile_page.dart';
import 'pages/organisers/organiser_trips_page.dart';
import 'notification_settings_page.dart';
import 'pages/trip_details_common.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_test_51Q8t4GHoyDahNOUZwYGLwj03mVqP5KdKKPTdhRcbKT4AOvvYeYRMlAruk0qYbm2LGhM5CnQUxQp83xEZSJXepZEa00pebLyRE2';
  //Load our .env file that contains our Stripe Secret key
  //await dotenv.load(fileName: "assets/.env");
  //Stripe.publishableKey = dotenv.env['pk_test_51Q8t4GHoyDahNOUZwYGLwj03mVqP5KdKKPTdhRcbKT4AOvvYeYRMlAruk0qYbm2LGhM5CnQUxQp83xEZSJXepZEa00pebLyRE2'] ?? '';
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HikenityApp());
}

class HikenityApp extends StatelessWidget {
  const HikenityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hikenity',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      // Update the initialRoute to check authentication state
      home: const AuthCheck(), // Added AuthCheck to handle user session
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/forgotPassword': (context) => ForgotPasswordPage(),

        '/tripDetail': (context) => const TripDetailsCommon(trip: null, tripId: '',),
        '/notificationSettings': (context) => const NotificationSettingsPage(),

        //Participant Interfaces
          '/home': (context) => const HomePage(),
          '/participantBottomNavBar': (context) => const ParticipantBottomNavBar(),
          '/bookmarkedTrips': (context) => const BookmarkedTripsPage(),
          '/participantTrips': (context) => const ParticipantTripsPage(),
          '/participantCompleted': (context) => const ParticipantCompletedTripsDetailsPage(tripData: {},),
          '/participantOngoing': (context) => const ParticipantOngoingTripsDetailsPage(tripData: {},),
          '/participantProfile': (context) => const ParticipantProfilePage(),

        //Organiser Intefaces
          '/organiserMain': (context) => const OrganiserMainPage(),
          '/organiserTrips': (context) => const OrganiserTripsPage(),
          '/organiserCreateTrips': (context) => const OrganiserCreateTripPage(),
          '/organiserProfile': (context) => const OrganiserProfilePage(),
      },
      onGenerateRoute: (settings) {
        // Handle any undefined routes here
        return MaterialPageRoute(builder: (context) => const LoginPage());
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => const LoginPage());
      },
    );
  }
}

// Widget to check the authentication state
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkUserStatus(); // Check user authentication status at the start
  }

  // Function to check if the user is logged in
  void _checkUserStatus() {
  _user = FirebaseAuth.instance.currentUser;

  // Adding delay (e.g., for splash screen)
  Future.delayed(const Duration(seconds: 2), () {
    if (!mounted) return;  // Check if the widget is still mounted
    if (_user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return const SplashScreen(); // Show splash screen while checking authentication
  }
}
