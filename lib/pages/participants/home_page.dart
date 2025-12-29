// home_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

  Stream<QuerySnapshot> _getTripsStream() {
  DateTime now = DateTime.now();

  // Start with the basic trips query
  Query query = FirebaseFirestore.instance
      .collection('trips')
      .where('endDate', isGreaterThanOrEqualTo: now); // Ensure only trips with valid end dates

  // Apply state filter if the user has selected a specific state
  if (_selectedState != 'All') {
    query = query.where('state', isEqualTo: _selectedState);
  }

  // Add sorting by startDate
  query = query.orderBy('startDate', descending: !_isDateAscending);

  // Debug: Log query results for troubleshooting
  query.snapshots().listen((snapshot) {
    for (var doc in snapshot.docs) {
      print('Trip: ${doc['placeName']} | StartDate: ${doc['startDate']} | EndDate: ${doc['endDate']}');
    }
  });

  return query.snapshots();
}

  Future<bool> _isBookmarked(String tripId) async {
    if (user == null) {
      return false;
    }
    DocumentSnapshot bookmark = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('bookmarkedTrips')
        .doc(tripId)
        .get();
    return bookmark.exists;
  }

  Future<void> _toggleBookmark(String tripId, Map<String, dynamic> tripData) async {
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

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

  Future<double> _fetchOrganizerRating(String organizerId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('organizerId', isEqualTo: organizerId)
        .where('status', isEqualTo: 'completed')
        .get();

    if (querySnapshot.docs.isEmpty) {
      return 0.0;
    }

    double totalRating = 0.0;
    int ratingCount = 0;

    for (var doc in querySnapshot.docs) {
      final docData = doc.data() as Map<String, dynamic>?;

      if (docData != null && docData.containsKey('rating') && docData['rating'] != null) {
        totalRating += (docData['rating'] as num).toDouble();
        ratingCount++;
      }
    }

    return ratingCount > 0 ? totalRating / ratingCount : 0.0;
  }

  Future<String> _fetchOrganizerName(String organizerId) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('organisers') // Replace with the actual collection name
        .doc(organizerId)
        .get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      return data['fullName'] ?? 'Unknown Organizer';
    }
    return 'Unknown Organizer';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.lightGreen,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.lightGreen,
            expandedHeight: 150.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'Hikenity',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1551632811-561732d1e306',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (user == null)
                IconButton(
                  icon: const Icon(Icons.login, color: Colors.white),
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                ),
              if (user != null)
                IconButton(
                  icon: const Icon(Icons.bookmark, color: Colors.white),
                  onPressed: () => Navigator.pushNamed(context, '/bookmarkedTrips')
                      .then((_) => setState(() {})),
                ),
            ],
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              child: Container(
                color: Colors.lightGreen,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildFilterRow(),
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _getTripsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.landscape, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No trips available',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      var trip = snapshot.data!.docs[index];
                      String tripId = trip.id;
                      Map<String, dynamic> tripData = 
                          trip.data() as Map<String, dynamic>;
                      return _buildEnhancedTripCard(tripId, trip, tripData);
                    },
                    childCount: snapshot.data!.docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add functionality to scroll to top or refresh
          setState(() {});
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildFilterRow() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedState, // Bind to the current state
              icon: const Icon(Icons.location_on, color: Colors.green),
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
                  child: Text(
                    state,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newState) {
                if (newState != null) {
                  setState(() {
                    _selectedState = newState;
                    print('Selected state changed to: $_selectedState'); // Debug print
                  });
                }
              }
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            _isDateAscending ? Icons.arrow_upward : Icons.arrow_downward,
            color: Colors.green,
          ),
          onPressed: () {
            setState(() {
              _isDateAscending = !_isDateAscending; // Toggle sorting
            });
          },
        ),
      ],
    ),
  );
}

  Widget _buildEnhancedTripCard(
      String tripId, DocumentSnapshot trip, Map<String, dynamic> tripData) {
    Timestamp startDateStamp = trip['startDate'];
    Timestamp endDateStamp = trip['endDate'];
    DateTime startDate = startDateStamp.toDate();
    DateTime endDate = endDateStamp.toDate();
    String dateRange = startDate == endDate
        ? DateFormat('yMMMd').format(startDate)
        : "${DateFormat('yMMMd').format(startDate)} - ${DateFormat('yMMMd').format(endDate)}";
    int participantCount = trip['participantCount'] ?? 0;
    int maxParticipantCount = trip['maxParticipantCount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: FutureBuilder(
        future: Future.wait([
          _fetchOrganizerName(tripData['organizerId']),
          _fetchOrganizerRating(tripData['organizerId']),
          _isBookmarked(tripId),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Error loading trip details.')),
            );
          }

          final results = snapshot.data as List<dynamic>;
          final organizerName = results[0] as String;
          final averageRating = results[1] as double;
          final isBookmarked = results[2] as bool;

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParticipantTripDetailsPage(
                    tripDocId: tripId,
                    trip: trip,
                    receiptUrl: '',
                    tripId: tripId,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        image: tripData['imageUrls'] != null && (tripData['imageUrls'] as List).isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage((tripData['imageUrls'] as List)[0]), // Use the first image from `imageUrls`
                                fit: BoxFit.cover,
                              )
                            : const DecorationImage(
                                image: AssetImage('assets/image_not_available.png'), // Placeholder for no image
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked ? Colors.green : Colors.white,
                        ),
                        onPressed: () => _toggleBookmark(tripId, tripData),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              trip['placeName'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'RM${trip['price']}0',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, 
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            trip['state'],
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, 
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            dateRange,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'By $organizerName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: averageRating > 0 
                                        ? Colors.amber 
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    averageRating > 0
                                        ? '${averageRating.toStringAsFixed(1)}/5'
                                        : 'No ratings',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: participantCount >= maxParticipantCount
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$participantCount/$maxParticipantCount spots',
                              style: TextStyle(
                                color: participantCount >= maxParticipantCount
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverAppBarDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}