//organiser_trip_details_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hikenity_app/pages/gpx_map_viewer.dart';
import 'package:hikenity_app/pages/organisers/trip_tracking_page.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';

import '../trip_details_common.dart';
import 'edit_trip_page.dart';

class OrganizerTripDetailsPage extends StatelessWidget {
  final String tripId;
  final QueryDocumentSnapshot<Object?> trip;

  const OrganizerTripDetailsPage({
    Key? key,
    required this.tripId,
    required this.trip,
  }) : super(key: key);

  // Calculate the average rating from 'bookings' collection
  Future<double> _calculateAverageRating() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('tripId', isEqualTo: tripId)
        .where('rating', isGreaterThan: 0)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return 0.0;
    }

    double totalRating = 0.0;
    for (var doc in querySnapshot.docs) {
      totalRating += (doc['rating'] ?? 0.0).toDouble();
    }

    return totalRating / querySnapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    var tripData = trip.data() as Map<String, dynamic>;
    var endDate = tripData['endDate']?.toDate() ?? DateTime.now();
    bool isCompleted = endDate.isBefore(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Trip Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        actions: isCompleted
            ? []
            : [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () => _deleteTrip(context),
                ),
              ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('trips').doc(tripId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading trip data:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          var tripDoc = snapshot.data!;
          var liveTripData = tripDoc.data() as Map<String, dynamic>;
          var startDate = liveTripData['startDate']?.toDate() ?? DateTime.now();
          var newEndDate = liveTripData['endDate']?.toDate() ?? DateTime.now();
          bool newIsCompleted = newEndDate.isBefore(DateTime.now());
          String? gpxFilePath = liveTripData['gpxFilePath'];

          return SingleChildScrollView(
            child: Column(
              children: [
                TripDetailsCommon(
                  trip: tripDoc,
                  tripId: tripId,
                  imageUrls: [],
                ),
                const SizedBox(height: 16),
                
                _buildStatusCard(newIsCompleted),
                _buildActionButtons(context, gpxFilePath, newIsCompleted),
                
                _buildAverageRating(),
                //_buildTripInfoCard(liveTripData),
                
                const SizedBox(height: 16),
                _buildParticipantsSection(newIsCompleted),
              ],
            ),
          );
        },
      ),
      floatingActionButton: isCompleted
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _editTrip(context),
              backgroundColor: Colors.green,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                'Edit Trip',
                style: TextStyle(color: Colors.white),
              ),
            ),
    );
  }

  Widget _buildStatusCard(bool isCompleted) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.orange[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.orange[200]! : Colors.green[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.pending_actions,
            color: isCompleted ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            isCompleted ? 'Trip Completed' : 'Trip Active',
            style: TextStyle(
              color: isCompleted ? Colors.orange[700] : Colors.green[700],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // The two main action buttons: Start Tracking + View GPX File
  Widget _buildActionButtons(BuildContext context, String? gpxFilePath, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.location_on),
            label: const Text('Start Tracking Participants'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripTrackingPage(tripId: tripId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.route),
            label: const Text('View GPX File'),
            onPressed: gpxFilePath != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GpxMapViewer(gpxFilePath: gpxFilePath),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: gpxFilePath != null ? Colors.blue : Colors.grey,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (gpxFilePath == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No GPX file yet. Ask participants to share location, then tap "Start Tracking Participants" to generate a GPX.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAverageRating() {
    return FutureBuilder<double>(
      future: _calculateAverageRating(),
      builder: (context, ratingSnapshot) {
        double averageRating = ratingSnapshot.data ?? 0.0;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Average Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star,
                    color: averageRating > 0 ? Colors.amber : Colors.grey[300],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    averageRating > 0
                        ? averageRating.toStringAsFixed(1)
                        : 'No ratings yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: averageRating > 0 ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripInfoCard(Map<String, dynamic> liveTripData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: value ? Colors.green[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value ? Colors.green[200]! : Colors.grey[300]!,
              ),
            ),
            child: Text(
              value ? 'Yes' : 'No',
              style: TextStyle(
                color: value ? Colors.green[700] : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection(bool isCompleted) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.group,
                  color: Colors.green[700],
                ),
                const SizedBox(width: 8),
                Text(
                  isCompleted ? 'Trip Participants' : 'Registered Participants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 400,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isCompleted
                ? _buildCompletedParticipantsList()
                : _buildCurrentParticipantsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedParticipantsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('tripId', isEqualTo: tripId)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs;
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No participants have completed this trip yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: bookings.length,
          separatorBuilder: (context, index) => Divider(color: Colors.grey[200]),
          itemBuilder: (context, index) {
            var booking = bookings[index];
            String participantId = booking['participantId'];
            double rating = (booking['rating'] ?? 0.0).toDouble();

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('participant')
                  .doc(participantId)
                  .get(),
              builder: (context, participantSnapshot) {
                if (!participantSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var participantData = participantSnapshot.data!;
                String participantName = participantData['fullName'] ?? 'Unknown';
                String emergencyNumber = participantData['emergencyNumber'] ?? 'Not available';

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green[50],
                        child: Text(
                          participantName[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              participantName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  emergencyNumber,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: rating > 0 ? Colors.amber : Colors.grey[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating > 0 ? '$rating/5' : 'Not rated',
                                  style: TextStyle(
                                    color: rating > 0 ? Colors.black87 : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            if (booking['receiptUrl'] != null) ...[
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  Uri receiptUri = Uri.parse(booking['receiptUrl']);
                                  if (await canLaunchUrl(receiptUri)) {
                                    await launchUrl(receiptUri);
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Could not open receipt'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.receipt, size: 14, color: Colors.green[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'View Receipt',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCurrentParticipantsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('tripId', isEqualTo: tripId)
          .where('status', whereIn: ['booked', 'confirmed'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs;
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No participants registered yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: bookings.length,
          separatorBuilder: (context, index) => Divider(color: Colors.grey[200]),
          itemBuilder: (context, index) {
            var booking = bookings[index];
            String participantId = booking['participantId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('participant')
                  .doc(participantId)
                  .get(),
              builder: (context, participantSnapshot) {
                if (!participantSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var participantData = participantSnapshot.data!;
                String participantName = participantData['fullName'] ?? 'Unknown';
                String emergencyNumber = participantData['emergencyNumber'] ?? 'Not available';

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green[50],
                        child: Text(
                          participantName[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              participantName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  emergencyNumber,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: booking['status'] == 'confirmed'
                              ? Colors.green[50]
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          booking['status'] == 'confirmed' ? 'Confirmed' : 'Pending',
                          style: TextStyle(
                            color: booking['status'] == 'confirmed'
                                ? Colors.green[700]
                                : Colors.orange[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  /// If you also want to delete sub-collections (like participant_locations),
  /// you'd do that in a transaction or with a Cloud Function. 
  /// This method only deletes the main 'trips/{tripId}' doc itself.
  void _deleteTrip(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).delete();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting trip: $e')),
      );
    }
  }

  void _editTrip(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTripPage(tripId: tripId),
      ),
    );
  }
}
