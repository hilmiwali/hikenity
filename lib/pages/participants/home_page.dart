//home_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'participant_trip_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedState = 'All';
  bool _isDateAscending = true;
  User? user = FirebaseAuth.instance.currentUser;

  Future<QuerySnapshot> _getTrips() {
    Query query = FirebaseFirestore.instance
        .collection('trips')
        .orderBy('date', descending: !_isDateAscending);

    if (_selectedState != 'All') {
      query = query.where('state', isEqualTo: _selectedState);
    }

    return query.get();
  }

  Future<bool> _isBookmarked(String tripId) async {
    DocumentSnapshot bookmark = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('bookmarkedTrips')
        .doc(tripId)
        .get();
    return bookmark.exists;
  }

  Future<void> _toggleBookmark(String tripId, Map<String, dynamic> tripData) async {
    DocumentReference bookmarkRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('bookmarkedTrips')
        .doc(tripId);

    if (await _isBookmarked(tripId)) {
      await bookmarkRef.delete();
    } else {
      await bookmarkRef.set(tripData);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.pushNamed(context, '/bookmarkedTrips').then((_) {
                // Rebuild the page to update bookmark statuses when returning
                setState(() {});
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFilterRow(),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: _getTrips(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No trips available.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var trip = snapshot.data!.docs[index];
                        String tripId = trip.id;
                        Map<String, dynamic> tripData = trip.data() as Map<String, dynamic>;

                        return _buildTripCard(tripId, trip, tripData);
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DropdownButton<String>(
          value: _selectedState,
          items: const [
            'All',
            'Perlis',
            'Kedah',
            'Pulau Pinang',
            'Perak',
            'Kelantan',
            'Terengganu',
            'Pahang',
            'Johor',
            'Negeri Sembilan',
            'Melaka',
            'Kuala Lumpur',
            'Selangor',
            'Sabah',
            'Sarawak',
            'Labuan'
          ].map((String state) {
            return DropdownMenuItem<String>(
              value: state,
              child: Text(state),
            );
          }).toList(),
          onChanged: (String? newState) {
            setState(() {
              _selectedState = newState!;
            });
          },
        ),
        IconButton(
          icon: Icon(_isDateAscending ? Icons.arrow_upward : Icons.arrow_downward),
          onPressed: () {
            setState(() {
              _isDateAscending = !_isDateAscending;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTripCard(String tripId, DocumentSnapshot trip, Map<String, dynamic> tripData) {
    return FutureBuilder<bool>(
      future: _isBookmarked(tripId),
      builder: (context, bookmarkSnapshot) {
        if (bookmarkSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        bool isBookmarked = bookmarkSnapshot.data ?? false;
        Timestamp timestamp = trip['date'];
        DateTime date = timestamp.toDate();
        String formattedDate = "${date.day}/${date.month}/${date.year}";

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 4,
          child: ListTile(
            title: Text(
              trip['placeName'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${trip['state']} - $formattedDate',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${trip['price']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: () => _toggleBookmark(tripId, tripData),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ParticipantTripDetailsPage(tripId: tripId, trip: trip),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
