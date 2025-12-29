// receipts_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'free_receipt.dart';  // Ensure you import FreeReceiptPage correctly

class ReceiptsPage extends StatefulWidget {
  const ReceiptsPage({super.key});

  @override
  State<ReceiptsPage> createState() => _ReceiptsPageState();
}

class _ReceiptsPageState extends State<ReceiptsPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  bool _sortDesc = true; // True for descending, false for ascending

  Future<QuerySnapshot> _getReceipts() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('participantId', isEqualTo: user!.uid)
        .where('status', whereIn: ['booked', 'confirmed', 'completed'])
        .orderBy('bookingDate', descending: _sortDesc) // Adjust based on _sortDesc
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Receipts'),
        backgroundColor: Colors.green,
        actions: <Widget>[
          IconButton(
            icon: Icon(_sortDesc ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () {
              setState(() {
                _sortDesc = !_sortDesc; // Toggle the sorting order
                });
            },
      ),
  ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _getReceipts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No receipts available.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var booking = snapshot.data!.docs[index];
              var tripData = booking.data() as Map<String, dynamic>;
              var receiptUrl = tripData['receiptUrl'] ?? '';
              var bookingDate = (tripData['bookingDate'] as Timestamp).toDate();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('trips')
                    .doc(tripData['tripId'])
                    .get(),
                builder: (context, tripSnapshot) {
                  if (!tripSnapshot.hasData || !tripSnapshot.data!.exists) {
                    return const SizedBox(); // Skip if trip not found
                  }
                  var tripDetails = tripSnapshot.data!;
                  return _buildReceiptCard(tripDetails, bookingDate, receiptUrl);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReceiptCard(
    DocumentSnapshot tripDetails, DateTime bookingDate, String receiptUrl) {
  var tripData = tripDetails.data() as Map<String, dynamic>?;
  var placeName = tripData?['placeName'] ?? 'Unknown';
  var state = tripData?['state'] ?? 'Unknown';
  var price = tripData?['price'] ?? '0.0';
  var tripDate = tripData?['date'] != null
      ? (tripData?['date'] as Timestamp).toDate()
      : DateTime.now();
  var isFreeTrip = tripData?['isFreeTrip'] ?? false;

  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    elevation: 6,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            placeName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            'State: $state',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          Text(
            'Trip Date: ${DateFormat('dd/MM/yyyy').format(tripDate)}',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          Text(
            'Price: RM${price is String ? double.tryParse(price)?.toStringAsFixed(2) ?? price : price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey[300]),
          Text(
            'Booked on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(bookingDate)}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isFreeTrip) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => FreeReceiptPage(
                    tripName: placeName,
                    dateTime: DateFormat('dd/MM/yyyy').format(tripData?['date'].toDate()),
                    state: tripData?['state'] ?? 'Unknown State',
                    price: tripData!['price'].toString(),
                    participantName: user?.displayName ?? 'No Name Provided',
                  )));
                } else if (receiptUrl.isNotEmpty) {
                  _launchUrl(receiptUrl);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No receipt URL available')),
                  );
                }
              },
              icon: const Icon(Icons.receipt),
              label: const Text('View Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void _launchUrl(String url) async {
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not launch URL')),
    );
  }
}

}