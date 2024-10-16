//participant_trip_details_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../trip_details_common.dart';

class ParticipantTripDetailsPage extends StatelessWidget {
  final String tripId;
  final DocumentSnapshot<Object?>? trip;

  const ParticipantTripDetailsPage({super.key, required this.tripId, required this.trip});

  @override
  Widget build(BuildContext context) {
    assert(tripId.isNotEmpty, "Trip ID must not be empty");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('trips').doc(tripId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Trip not found.'));
          }

          var tripData = snapshot.data;
          var price = (tripData!['price'] as num).toInt(); 
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: TripDetailsCommon(trip: tripData, tripId: tripId),
                ),
              ),
              const SizedBox(height: 8),
              _buildBookTripButton(context, tripId, price),
              const SizedBox(height: 16),
            ],
          ); 
        },
      ),
    );
  }

  Widget _buildBookTripButton(BuildContext context, String tripId, int price) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton.icon(
        onPressed: () => _handlePayment(context, tripId, price),
        icon: const Icon(Icons.book, color: Colors.white),
        label: const Text('Book Trip'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  Future<void> _handlePayment(BuildContext context, String tripId, int amount) async {
    print("Book Trip button clicked.");
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to book this trip')),
      );
      return;
    }

    try {
      print("Creating payment intent for amount: $amount (in USD)...");
      final paymentIntent = await _createPaymentIntent(amount); 
      print("Payment intent created: $paymentIntent");

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['clientSecret'],
          merchantDisplayName: 'Hikenity',
          style: ThemeMode.light,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      await _bookTrip(context, user.uid, tripId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip booked and payment successful!')),
        );
      }
    } catch (e) {
      print("Error presenting payment sheet: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(int amount) async {
    print("Creating payment intent with amount (in cents): ${amount * 100}");

    final response = await http.post(
      Uri.parse('https://us-central1-hikenity.cloudfunctions.net/createPaymentIntent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount * 100, 
        'currency': 'usd',
      }),
    );

    print("Payment amount in cents: ${amount * 100}");

    if (response.statusCode == 200) {
      print("Payment Intent response: ${response.body}");
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create Payment Intent');
    }
  }

  Future<void> _bookTrip(BuildContext context, String participantId, String tripId) async {
    var booking = await FirebaseFirestore.instance
        .collection('bookings')
        .where('tripId', isEqualTo: tripId)
        .where('participantId', isEqualTo: participantId)
        .get();

    if (booking.docs.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already booked this trip')),
        );
      }
      return;
    }

    await FirebaseFirestore.instance.collection('bookings').add({
      'tripId': tripId,
      'participantId': participantId,
      'bookingDate': DateTime.now(),
      'status': 'booked',
    });
  }
}
