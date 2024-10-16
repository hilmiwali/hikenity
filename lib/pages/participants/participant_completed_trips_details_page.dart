//participant_completed_trips_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ParticipantCompletedTripsDetailsPage extends StatelessWidget {
  final Map<String, dynamic> tripData;

  const ParticipantCompletedTripsDetailsPage({super.key, required this.tripData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tripData['placeName']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Place: ${tripData['placeName']}', style: const TextStyle(fontSize: 18)),
            Text('State: ${tripData['state']}'),
            Text('Organizer: ${tripData['organizerName']}'),
            Text('Date: ${tripData['date']}'),
            Text('Price: \$${tripData['price']}'),
            Text('Track Length: ${tripData['trackLength']} km'),
            Text('Difficulty Level: ${tripData['difficultyLevel']}'),
            Text('MGP Info: ${tripData['mgpInfo']}'),
            const SizedBox(height: 20),
            const Text('Rate this trip:', style: TextStyle(fontSize: 16)),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                // Save rating to Firestore or any other logic
              },
            ),
          ],
        ),
      ),
    );
  }
}
