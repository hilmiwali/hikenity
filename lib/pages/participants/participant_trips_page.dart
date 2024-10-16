//participant_trips_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'participant_completed_trips_details_page.dart';
import 'participant_ongoing_trips_details_page.dart';

class ParticipantTripsPage extends StatefulWidget {
  const ParticipantTripsPage({super.key});

  @override
  _ParticipantTripsPageState createState() => _ParticipantTripsPageState();
}

class _ParticipantTripsPageState extends State<ParticipantTripsPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ongoing Trips',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10), // Spacing before the list
              _buildTripList('booked'), // Ongoing trips
              const SizedBox(height: 20),
              const Text(
                'Completed Trips',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10), // Spacing before the list
              _buildTripList('completed'), // Completed trips
            ],
          ),
        ),
      ),
    );
  }

  // Build a real-time list of trips for a given status
  Widget _buildTripList(String status) {
    User? user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('No user logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('participantId', isEqualTo: user.uid)
          .where('status', isEqualTo: status)
          .snapshots(), // Real-time stream
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No trips found'));
        }

        // Fetch trip details for each booking in the snapshot
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchTripDetails(snapshot.data!.docs),
          builder: (context, tripSnapshot) {
            if (tripSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!tripSnapshot.hasData || tripSnapshot.data!.isEmpty) {
              return const Center(child: Text('No trips available'));
            }

            final trips = tripSnapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0), // Spacing between cards
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0), // Rounded corners
                  ),
                  elevation: 4.0, // Elevation for card shadow
                  child: ListTile(
                    title: Text(
                      trip['placeName'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _formatDate(trip['date']),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    onTap: () {
                      if (status == 'booked') {
                        _goToOngoingTripDetails(trip);
                      } else {
                        _goToCompletedTripDetails(trip);
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Helper function to fetch trip details from 'trips' collection
  Future<List<Map<String, dynamic>>> _fetchTripDetails(
      List<QueryDocumentSnapshot> bookingDocs) async {
    List<Map<String, dynamic>> trips = [];

    for (var booking in bookingDocs) {
      var tripId = booking['tripId'];
      var tripDoc = await _firestore.collection('trips').doc(tripId).get();

      if (tripDoc.exists) {
        var tripData = tripDoc.data() as Map<String, dynamic>;
        tripData['bookingId'] = booking.id; // Store bookingId for later use
        trips.add(tripData);
      }
    }
    return trips;
  }

  // Format Firestore Timestamp to a readable date string
  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('yyyy-MM-dd').format(date.toDate());
    } else if (date is String) {
      return date;
    }
    return 'Unknown Date';
  }

  void _goToOngoingTripDetails(Map<String, dynamic> tripData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParticipantOngoingTripsDetailsPage(tripData: tripData),
      ),
    );
  }

  void _goToCompletedTripDetails(Map<String, dynamic> tripData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParticipantCompletedTripsDetailsPage(tripData: tripData),
      ),
    );
  }
}
