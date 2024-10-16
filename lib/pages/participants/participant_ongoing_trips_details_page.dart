//participant_ongoing_trips_details_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ParticipantOngoingTripsDetailsPage extends StatelessWidget {
  final Map<String, dynamic> tripData;

  const ParticipantOngoingTripsDetailsPage({super.key, required this.tripData});

  // Function to cancel the trip
  Future<void> _cancelTrip(BuildContext context) async {
    try {
      String bookingId = tripData['bookingId'];
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': 'canceled'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip canceled successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel trip: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4, 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.location_on, 'Place Name: ${tripData['placeName']}'),
                    _buildInfoRow(Icons.location_city, 'State: ${tripData['state']}'),
                    _buildInfoRow(Icons.person, 'Organizer: ${tripData['organizerName']}'),
                    _buildInfoRow(Icons.date_range, 'Date: ${_formatDate(tripData['date'])}'),
                    _buildInfoRow(Icons.attach_money, 'Price: \$${tripData['price']}'),
                    _buildInfoRow(Icons.description, 'Description: ${tripData['description']}'),
                    _buildInfoRow(Icons.directions_walk, 'Track Length: ${tripData['trackLength']} km'),
                    _buildInfoRow(Icons.assessment, 'Difficulty Level: ${tripData['difficultyLevel']}'),
                    _buildInfoRow(Icons.info_outline, 'MGP Info: ${tripData['mgpInfo']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                bool? confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cancel Trip'),
                    content: const Text('Are you sure you want to cancel this trip?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _cancelTrip(context);
                }
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Trip'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build each row in the card
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
}
