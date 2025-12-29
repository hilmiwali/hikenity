//dashboard_page.dart - participant
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _tripsJoined = 0; // Number of trips joined
  int _totalPoints = 0; // Total points for achievements
  double _totalSpent = 0.0; // Total money spent by participant
  String _badge = "None"; // Current badge
  List<LatLng> _tripLocations = []; // List of trip locations
  Map<String, dynamic> _tripInsights = {}; // Insights about trips
  //List<FlSpot> _pointsData = [];

  @override
  void initState() {
    super.initState();
    _fetchParticipantProgress();
    _fetchTripInsights();
    _fetchTripLocations();
    _fetchPaymentInfo();
     _fetchPointsHistory();
  }

  Future<void> _fetchPointsHistory() async {
    try {
      final String? participantId = FirebaseAuth.instance.currentUser?.uid;
      if (participantId != null) {
        final bookingsSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('participantId', isEqualTo: participantId)
            .where('status', isEqualTo: 'completed')
            .orderBy('completedDate')
            .get();

        List<FlSpot> spots = [];
        int index = 0;
        for (var doc in bookingsSnapshot.docs) {
          String difficulty = doc.data()['difficultyLevel'] ?? 'Easy';
          double points = difficulty == 'Easy' ? 1 : difficulty == 'Medium' ? 2 : 3;
          spots.add(FlSpot(index.toDouble(), points));
          index++;
        }

        setState(() {
          //_pointsData = spots;
        });
      }
    } catch (e) {
      print('Error fetching points history: $e');
    }
  }

  // Enhanced UI Components
  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchParticipantProgress() async {
    try {
      final String? participantId = FirebaseAuth.instance.currentUser?.uid;

      if (participantId != null) {
        // Fetch trips the participant joined
        final bookingsSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('participantId', isEqualTo: participantId)
            .where('status', whereIn: ['booked', 'confirmed', 'completed'])
            .get();

        int tripsCount = bookingsSnapshot.docs.length;

        // Calculate total points based on trip difficulty
        int totalPoints = 0;
        for (var booking in bookingsSnapshot.docs) {
          String difficulty = booking.data()['difficultyLevel'] ?? 'Easy';
          if (difficulty == 'Easy') {
            totalPoints += 1;
          } else if (difficulty == 'Medium') {
            totalPoints += 2;
          } else if (difficulty == 'Hard') {
            totalPoints += 3;
          }
        }

        // Determine badge
        String badge = "None";
        if (totalPoints < 10) {
          badge = "Beginner";
        } else if (totalPoints >= 10 && totalPoints < 20) {
          badge = "Competent";
        } else if (totalPoints >= 20 && totalPoints < 30) {
          badge = "Expert";
        } else if (totalPoints >= 50) {
          badge = "Veteran";
        }

        // Update the state
        setState(() {
          _tripsJoined = tripsCount;
          _totalPoints = totalPoints;
          _badge = badge;
        });
      }
    } catch (e) {
      print('Error fetching participant progress: $e');
    }
  }

  Future<void> _fetchPaymentInfo() async {
  try {
    final String? participantId = FirebaseAuth.instance.currentUser?.uid;

    if (participantId != null) {
      // Fetch bookings for the participant
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('participantId', isEqualTo: participantId)
          .where('status', whereIn: ['booked', 'confirmed', 'completed'])
          .get();

      double totalSpent = 0;

      // Fetch price from each trip document
      for (var booking in bookingsSnapshot.docs) {
        String tripId = booking.data()['tripId'];

        final tripSnapshot = await FirebaseFirestore.instance
            .collection('trips')
            .doc(tripId)
            .get();

        if (tripSnapshot.exists) {
          double price = tripSnapshot.data()?['price'] ?? 0.0;
          totalSpent += price.toInt(); // Add price to total spent
        }
      }

      setState(() {
        _totalSpent = totalSpent;
      });
    }
  } catch (e) {
    print('Error fetching payment info: $e');
  }
}

Widget _buildPaymentInfo() {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: const Icon(Icons.attach_money, color: Colors.green),
      title: const Text('Total Spent'),
      subtitle: Text('RM $_totalSpent'),
    ),
  );
}

  Widget _buildAchievementsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Achievements & Badges',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          _buildAchievementTile(
            Icons.star,
            'Total Points',
            '$_totalPoints points',
            Colors.amber,
          ),
          _buildAchievementTile(
            Icons.emoji_events,
            'Current Badge',
            _badge,
            _getBadgeColor(_badge),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor(String badge) {
    switch (badge) {
      case 'Beginner':
        return Colors.blue;
      case 'Competent':
        return Colors.green;
      case 'Expert':
        return Colors.purple;
      case 'Veteran':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAchievementTile(
      IconData icon, String title, String value, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(
        value,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _fetchTripInsights() async {
  try {
    final String? participantId = FirebaseAuth.instance.currentUser?.uid;

    if (participantId != null) {
      // Fetch bookings for completed trips
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('participantId', isEqualTo: participantId)
          .where('status', whereIn: ['booked', 'confirmed', 'completed'])
          .get();

      var stateCounts = <String, int>{};
      var organizerCounts = <String, int>{};
      var totalDifficulty = 0;
      var tripCount = bookingsSnapshot.docs.length;

      // Iterate through each booking and fetch trip details
      for (var booking in bookingsSnapshot.docs) {
        String tripId = booking.data()['tripId'];
        final tripSnapshot = await FirebaseFirestore.instance
            .collection('trips')
            .doc(tripId)
            .get();

        if (tripSnapshot.exists) {
          var tripData = tripSnapshot.data() as Map<String, dynamic>;

          // Extract fields from the trips collection
          String state = tripData['state'] ?? 'Unknown';
          String organizer = tripData['organizerName'] ?? 'Unknown';
          String difficulty = tripData['difficultyLevel'] ?? 'Easy';

          // Count states and organizers
          stateCounts[state] = (stateCounts[state] ?? 0) + 1;
          organizerCounts[organizer] = (organizerCounts[organizer] ?? 0) + 1;

          // Convert difficulty to numeric value for averaging
          if (difficulty == 'Easy') {
            totalDifficulty += 1;
          } else if (difficulty == 'Medium') {
            totalDifficulty += 2;
          } else if (difficulty == 'Hard') {
            totalDifficulty += 3;
          }
        }
      }

      // Determine most visited state and favorite organizer
      String mostVisitedState = stateCounts.isNotEmpty
          ? stateCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'None';
      String favoriteOrganizer = organizerCounts.isNotEmpty
          ? organizerCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'None';

      // Calculate average difficulty
      double avgDifficulty = tripCount > 0 ? totalDifficulty / tripCount : 0.0;

      setState(() {
        _tripInsights = {
          'mostVisitedState': mostVisitedState,
          'favoriteOrganizer': favoriteOrganizer,
          'avgDifficulty': avgDifficulty.toStringAsFixed(1),
        };
      });
    }
  } catch (e) {
    print('Error fetching trip insights: $e');
  }
}

  Widget _buildTripInsights() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Trip Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          _buildInsightTile(
            Icons.map,
            'Most Visited State',
            _tripInsights['mostVisitedState'] ?? 'N/A',
            Colors.teal,
          ),
          _buildInsightTile(
            Icons.group,
            'Favorite Organizer',
            _tripInsights['favoriteOrganizer'] ?? 'N/A',
            Colors.blue,
          ),
          _buildInsightTile(
            Icons.trending_up,
            'Average Difficulty',
            '${_tripInsights['avgDifficulty'] ?? 'N/A'}/3.0',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightTile(
      IconData icon, String title, String value, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Future<void> _fetchTripLocations() async {
    try {
      final String? participantId = FirebaseAuth.instance.currentUser?.uid;

      if (participantId != null) {
        final bookingsSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('participantId', isEqualTo: participantId)
            .where('status', isEqualTo: 'completed')
            .get();

        List<LatLng> locations = [];
        for (var booking in bookingsSnapshot.docs) {
          double latitude = booking.data()['latitude'] ?? 0.0;
          double longitude = booking.data()['longitude'] ?? 0.0;
          locations.add(LatLng(latitude, longitude));
        }

        setState(() {
          _tripLocations = locations;
        });
      }
    } catch (e) {
      print('Error fetching trip locations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Dashboard'),
        backgroundColor: Colors.lightGreen,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, Hiker!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your hiking journey and achievements',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              _buildStatCard(
                Icons.directions_walk,
                'Trips Joined',
                '$_tripsJoined trips',
                Colors.green,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                Icons.attach_money,
                'Total Spent',
                'RM $_totalSpent',
                Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildAchievementsSection(),
              const SizedBox(height: 16),
              _buildTripInsights(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
