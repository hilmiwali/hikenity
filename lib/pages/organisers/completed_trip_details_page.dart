//completed_trip_details_page.dart - for organiser
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../trip_details_common.dart';

class CompletedTripDetailsPage extends StatelessWidget {
  final String tripId;

  const CompletedTripDetailsPage({
    Key? key,
    required this.tripId,
    required QueryDocumentSnapshot<Object?> trip,
  }) : super(key: key);

  Future<double> _calculateAverageRating() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('tripId', isEqualTo: tripId)
        .where('status', isEqualTo: 'completed')
        .get();

    if (querySnapshot.docs.isEmpty) {
      return 0.0;
    }

    double totalRating = 0.0;
    int ratingCount = 0;

    for (var doc in querySnapshot.docs) {
      final docData = doc.data() as Map<String, dynamic>?;
      if (docData != null &&
          docData.containsKey('rating') &&
          docData['rating'] != null) {
        totalRating += (docData['rating'] as num).toDouble();
        ratingCount++;
      }
    }

    return ratingCount > 0 ? totalRating / ratingCount : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Color(0xFF2E7D32)],
              begin: Alignment.centerLeft,end: Alignment.centerRight,
      ),
    ),
  ),
  title: const Text(
    'Completed Trip Details',
    style: TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontSize: 22,
    ),
  ),
  centerTitle: true,
  elevation: 4,
),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: FutureBuilder<DocumentSnapshot>(
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

          // We have trip data now
          var tripDoc = snapshot.data!;
          // (If you need the raw map, you can do: var tripData = tripDoc.data() as Map<String, dynamic>)

          // Instead of a Column with Expanded, we use one ListView:
          return ListView(
            children: [
              // Common trip info
              TripDetailsCommon(
                trip: tripDoc,
                tripId: tripId,
                imageUrls: const [],
              ),
              const Divider(),

              // Average rating
              FutureBuilder<double>(
                future: _calculateAverageRating(),
                builder: (context, ratingSnapshot) {
                  double averageRating = ratingSnapshot.data ?? 0.0;
                  return Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.shade50, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Average Rating: ${averageRating > 0 ? "${averageRating.toStringAsFixed(1)}/5" : "No ratings yet"}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
                            const Divider(),

              // Participants title
              Container(
  margin: const EdgeInsets.symmetric(vertical: 16),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.green.shade50,
    border: Border(
      left: BorderSide(color: Colors.green.shade700, width: 4),
    ),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.group, color: Colors.green.shade700),
      const SizedBox(width: 8),
      Text(
        'Participants',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade700,
        ),
      ),
    ],
  ),
),

              // Our participant list goes directly in the ListView
              _buildParticipantsList(),
            ],
          );
        },
      ),),
    );
  }

  Widget _buildParticipantsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('tripId', isEqualTo: tripId)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs;
        if (bookings.isEmpty) {
          return const Padding(
          padding: EdgeInsets.only(bottom: 20.0, left: 60.0), // or all(16.0), etc.
            child: Text(
              'No participants have joined this trip.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // Because this ListView is nested in the main ListView, we do:
        //   shrinkWrap: true, physics: NeverScrollableScrollPhysics()
        // so we don't get two scroll views competing.
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            var booking = bookings[index];
            final bookingData = booking.data() as Map<String, dynamic>?;

            String participantId = bookingData?['participantId'] ?? '';
            double rating = (bookingData != null &&
                    bookingData['rating'] != null)
                ? (bookingData['rating'] as num).toDouble()
                : 0.0;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('participant')
                  .doc(participantId)
                  .get(),
              builder: (context, participantSnapshot) {
                if (!participantSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var participantData = participantSnapshot.data!;
                String participantFullName =
                    participantData.get('fullName') ?? 'Unknown';
                String emergencyNumber =
                    participantData.get('emergencyNumber') ?? 'Not available';

                return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Icon(Icons.person, color: Colors.green.shade700),
                ),
                title: Text(
                  participantFullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone_in_talk, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text('Emergency: $emergencyNumber'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            'Rating: ${rating > 0 ? "$rating/5" : "Not rated"}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      if (bookingData != null && bookingData['receiptUrl'] != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: InkWell(
                            onTap: () async {
                              Uri receiptUri = Uri.parse(bookingData['receiptUrl']);
                              if (await canLaunchUrl(receiptUri)) {
                                await launchUrl(receiptUri);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not launch receipt URL')),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.receipt_long, size: 16, color: Colors.green.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'View Receipt',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
              },
            );
          },
        );
      },
    );
  }
}
