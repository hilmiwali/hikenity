//organiser_trip_details_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../trip_details_common.dart';
import 'edit_trip_page.dart'; // New page for editing trip

class OrganizerTripDetailsPage extends StatelessWidget {
  final String tripId;

  OrganizerTripDetailsPage({
    super.key,
    required this.tripId, required QueryDocumentSnapshot<Object?> trip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteTrip(context),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('trips').doc(tripId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          var trip = snapshot.data!;
          return Column(
            children: [
              // Reuse common trip details widget
              TripDetailsCommon(trip: trip, tripId: tripId),

              const Divider(), // Add a divider for better UI separation

              // Display participants list
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Participants',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(child: _buildParticipantsList()), // Participants list
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editTrip(context),
        child: const Icon(Icons.edit),
      ),
    );
  }

  // Build the participants list
  Widget _buildParticipantsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('tripId', isEqualTo: tripId) // Query by tripId
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading participants: ${snapshot.error}'),
          );
        }

        final bookings = snapshot.data!.docs;
        if (bookings.isEmpty) {
          return const Center(child: Text('No participants have joined this trip.'));
        }

        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            var booking = bookings[index];
            String participantId = booking['participantId']; // Get the participantId from bookings

            // Log for debugging
            print('Fetching participant with ID: $participantId');

            // Fetch participant details from 'participant' collection using participantId
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('participant').doc(participantId).get(),
              builder: (context, participantSnapshot) {
                if (!participantSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (participantSnapshot.hasError) {
                  return Center(
                    child: Text('Error fetching participant: ${participantSnapshot.error}'),
                  );
                }

                var participantData = participantSnapshot.data!;
                String participantFullName = participantData['fullName']; // Get fullName from participant

                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(participantFullName), // Display fullName
                );
              },
            );
          },
        );
      },
    );
  }

  // Delete trip function
  void _deleteTrip(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).delete();
      Navigator.pop(context); // Navigate back after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting trip: $e')),
      );
    }
  }

  // Navigate to the edit trip page
  void _editTrip(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTripPage(tripId: tripId), // Pass tripId to edit page
      ),
    );
  }
}

