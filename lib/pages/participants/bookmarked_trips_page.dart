// bookmarked_trips_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'participant_trip_details_page.dart';

class BookmarkedTripsPage extends StatefulWidget {
  const BookmarkedTripsPage({super.key});

  @override
  State<BookmarkedTripsPage> createState() => _BookmarkedTripsPageState();
}

class _BookmarkedTripsPageState extends State<BookmarkedTripsPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<List<DocumentSnapshot>> _getBookmarkedTrips() async {
    if (user == null) return [];

    QuerySnapshot bookmarkedSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('bookmarkedTrips')
        .get();

    if (bookmarkedSnapshot.docs.isEmpty) return [];

    List<String> bookmarkedTripIds = bookmarkedSnapshot.docs
        .map((doc) => doc.id)
        .toList();

    QuerySnapshot allTripsSnapshot = await FirebaseFirestore.instance
        .collection('trips')
        .where(FieldPath.documentId, whereIn: bookmarkedTripIds)
        .get();

    DateTime now = DateTime.now();
    List<DocumentSnapshot> validTrips = allTripsSnapshot.docs.where((tripDoc) {
      Timestamp startDateTimestamp = tripDoc['startDate'];
      DateTime startDate = startDateTimestamp.toDate();
      DateTime bookingCutoff = startDate.subtract(const Duration(days: 4));
      return now.isBefore(bookingCutoff);
    }).toList();

    return validTrips;
  }

  Future<void> _removeBookmark(String tripId) async {
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('bookmarkedTrips')
        .doc(tripId)
        .delete();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green.shade50, Colors.white],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle_outlined, 
                     size: 80, 
                     color: Colors.green.shade300),
                const SizedBox(height: 16),
                const Text(
                  'Please log in to view your bookmarked trips.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Bookmarked Trips',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: FutureBuilder<List<DocumentSnapshot>>(
          future: _getBookmarkedTrips(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_border,
                         size: 80,
                         color: Colors.green.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'No bookmarked trips found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start exploring and save your favorite trips!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                DocumentSnapshot tripSnapshot = snapshot.data![index];
                Map<String, dynamic> tripData = 
                    tripSnapshot.data() as Map<String, dynamic>;
                String tripId = tripSnapshot.id;

                Timestamp startDateStamp = tripData['startDate'];
                Timestamp endDateStamp = tripData['endDate'];
                DateTime startDate = startDateStamp.toDate();
                DateTime endDate = endDateStamp.toDate();
                String dateRange = startDate == endDate
                    ? DateFormat('EEE, MMM d, yyyy').format(startDate)
                    : "${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}";

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParticipantTripDetailsPage(
                              tripId: tripId,
                              trip: tripSnapshot,
                              receiptUrl: '',
                              tripDocId: tripId,
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tripData['placeName'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.bookmark,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _removeBookmark(tripId),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_city,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tripData['state'],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateRange,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'RM${tripData['price']}0',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}