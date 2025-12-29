// participant_ongoing_trips_details_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gal/gal.dart';
import 'package:hikenity_app/pages/participants/participant_location_page.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class ParticipantOngoingTripsDetailsPage extends StatelessWidget {
  final Map<String, dynamic> tripData;
  
  const ParticipantOngoingTripsDetailsPage({super.key, required this.tripData});

  Future<void> _cancelTrip(BuildContext context) async {
    try {
      String bookingId = tripData['bookingId'];
      String tripId = tripData['tripDocId'];

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': 'canceled'});

      DocumentReference tripRef =
          FirebaseFirestore.instance.collection('trips').doc(tripId);
      FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(tripRef);
        int currentCount = snapshot['participantCount'] ?? 0;
        if (currentCount > 0) {
          transaction.update(tripRef, {'participantCount': currentCount - 1});
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip canceled successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel trip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmParticipation(BuildContext context) async {
    String bookingId = tripData['bookingId'];

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': 'confirmed'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip participation confirmed!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm participation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleUnlistingIfNeeded(BuildContext context) async {
    if (tripData['startDate'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip date is unavailable.')),
      );
      return;
    }

    DateTime startDate = (tripData['startDate'] as Timestamp).toDate();
    DateTime cutoffDate = startDate.subtract(const Duration(days: 4));

    if (DateTime.now().isAfter(cutoffDate) && tripData['status'] == 'booked') {
      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(tripData['bookingId'])
            .update({'status': 'unlisted'});

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentReference tripRef = FirebaseFirestore.instance
              .collection('trips')
              .doc(tripData['tripDocId']);
          DocumentSnapshot tripSnapshot = await transaction.get(tripRef);

          if (tripSnapshot.exists) {
            int currentCount = tripSnapshot['participantCount'] ?? 0;
            transaction.update(
                tripRef, {'participantCount': currentCount > 0 ? currentCount - 1 : 0});
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You were unlisted from the trip due to no confirmation.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unlisting from the trip: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _handleUnlistingIfNeeded(context);
    //DateTime startDate = (tripData['startDate'] as Timestamp).toDate();
    DateTime endDate = (tripData['endDate'] as Timestamp).toDate();
    bool isBeforeEndDate = DateTime.now().isBefore(endDate);
    bool hasConfirmed = tripData['status'] == 'confirmed';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                tripData['placeName'],
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
                  Image.network(
                    'https://picsum.photos/800/400', // Replace with actual trip image
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(hasConfirmed),
                  const SizedBox(height: 16),
                  _buildDetailsCard(),
                  const SizedBox(height: 16),
                  _buildImagesSection(context),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, isBeforeEndDate, hasConfirmed),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool hasConfirmed) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: hasConfirmed
              ? [Colors.green.shade100, Colors.green.shade50]
              : [Colors.orange.shade100, Colors.orange.shade50],
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasConfirmed ? Icons.check_circle : Icons.pending,
            color: hasConfirmed ? Colors.green : Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasConfirmed ? 'Confirmed' : 'Pending Confirmation',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  hasConfirmed
                      ? 'You are all set for the trip!'
                      : 'Please confirm your participation',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildDetailsCard() {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Trip Details'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, 'Location', tripData['placeName']),
          _buildInfoRow(Icons.location_city, 'State', tripData['state']),
          _buildInfoRow(Icons.person, 'Organizer', tripData['organizerName']),
          _buildInfoRow(
            Icons.calendar_today,
            'Date',
            '${DateFormat('MMM d').format((tripData['startDate'] as Timestamp).toDate())} - '
            '${DateFormat('MMM d, yyyy').format((tripData['endDate'] as Timestamp).toDate())}',
          ),
          _buildInfoRow(
            Icons.time_to_leave,
            'Meeting Time',
            tripData['meetingTime']?.toString() ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.group,
            'Spots',
            '${tripData['participantCount'] ?? 0}/${tripData['maxParticipantCount'] ?? 0}',
          ),
          _buildDivider(),
          _buildSectionTitle('Trip Information'),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.attach_money,
            'Price',
            'RM${tripData['price']}0',
          ),
          _buildInfoRow(
            Icons.directions_walk,
            'Track Length',
            '${tripData['trackLength']} km',
          ),
          _buildInfoRow(
            Icons.height_sharp,
            'Elevation Gain',
            '${tripData['mountainHeight']}m',
          ),
          _buildInfoRow(
            Icons.assessment,
            'Difficulty',
            tripData['difficultyLevel'],
            getDifficultyColor(tripData['difficultyLevel']),
          ),
          _buildDivider(),
          _buildSectionTitle('Trip Features'),
          const SizedBox(height: 12),
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
          _buildDivider(),
          _buildSectionTitle('Additional Information'),
          const SizedBox(height: 12),
          _buildDescriptionRow('Description', tripData['description']),
          _buildDescriptionRow('MGP Information', tripData['mgpInfo']),
          if (tripData['meetingPointLink'] != null) _buildMeetingPointButton(),
          if (tripData['whatsappLink'] != null) _buildWhatsAppButton(),
          
        ],
      ),
    ),
  );
}

Widget _buildImagesSection(BuildContext context) {
  // Use tripData instead of trip to access the data
  List<dynamic> imageUrls = tripData['imageUrls'] as List<dynamic>? ?? [];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border(
            left: BorderSide(color: Colors.green.shade700, width: 4),
          ),
        ),
        child: Text(
          'Trip Images',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ),
      if (imageUrls.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                'No images available',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        )
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: imageUrls.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _showFullImage(context, imageUrls[index]),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),
    ],
  );
}

void _showFullImage(BuildContext context, String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) {
    Fluttertoast.showToast(msg: 'No image available to display.');
    return;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 100, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _downloadImage(imageUrl, context),
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text(
                    'Download',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

  Future<void> _downloadImage(String imageUrl, BuildContext context) async {
  var status = await Permission.storage.request();

  await checkPermissions();

  if (await Permission.storage.request().isGranted) {
    try {
      await Gal.putImage(imageUrl);
      Fluttertoast.showToast(msg: 'Image downloaded successfully!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to download image: $e');
    }
  } else if (await Permission.storage.isPermanentlyDenied) {
    Fluttertoast.showToast(msg: 'Permission permanently denied. Please enable storage permission in settings.');
    openAppSettings();
  } else {
    Fluttertoast.showToast(msg: 'Storage permission denied');
  }
}

Future<void> checkPermissions() async {
  if (await Permission.storage.request().isGranted) {
    print("Storage permission granted.");
  } else {
    print("Storage permission denied.");
  }

  if (await Permission.manageExternalStorage.request().isGranted) {
    print("Manage External Storage permission granted.");
  } else {
    print("Manage External Storage permission denied.");
  }
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

  Widget _buildMeetingPointButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton.icon(
        onPressed: () async {
          Uri meetingPointUri = Uri.parse(tripData['meetingPointLink']);
          if (await canLaunchUrl(meetingPointUri)) {
            await launchUrl(meetingPointUri);
          } else {
            ScaffoldMessenger.of(context as BuildContext).showSnackBar(
              const SnackBar(content: Text('Could not open the meeting point link')),
            );
          }
        },
        icon: const Icon(Icons.map, color: Colors.white),
        label: const Text('View Meeting Point'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }


Widget _buildWhatsAppButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton.icon(
        onPressed: () async {
          Uri whatsappUri = Uri.parse(tripData['whatsappLink']);
          if (await canLaunchUrl(whatsappUri)) {
            await launchUrl(whatsappUri);
          }
        },
        icon: const Icon(Icons.groups, color: Colors.white),
        label: const Text('Join WhatsApp Group'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366), // WhatsApp green
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

Widget _buildSectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.green,
    ),
  );
}

Widget _buildDivider() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Divider(color: Colors.grey.shade300),
  );
}

Color getDifficultyColor(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return Colors.green;
    case 'medium':
      return Colors.orange;
    case 'hard':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

Widget _buildInfoRow(IconData icon, String label, String value, [Color? valueColor]) {
  // If the field doesn't exist or is null, show 'Not provided'.
  String displayValue = (value != null && value.toString().isNotEmpty)
      ? value.toString()
      : 'Not provided';
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildDescriptionRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}

Widget _buildActionButtons(BuildContext context, bool isBeforeEndDate, bool hasConfirmed) {
  return Column(
    children: [
      if (isBeforeEndDate && !hasConfirmed)
        ElevatedButton.icon(
          onPressed: () => _confirmParticipation(context),
          icon: const Icon(Icons.check_circle),
          label: const Text('Confirm Participation'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      const SizedBox(height: 12),
      if (!hasConfirmed)
        ElevatedButton.icon(
          onPressed: () => _cancelTrip(context),
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel Trip'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        onPressed: () {
          final tripId = tripData['tripDocId'] as String;
          final participantId = tripData['participantId'] as String? ?? FirebaseAuth.instance.currentUser!.uid;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ParticipantLocationPage(
                tripId: tripId,
                participantId: participantId,
              ),
            ),
          );
        },
        icon: const Icon(Icons.location_on),
        label: const Text('Share My Location'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    ],
  );
}
}