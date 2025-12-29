// participant_trip_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hikenity_app/pages/participants/free_receipt.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../trip_details_common.dart';

class ParticipantTripDetailsPage extends StatelessWidget {
  final String tripDocId;
  final DocumentSnapshot<Object?>? trip;

  const ParticipantTripDetailsPage({
    super.key,
    required this.tripDocId,
    required this.trip,
    required String receiptUrl,
    required String tripId,
  });

  Future<bool> _checkIfUserHasBooking(String tripDocId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    var booking = await FirebaseFirestore.instance
        .collection('bookings')
        .where('tripId', isEqualTo: tripDocId)
        .where('participantId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'booked')
        .get();

    return booking.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('trips').doc(tripDocId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Trip not found.'));
          }

          var tripData = snapshot.data!;
          var tripSnapshot = snapshot.data!;
          var dataMap = tripSnapshot.data() as Map<String, dynamic>?;
          var imageUrls = List<dynamic>.from(dataMap?['imageUrls'] as List<dynamic>? ?? []);
          bool isFreeTrip = tripData['isFreeTrip'] ?? false;

          Timestamp startDateStamp = tripData['startDate'] as Timestamp;
          Timestamp endDateStamp = tripData['endDate'] as Timestamp;
          DateTime startDate = startDateStamp.toDate();
          DateTime endDate = endDateStamp.toDate();
          String dateRange = startDate == endDate 
              ? DateFormat('yMMMd').format(startDate) 
              : "${DateFormat('yMMMd').format(startDate)} to ${DateFormat('yMMMd').format(endDate)}";

          if (endDate.isBefore(DateTime.now())) {
            return const Center(
              child: Text('This trip has already passed and cannot be booked.'),
            );
          }

          return CustomScrollView(
            slivers: [
              // Collapsing App Bar with Hero Image
              SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true, // This centers the title
                    title: Text(
                      tripData['placeName'] ?? 'Trip Details',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3.0,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ],
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrls.isNotEmpty)
                          Image.network(
                            imageUrls[0], // Display the first uploaded image
                            fit: BoxFit.cover,
                          )
                        else
                          Image.asset(
                            'assets/image_not_available.png', // Default placeholder image
                            fit: BoxFit.cover,
                          ),
                        // Gradient overlay
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
                  backgroundColor: Colors.green,
                ),

              // Trip Details Content
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Quick Info Card
                    material.Card(
                      margin: const EdgeInsets.all(16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoTile(
                                    Icons.calendar_today,
                                    'Date',
                                    dateRange,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInfoTile(
                                    Icons.attach_money,
                                    'Price',
                                    isFreeTrip ? 'Free' : 'RM${tripData['price']}0',
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoTile(
                                    Icons.location_on,
                                    'State',
                                    tripData['state'] ?? 'Unknown',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInfoTile(
                                    Icons.group,
                                    'Spots',
                                    '${tripData['participantCount'] ?? 0}/${tripData['maxParticipantCount'] ?? 0}',
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoTile(
                                    Icons.height_sharp,
                                    'Elevation Gain',
                                    '${tripData['mountainHeight']}m',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInfoTile(
                                    Icons.straighten,
                                    'Track Length',
                                    '${tripData['trackLength']} km',
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            Row(
                              children: [
                                const SizedBox(width: 3),
                                Expanded(
                                  child: _buildInfoTile(
                                    Icons.trending_up,
                                    'Difficulty Level',
                                    tripData['difficultyLevel'] ?? 'Unknown',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInfoTile(
                                    Icons.time_to_leave,
                                    'Meeting Time',
                                    (tripData.data() as Map<String, dynamic>)?['meetingTime']?.toString() ?? 'Not provided',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    material.Card(
                      margin: const EdgeInsets.all(16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextTile(Icons.person,'Organizer Name',tripData['organizerName'] is String ? tripData['organizerName'] : 'N/A',),
                            _buildTextTile(Icons.info, 'MGP Info', tripData['mgpInfo'] ?? 'N/A'),
                          ],
                        ),
                      ),
                    ),
                    // Trip Features
                    material.Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Trip Features',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureTile(
                              Icons.food_bank,
                              'Ration Provided',
                              tripData['isRationProvided'] ?? false,
                            ),
                            _buildFeatureTile(
                              Icons.food_bank,
                              '4x4 Provided',
                              tripData['is4x4Provided'] ?? false,
                            ),
                            _buildFeatureTile(
                              Icons.cabin,
                              'Camping Required',
                              tripData['isCampingRequired'] ?? false,
                            ),
                            if (tripData['isCampingRequired'] ?? false)
                              _buildFeatureTile(
                                Icons.cabin,
                                'Bring Own Camp',
                                tripData['bringOwnCamp'] ?? false,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Description Card
                    if (tripData['description'] != null)
                      material.Card(
                        margin: const EdgeInsets.all(16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tripData['description'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // WhatsApp Group Link
                    FutureBuilder<bool>(
                      future: _checkIfUserHasBooking(tripDocId),
                      builder: (context, bookingSnapshot) {
                        if (bookingSnapshot.data == true && tripData['whatsappLink'] != null) {
                          return material.Card(
                            margin: const EdgeInsets.all(16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.groups, color: Colors.green),
                              title: const Text('Join WhatsApp Group'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                Uri whatsappUri = Uri.parse(tripData['whatsappLink']);
                                if (await canLaunchUrl(whatsappUri)) {
                                  await launchUrl(whatsappUri);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open WhatsApp link')),
                                  );
                                }
                              },
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('trips').doc(tripDocId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            var tripData = snapshot.data!;
            bool isFreeTrip = tripData['isFreeTrip'] ?? false;
            DateTime endDate = (tripData['endDate'] as Timestamp).toDate();

            return FloatingActionButton.extended(
              onPressed: () => isFreeTrip 
                  ? _bookFreeTrip(context, tripDocId)
                  : _handlePayment(context, tripDocId, endDate),
              label: Text(
                isFreeTrip ? 'Book Free Trip' : 'Pay & Book Trip',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.book),
              backgroundColor: Colors.green,
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    // If the field doesn't exist or is null, show 'Not provided'.
  String displayValue = (value != null && value.toString().isNotEmpty)
      ? value.toString()
      : 'Not provided';
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(height: 8),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: value ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value ? 'Yes' : 'No',
              style: TextStyle(
                color: value ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextTile(IconData icon, String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}


  Future<void> _bookFreeTrip(BuildContext context, String tripDocId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: const Text('Are you sure you want to book this free trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    try {
      var bookingQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('tripId', isEqualTo: tripDocId)
          .where('participantId', isEqualTo: user.uid)
          .where('status', whereIn: ['booked', 'confirmed'])
          .get();

      if (bookingQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have already booked this trip!')),
        );
        return;
      }

      var tripSnapshot = await FirebaseFirestore.instance.collection('trips').doc(tripDocId).get();
      var tripData = tripSnapshot.data();

      if (tripData == null) {
        throw 'Trip data not found';
      }

      Navigator.push(context, MaterialPageRoute(builder: (context) => FreeReceiptPage(
        tripName: tripData['name'] ?? 'Unknown Trip Name',
        dateTime: DateFormat('dd/MM/yyyy').format((tripData['date'] as Timestamp).toDate()),
        participantName: user.displayName ?? 'No Name Provided', state: '', price: '',
      )));

      await FirebaseFirestore.instance.collection('bookings').add({
        'tripId': tripDocId,
        'participantId': user.uid,
        'bookingDate': DateTime.now(),
        'status': 'booked',
        'receiptUrl': 'URL or Data for Receipt',  // Optionally include a receipt URL or data
      });

      var tripRef = FirebaseFirestore.instance.collection('trips').doc(tripDocId);
      await tripRef.update({
        'participantCount': FieldValue.increment(1),
      });

      await _sendNotificationToOrganizer(tripDocId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip booked successfully!')),
      );
      Navigator.pushReplacementNamed(context, '/participantBottomNavBar');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book trip: $e')),
      );
    }
  }

  Future<void> _handlePayment(BuildContext context, String tripDocId, DateTime tripDate) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    DateTime cutoffDate = tripDate.subtract(const Duration(days: 4));
    if (DateTime.now().isAfter(cutoffDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking is only allowed up to 4 days before the trip.')),
      );
      return;
    }

    var tripSnapshot = await FirebaseFirestore.instance.collection('trips').doc(tripDocId).get();
    int participantCount = tripSnapshot['participantCount'] ?? 0;
    int maxParticipantCount = tripSnapshot['maxParticipantCount'] ?? 0;

    if (participantCount >= maxParticipantCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This trip is fully booked.')),
      );
      return;
    }

    var booking = await FirebaseFirestore.instance
        .collection('bookings')
        .where('tripId', isEqualTo: tripDocId)
        .where('participantId', isEqualTo: user.uid)
        .where('status', whereIn: ['booked', 'confirmed'])
        .get();

    if (booking.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already booked this trip!')),
      );
      return;
    }

    try {
      final paymentIntent = await _createPaymentIntent();
      String? clientSecret = paymentIntent['clientSecret'];

      if (clientSecret == null) {
        throw 'Payment failed: clientSecret is null';
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Hikenity',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      final paymentIntentId = paymentIntent['paymentIntentId'];
      final receiptResponse = await _retrieveReceipt(paymentIntentId);
      String? receiptUrl = receiptResponse['receiptUrl'] ?? 'No receipt available';

      await _bookTrip(context, user.uid, tripDocId, receiptUrl ?? 'No receipt available');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip booked successfully!')),
        );
        Navigator.pushReplacementNamed(context, '/participantBottomNavBar');
      }
    } on StripeException catch (e) {
    // Detect if the error is user-initiated cancellation
    if (e.error.localizedMessage?.contains('The payment flow has been canceled') ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment was canceled. Please try again if needed.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.error.localizedMessage ?? "Unknown error"}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unexpected error: $e')),
    );
  }
}

  Future<Map<String, dynamic>> _retrieveReceipt(String paymentIntentId) async {
    final response = await http.post(
      Uri.parse('https://us-central1-hikenity.cloudfunctions.net/retrieveReceipt'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'paymentIntentId': paymentIntentId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to retrieve receipt');
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent() async {
    final response = await http.post(
      Uri.parse('https://us-central1-hikenity.cloudfunctions.net/createPaymentIntent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': 1000,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create Payment Intent');
    }
  }

  Future<void> _bookTrip(BuildContext context, String participantId, String tripDocId, String receiptUrl) async {
    var booking = await FirebaseFirestore.instance
        .collection('bookings')
        .where('tripId', isEqualTo: tripDocId)
        .where('participantId', isEqualTo: participantId)
        .get();

    if (booking.docs.isNotEmpty) {
      var bookingDoc = booking.docs.first;
      await FirebaseFirestore.instance.collection('bookings').doc(bookingDoc.id).update({
        'status': 'booked',
        'bookingDate': DateTime.now(),
        'receiptUrl': receiptUrl,
      });
    } else {
      await FirebaseFirestore.instance.collection('bookings').add({
        'tripId': tripDocId,
        'participantId': participantId,
        'bookingDate': DateTime.now(),
        'status': 'booked',
        'receiptUrl': receiptUrl,
      });
    }

    var tripRef = FirebaseFirestore.instance.collection('trips').doc(tripDocId);
    await tripRef.update({
      'participantCount': FieldValue.increment(1),
    });

    await _sendNotificationToOrganizer(tripDocId);
  }

  Future<void> _sendNotificationToOrganizer(String tripDocId) async {
    final tripDoc = await FirebaseFirestore.instance.collection('trips').doc(tripDocId).get();
    final tripData = tripDoc.data();

    if (tripData != null) {
      final organizerId = tripData['organizerId'];
      final organizerDoc = await FirebaseFirestore.instance.collection('users').doc(organizerId).get();
      final organizerData = organizerDoc.data();

      if (organizerData != null && organizerData['fcmToken'] != null) {
        final fcmToken = organizerData['fcmToken'];

        final response = await http.post(
          Uri.parse('https://fcm.googleapis.com/v1/projects/hikenity/messages:send'),
          headers: {
            'Authorization': 'Bearer ya29.c.c0ASRK0GZrbDkFLyeKTxQCr_c7ruo20iNwfh7DuysNOVQveBySm6YQkk1HJQ7Ty4xPilQe_ltUkvDDT-PJjIpE0XRn8jahCqX-OvKaeCQwnrG_rFj9GU_Di4ziVWnfSCC33EW0Pe9Maa6RP-x0NbaeBE3I3PRTQcxhdzgbkmy1UO6iCWU1BNw6vEfxsz2cUdJwV3e2A3tAtrjvbMm92oXOz6gDqYUZ8n25GmGtO-2a6ddQSYbI0MqzGh4Q7ID200hBXsu-2YqmyWq_8-qdrf5dTNaoXpm7A73ndyZaoJg-a2PJ3MawnePdeLalpGx3iTisunbh2rAir9YY3hrakvvnZqcVe7cc7RrNITXLbH1F4vfDBLW3viUHK2uv9IsnzcILd38JT397KF9_rhbR8VB58kY92ece674MJhBegXpJqncW_WX4RtzQl4evfjXcQ8UqmfsB80M01mp8_-Y2WFUl7UQUwbgZ1gUzQkt0x-79XV3qMeMcQ73kqyru8Sel3fhvX6-b9lz28Q6cYeia7U77moF_XpS_huaj3f9RW6qIbX0_-wFjIQxp7SaR-poje7r5jb6-Rk7v6gZVcs6qII_O3o03uOuhXBWffjQBFfomi767vkJromo175UZaviV3drsz02loSRd5RqvolbaJ3dWSRfffIIR5oqIa-Mhp1acjFp3b0sk5i1941yU-ZgJRX45jIWhdZ16s8qkz90gadakJ4Bck5SS1RwRYmdIRfqxFuFt0jaXa255dXx8874trMtiR1nJu673X-gmnvaIWwwWRforuy3nlW5htwgVxwn0I52JiIhcyzSy9oQpU2zJjSX8mqW6Fi29emJoFkqWg23M_ihy59Y0O70omm003Vu9n4kar3bIsZ8k24jqU-R0_byh2YkFMXO92XfRZ_hb3Rj36kRWeyOtiv7OZ1y1bpZg2sm0gktbaqnskY3Vz8XOeouIUyea25bFBotB7JJ8rpuMsYfOo1ModhFViinFwnc82i_ge_uhwvzty6a',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'message': {
              'token': fcmToken,
              'notification': {
                'title': 'New Booking',
                'body': 'A participant has booked your trip!',
              },
            },
          }),
        );

        if (response.statusCode == 200) {
          print('Notification sent successfully');
        } else {
          print('Failed to send notification: ${response.body}');
        }
      }
    }
  }
}
