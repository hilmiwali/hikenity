// trip_details_common.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class TripDetailsCommon extends StatelessWidget {
   final DocumentSnapshot<Object?>? trip; // Make this nullable
   final String tripId;

  const TripDetailsCommon({super.key, this.trip, required this.tripId});

  String _formatDate(Timestamp timestamp) {
    return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTripInfoRow(Icons.place, 'Place Name', trip?['placeName']),
              _buildTripInfoRow(Icons.location_city, 'State', trip?['state']),
              _buildTripInfoRow(Icons.person, 'Organizer', trip?['organizerName']),
              _buildTripInfoRow(Icons.date_range, 'Date', _formatDate(trip?['date'])),
              _buildTripInfoRow(Icons.attach_money, 'Price', '\$${trip?['price']}'),
              _buildTripInfoRow(Icons.description, 'Description', trip?['description']),
              _buildTripInfoRow(Icons.track_changes, 'Track Length', '${trip?['trackLength']} km'),
              _buildTripInfoRow(Icons.bar_chart, 'Difficulty Level', trip?['difficultyLevel']),
              _buildTripInfoRow(Icons.info_outline, 'MGP Info', trip?['mgpInfo']),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripInfoRow(IconData icon, String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$title: ${value ?? 'Not provided'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
