//participant_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'participant_trips_page.dart';
import 'participant_profile_page.dart';
import 'dashboard_page.dart';

class ParticipantBottomNavBar extends StatefulWidget {
  const ParticipantBottomNavBar({super.key});

  @override
  _ParticipantBottomNavBarState createState() => _ParticipantBottomNavBarState();
}

class _ParticipantBottomNavBarState extends State<ParticipantBottomNavBar> {
  int _currentIndex = 0;

  // List of the pages for each tab
  final List<Widget> _pages = [
    const HomePage(),
    const DashboardPage(),
    const ParticipantTripsPage(),
    const ParticipantProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index; // Update the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Display the selected page
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded), // New Dashboard tab
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_walk_rounded),
                label: 'Trips',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
            selectedItemColor: Colors.green, // Highlighted tab color
            unselectedItemColor: Colors.grey, // Non-highlighted tab color
            backgroundColor: Colors.white, // Background color
            showUnselectedLabels: true, // Show labels for unselected tabs
            type: BottomNavigationBarType.fixed, // Fixed tab style
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
