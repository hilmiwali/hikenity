// bookmarked_trips_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'participant_trip_details_page.dart';

class BookmarkedTripsPage extends StatefulWidget {
  const BookmarkedTripsPage({super.key});

  @override
  State<BookmarkedTripsPage> createState() => _BookmarkedTripsPageState();
}

class _BookmarkedTripsPageState extends State<BookmarkedTripsPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<QuerySnapshot> _getBookmarkedTrips() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('bookmarkedTrips')
        .get();
  }

  // Remove trip from bookmarks
  Future<void> _removeBookmark(String tripId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('bookmarkedTrips')
        .doc(tripId)
        .delete();
    setState(() {}); // Refresh UI after removal
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarked Trips'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _getBookmarkedTrips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No bookmarked trips.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                // Get the trip document snapshot
                DocumentSnapshot tripSnapshot = snapshot.data!.docs[index];

                // Convert the document data to a Map
                Map<String, dynamic> tripData =
                    tripSnapshot.data() as Map<String, dynamic>;

                // Get trip ID
                String tripId = tripSnapshot.id;

                // Format the date from Timestamp
                Timestamp timestamp = tripData['date'];
                DateTime date = timestamp.toDate();
                String formattedDate = "${date.day}/${date.month}/${date.year}";

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(
                      tripData['placeName'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${tripData['state']} - $formattedDate',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${tripData['price']}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 10), // Add spacing
                        IconButton(
                          icon: const Icon(Icons.bookmark), // Always show as bookmarked here
                          onPressed: () => _removeBookmark(tripId), // Remove from bookmarks
                        ),
                      ],
                    ),
                    onTap: () {
                      // Navigate to ParticipantTripDetailsPage with tripId and data
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ParticipantTripDetailsPage(
                            tripId: tripId,
                            trip: tripSnapshot,
                          ),
                        ),
                      ).then((_) => setState(() {})); // Refresh on return
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
