//Organiser_main_page.dart
import 'package:flutter/material.dart';
import 'organiser_trips_page.dart'; // Your OrganiserTripsPage import
import 'organiser_create_trips.dart'; // Your OrganiserCreateTripPage import
import 'organiser_profile_page.dart'; // Your ProfilePage import

class OrganiserMainPage extends StatefulWidget {
  const OrganiserMainPage({super.key});

  @override
  _OrganiserMainPageState createState() => _OrganiserMainPageState();
}

class _OrganiserMainPageState extends State<OrganiserMainPage> {
  int _currentIndex = 0;

  // List of pages to switch between
  final List<Widget> _pages = [
    const OrganiserTripsPage(),
    const OrganiserCreateTripPage(),
    const OrganiserProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Highlight the current tab
        onTap: _onTabTapped, // Handle tab taps
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Create Trip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.green, // Customize selected tab color (green)
        unselectedItemColor: Colors.grey, // Customize unselected tab color
        showUnselectedLabels: true, // Show labels for unselected tabs
        backgroundColor: Colors.green[45], // Light green background for the bar
        type: BottomNavigationBarType.fixed, // Prevent shifting on tab selection
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }
}
