//completed_trip_details_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../trip_details_common.dart'; // Reuse common trip details widget

class CompletedTripDetailsPage extends StatelessWidget {
  final String tripId;

  const CompletedTripDetailsPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Trip Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('trips').doc(tripId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var trip = snapshot.data!;
          var tripData = trip.data() as Map<String, dynamic>;

          // Extract the average rating safely
          double averageRating = (tripData['averageRating'] ?? 0.0).toDouble();

          return Column(
            children: [
              // Reuse common trip details widget
              TripDetailsCommon(trip: trip, tripId: tripId),

              const Divider(), // UI separation

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Average Rating: ${averageRating > 0 ? averageRating.toStringAsFixed(1) + "/5" : "No ratings yet"}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const Divider(),

              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Participants',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // Participants list
              Expanded(child: _buildParticipantsList()),
            ],
          );
        },
      ),
    );
  }

  // Build the participants list
  Widget _buildParticipantsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('tripId', isEqualTo: tripId) // Filter bookings by tripId
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs;

        if (bookings.isEmpty) {
          return const Center(child: Text('No participants have joined this trip.'));
        }

        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            var booking = bookings[index];
            String participantId = booking['participantId']; // Get participantId

            // Fetch participant details using the participantId
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('participant').doc(participantId).get(),
              builder: (context, participantSnapshot) {
                if (!participantSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var participantData = participantSnapshot.data!;
                String participantFullName = participantData.get('fullName') ?? 'Unknown'; // Null safety

                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(participantFullName),
                );
              },
            );
          },
        );
      },
    );
  }
}
