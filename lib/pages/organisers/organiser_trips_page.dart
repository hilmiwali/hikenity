//organiser_trips_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'organiser_trip_details_page.dart';

class OrganiserTripsPage extends StatefulWidget {
  const OrganiserTripsPage({super.key});

  @override
  _OrganiserTripsPageState createState() => _OrganiserTripsPageState();
}

class _OrganiserTripsPageState extends State<OrganiserTripsPage> {
  static const int _limit = 10; // Pagination limit
  String? currentOrganizerId;  // Variable to store organizer's UID

  @override
  void initState() {
    super.initState();
    _getCurrentOrganizerId();  // Fetch the current organizer's UID
  }

  Future<void> _getCurrentOrganizerId() async {
    // Get current organizer's UID (assuming they are logged in via FirebaseAuth)
    setState(() {
      currentOrganizerId = FirebaseAuth.instance.currentUser?.uid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        centerTitle: true,
      ),
      body: currentOrganizerId == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ongoing Trips',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildOngoingTripsList(), // Ongoing trips list

                    const SizedBox(height: 20), // Spacing between the lists

                    const Text(
                      'Completed Trips',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildCompletedTripsList(), // Completed trips list
                  ],
                ),
              ),
            ),
    );
  }

  // Ongoing Trips list with pagination
  Widget _buildOngoingTripsList() {
  String currentOrganizerId = FirebaseAuth.instance.currentUser?.uid ?? '';

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('trips')
        .where('organizerId', isEqualTo: currentOrganizerId)  // Filter by organizerId
        .where('date', isGreaterThanOrEqualTo: DateTime.now()) // Ensure it's in the future
        .orderBy('date')
        .snapshots(),
    builder: (context, snapshot) {
      // Debug: Log when the query is made
      print('Fetching trips for organizer: $currentOrganizerId');

      if (snapshot.connectionState == ConnectionState.waiting) {
        // Debug: Log waiting state
        print('Waiting for trips data...');
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        // Debug: Log no data or empty trips
        print('No trips found for the current organizer');
        return const Text('No ongoing trips.');
      } else {
        // Debug: Log the number of trips found
        print('Trips found: ${snapshot.data!.docs.length}');
      }

      // Display the trips in the ListView
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          var trip = snapshot.data!.docs[index];
          String tripId = trip.id;
          Timestamp timestamp = trip['date'];
          DateTime date = timestamp.toDate();
          String formattedDate = "${date.day}/${date.month}/${date.year}";

          // Debug: Log trip details
          print('Trip: ${trip['placeName']}, Date: $formattedDate, Organizer: ${trip['organizerName']}');

          return Card(
            child: ListTile(
              title: Text(trip['placeName']),
              subtitle: Text('Organized by: ${trip['organizerName']} - $formattedDate'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrganizerTripDetailsPage(
                      tripId: tripId,
                      trip: trip,
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    },
  );
}


  // Completed Trips list with pagination
  Widget _buildCompletedTripsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .where('organizerId', isEqualTo: currentOrganizerId)  // Filter by organizerId
          .where('date', isLessThan: DateTime.now())
          .orderBy('date', descending: true)
          .limit(_limit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No completed trips.');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var trip = snapshot.data!.docs[index];
            String tripId = trip.id;
            Timestamp timestamp = trip['date'];
            DateTime date = timestamp.toDate();
            String formattedDate = "${date.day}/${date.month}/${date.year}";

            return Card(
              child: ListTile(
                title: Text(trip['placeName']),
                subtitle: Text(
                    'Completed by: ${trip['organizerName']} - $formattedDate'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrganizerTripDetailsPage(
                        tripId: tripId,
                        trip: trip,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
