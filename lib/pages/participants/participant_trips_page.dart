//participant_trips_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'participant_completed_trips_details_page.dart';
import 'participant_ongoing_trips_details_page.dart';

class ParticipantTripsPage extends StatefulWidget {
  const ParticipantTripsPage({super.key});

  @override
  _ParticipantTripsPageState createState() => _ParticipantTripsPageState();
}

class _ParticipantTripsPageState extends State<ParticipantTripsPage> with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  String? currentParticipantId;

  @override
  void initState() {
    super.initState();
     _tabController = TabController(length: 2, vsync: this);
    _getCurrentParticipantId();
    _updateTripStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentParticipantId() async {
    setState(() {
      currentParticipantId = _auth.currentUser?.uid;
    });
    print("Current Participant ID: $currentParticipantId");
  }

  void _updateTripStatus() async {
  var user = _auth.currentUser;
  if (user == null) return;

  try {
    var bookings = await _firestore
        .collection('bookings')
        .where('participantId', isEqualTo: user.uid)
        .where('status', whereIn: ['booked', 'confirmed'])
        .get();

    var now = DateTime.now();

    for (var booking in bookings.docs) {
      var tripDoc = await _firestore.collection('trips').doc(booking['tripId']).get();
      if (!tripDoc.exists) continue;

      var endDate = (tripDoc['endDate'] as Timestamp).toDate();
      if (endDate.isBefore(now)) {
        print("Updating Booking ${booking.id} to 'completed'");
        await _firestore.collection('bookings').doc(booking.id).update({'status': 'completed'});
      }
    }
  } catch (e) {
    print("Error updating trip status: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 100.0,
              floating: false,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text('My Trips',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    )),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/hutan.jpg', // Make sure to add this image
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
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.directions_walk),
                    text: 'Ongoing',
                  ),
                  Tab(
                    icon: Icon(Icons.check_circle),
                    text: 'Completed',
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTripList(['booked', 'confirmed']),
            _buildTripList(['completed']),
          ],
        ),
      ),
    );
  }

  Widget _buildTripList(List<String> statuses) {
    User? user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view your trips'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('participantId', isEqualTo: user.uid)
          .where('status', whereIn: statuses)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(statuses.contains('booked'));
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchTripDetails(snapshot.data!.docs),
          builder: (context, tripSnapshot) {
            if (tripSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!tripSnapshot.hasData || tripSnapshot.data!.isEmpty) {
              return _buildEmptyState(statuses.contains('booked'));
            }

            final trips = tripSnapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _buildTripCard(trip, statuses);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isOngoing) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOngoing ? Icons.hiking : Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isOngoing ? 'No ongoing trips' : 'No completed trips yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOngoing ? 'Book a new adventure!' : 'Complete a trip to see it here',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip, List<String> statuses) {
  final isOngoing = statuses.contains('booked') || statuses.contains('confirmed');
  final startDate = (trip['startDate'] as Timestamp).toDate();
  final endDate = (trip['endDate'] as Timestamp).toDate();

  return Card(
    elevation: 4,
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
    child: InkWell(
      onTap: () {
        if (isOngoing) {
          _goToOngoingTripDetails(trip);
        } else {
          _goToCompletedTripDetails(trip);
        }
      },
      borderRadius: BorderRadius.circular(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              image: DecorationImage(
                image: trip['imageUrls'][0].toString().startsWith('http')
                    ? NetworkImage(trip['imageUrls'][0])
                    : AssetImage(trip['imageUrls'][0]) as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    trip['placeName'] ?? 'Unknown Place', // Fallback for placeName
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _formatTripDates(trip['startDate'], trip['endDate']),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.group, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${trip['participantCount'] ?? 0}/${trip['maxParticipantCount'] ?? 0}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const Spacer(),
                    _buildStatusChip(trip['status']),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'booked':
        chipColor = Colors.orange;
        statusText = 'Booked';
        statusIcon = Icons.schedule;
        break;
      case 'confirmed':
        chipColor = Colors.green;
        statusText = 'Confirmed';
        statusIcon = Icons.check_circle;
        break;
      case 'completed':
        chipColor = Colors.blue;
        statusText = 'Completed';
        statusIcon = Icons.flag;
        break;
      default:
        chipColor = Colors.grey;
        statusText = 'Unknown';
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: chipColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  Future<List<Map<String, dynamic>>> _fetchTripDetails(List<QueryDocumentSnapshot> bookingDocs) async {
  List<Map<String, dynamic>> trips = [];

  for (var booking in bookingDocs) {
    try {
      var tripId = booking['tripId'];
      var tripDoc = await _firestore.collection('trips').doc(tripId).get();

      if (tripDoc.exists) {
        var tripData = tripDoc.data() as Map<String, dynamic>;
        tripData['bookingId'] = booking.id;
        tripData['status'] = booking['status'];
        tripData['startDate'] = tripDoc['startDate'];
        tripData['endDate'] = tripDoc['endDate'];
        tripData['tripDocId'] = tripId;

        // Check if `imageUrls` exists and is non-empty; otherwise, set a fallback asset
        tripData['imageUrls'] = (tripDoc.data()!.containsKey('imageUrls') &&
                (tripDoc['imageUrls'] as List).isNotEmpty)
            ? tripDoc['imageUrls']
            : ['assets/image_not_available.png'];

        trips.add(tripData);
      } else {
        print("Trip Doc $tripId does not exist.");
      }
    } catch (e) {
      print("Error fetching trip details: $e");
    }
  }
  return trips;
}

  String _formatTripDates(Timestamp start, Timestamp end) {
    var startDate = DateFormat('MMM d, yyyy').format(start.toDate());
    var endDate = DateFormat('MMM d, yyyy').format(end.toDate());
    return startDate == endDate ? startDate : "$startDate - $endDate";
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
  try {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParticipantCompletedTripsDetailsPage(tripData: tripData),
      ),
    );
  } catch (e) {
    print("Error navigating to ParticipantCompletedTripsDetailsPage: $e");
  }
}
}
