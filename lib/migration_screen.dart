import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationScreen extends StatelessWidget {
  const MigrationScreen({Key? key}) : super(key: key);

  Future<void> migrateExistingBookings() async {
  final bookingsCollection = FirebaseFirestore.instance.collection('bookings');
  final tripsCollection = FirebaseFirestore.instance.collection('trips');

  // Fetch all existing bookings
  final bookingsSnapshot = await bookingsCollection.get();

  for (var bookingDoc in bookingsSnapshot.docs) {
    final bookingData = bookingDoc.data();
    final oldTripId = bookingData['tripId'];

    // Attempt to find a trip document with the document ID matching `oldTripId`
    final tripDoc = await tripsCollection.doc(oldTripId).get();

    if (tripDoc.exists) {
      // Update the booking's `tripId` to the document ID of the found trip
      await bookingDoc.reference.update({'tripId': tripDoc.id});
      print('Updated booking ${bookingDoc.id} to new tripId ${tripDoc.id}');
    } else {
      print('No trip found for booking ${bookingDoc.id} with old tripId $oldTripId');
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Migration'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await migrateExistingBookings();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Migration completed! Check console for details.')),
            );
          },
          child: const Text('Run Migration'),
        ),
      ),
    );
  }
}
