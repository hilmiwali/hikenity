//participant_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'home_page.dart'; 
import 'participant_trips_page.dart'; 
import 'participant_profile_page.dart'; 

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
      body: _pages[_currentIndex], 
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, 
        onTap: _onTabTapped, 
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.blue, 
        unselectedItemColor: Colors.grey, 
        showUnselectedLabels: true, 
      ),
    );
  }
}
