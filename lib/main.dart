// main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hikenity_app/pages/admin/admin_bottom_nav_bar.dart';
import 'package:hikenity_app/pages/admin/admin_dashboard_page.dart';
//import 'package:hikenity_app/auth_check.dart';
import 'package:hikenity_app/pages/splash_screen.dart';
import 'package:hikenity_app/pages/login_page.dart';
import 'package:hikenity_app/pages/sign_up_page.dart';
import 'package:hikenity_app/pages/forgot_password_page.dart';
import 'package:hikenity_app/pages/participants/home_page.dart';
import 'package:hikenity_app/pages/participants/participant_bottom_nav_bar.dart';
import 'package:hikenity_app/pages/participants/bookmarked_trips_page.dart';
import 'package:hikenity_app/pages/participants/participant_trips_page.dart';
import 'package:hikenity_app/pages/participants/participant_completed_trips_details_page.dart';
import 'package:hikenity_app/pages/participants/participant_ongoing_trips_details_page.dart';
import 'package:hikenity_app/pages/participants/participant_profile_page.dart';
import 'package:hikenity_app/pages/organisers/organiser_main_page.dart';
import 'package:hikenity_app/pages/organisers/organiser_create_trips.dart';
import 'package:hikenity_app/pages/organisers/organiser_trips_page.dart';
import 'package:hikenity_app/pages/organisers/organiser_profile_page.dart';
import 'package:hikenity_app/notification_settings_page.dart';
import 'package:hikenity_app/pages/trip_details_common.dart';
import 'package:hikenity_app/firebase_options.dart';
import 'initialize_messaging.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:location/location.dart';
import 'package:hikenity_app/services/location_tracking_service.dart';

/// Handles background Firebase messages.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

/// Background service entry point.
void onStart(ServiceInstance service) async {
  final locationTrackingService = LocationTrackingService();
  final location = Location();

  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  // Variable to hold incoming data
  String? tripId;
  String? participantId;

  service.on('setData').listen((event) {
    tripId = event?['tripId'];
    participantId = event?['participantId'];
    print('Received tripId: $tripId and participantId: $participantId');
  });

  if (tripId == null || participantId == null) {
    service.stopSelf();
    return;
  }

  location.onLocationChanged.listen((locationData) async {
    if (locationData.latitude != null && locationData.longitude != null) {
      await locationTrackingService.saveParticipantLocation(
        tripId!,
        participantId!,
        locationData.latitude!,
        locationData.longitude!,
      );
      print('Saved location for $participantId in trip $tripId');
    }
  });
}

Future<void> initializeBackgroundService(String tripId, String participantId) async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'location_tracking',
      initialNotificationTitle: 'Location Tracking Active',
      initialNotificationContent: 'Tracking location in the background.',
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      autoStart: true,
    ),
  );

  // Start the service
  await service.startService();

  // Pass data to the service
  service.invoke('setData', {
    'tripId': tripId,
    'participantId': participantId,
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and Stripe
  Stripe.publishableKey = 'pk_test_51Q8t4GHoyDahNOUZwYGLwj03mVqP5KdKKPTdhRcbKT4AOvvYeYRMlAruk0qYbm2LGhM5CnQUxQp83xEZSJXepZEa00pebLyRE2';
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);

  // Register background Firebase Messaging handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Firebase Messaging
  await initializeMessaging();

  // Initialize the background service
  //await initializeBackgroundService();

  runApp(const HikenityApp());
}

class HikenityApp extends StatelessWidget {
  const HikenityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hikenity',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const AuthCheck(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/forgotPassword': (context) => ForgotPasswordPage(),
        '/tripDetail': (context) => const TripDetailsCommon(trip: null, tripId: '', imageUrls: [],),
        '/notificationSettings': (context) => const NotificationSettingsPage(),
        '/home': (context) => const HomePage(),
        '/participantBottomNavBar': (context) => const ParticipantBottomNavBar(),
        '/bookmarkedTrips': (context) => const BookmarkedTripsPage(),
        '/participantTrips': (context) => const ParticipantTripsPage(),
        '/participantCompleted': (context) => const ParticipantCompletedTripsDetailsPage(tripData: {}),
        '/participantOngoing': (context) => const ParticipantOngoingTripsDetailsPage(tripData: {}),
        '/participantProfile': (context) => const ParticipantProfilePage(),
        '/organiserMain': (context) => const OrganiserMainPage(),
        '/organiserTrips': (context) => const OrganiserTripsPage(),
        '/organiserCreateTrips': (context) => const OrganiserCreateTripPage(),
        '/organiserProfile': (context) => const OrganiserProfilePage(),
        '/adminDashboard': (context) => const AdminDashboardPage(),
        '/adminBottomNavBar': (context) => AdminBottomNavBar(),
        
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

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

class RoleBasedRedirect extends StatelessWidget {
  const RoleBasedRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // If no user role found or any error occurs, redirect to LoginPage
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const LoginPage();
        }

        String role = snapshot.data!['role'];
        if (role == 'organizer') {
          return const OrganiserMainPage();
        } else if (role == 'participant') {
          return const ParticipantBottomNavBar();
        } else if (role == 'admin') {
          return AdminBottomNavBar();
        } else {
          return const LoginPage();
        }
      },
    );
  }

  Future<DocumentSnapshot> _getUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
  }
}