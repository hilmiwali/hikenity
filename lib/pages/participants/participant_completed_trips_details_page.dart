//participant_completed_trips_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class ParticipantCompletedTripsDetailsPage extends StatelessWidget {
  final Map<String, dynamic> tripData;

  const ParticipantCompletedTripsDetailsPage({super.key, required this.tripData});

  Future<double> _fetchRating() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;

    final bookingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('tripId', isEqualTo: tripData['tripDocId'])
        .where('participantId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (bookingSnapshot.docs.isNotEmpty) {
      return bookingSnapshot.docs.first.data()['rating']?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  void _saveRating(double rating, BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      var bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('tripId', isEqualTo: tripData['tripDocId'])
          .where('participantId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (bookingSnapshot.docs.isNotEmpty) {
        await bookingSnapshot.docs.first.reference.update({'rating': rating});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving rating: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkTripCompletion() async {
  try {
    if (tripData['status'] != 'completed') {
      Fluttertoast.showToast(msg: 'This trip is not marked as completed.');
      return;
    }

    if (!tripData.containsKey('startDate') ||
        !tripData.containsKey('endDate') ||
        !tripData.containsKey('participantCount')) {
      Fluttertoast.showToast(msg: 'Incomplete trip data.');
    }
  } catch (e) {
    print("Error in _checkTripCompletion: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    _checkTripCompletion();

    DateTime startDate = (tripData['startDate'] as Timestamp).toDate();
    DateTime endDate = (tripData['endDate'] as Timestamp).toDate();

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
                tripData['placeName'] ?? 'Unknown Place',
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
                  tripData['imageUrls'] != null &&
                          tripData['imageUrls'] is List &&
                          (tripData['imageUrls'] as List).isNotEmpty
                      ? Image.network(
                          (tripData['imageUrls'] as List).first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset('assets/image_not_available.png', fit: BoxFit.cover);
                          },
                        )
                      : Image.asset(
                          'assets/image_not_available.png',
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
                  _buildCompletionCard(startDate, endDate),
                  const SizedBox(height: 16),
                  _buildRatingSection(context),
                  const SizedBox(height: 16),
                  _buildDetailsCard(startDate, endDate),
                  const SizedBox(height: 16),
                  _buildImagesSection(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(DateTime startDate, DateTime endDate) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.green.shade50],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Completed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Completed on ${DateFormat('MMM d, yyyy').format(endDate)}',
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

  Widget _buildRatingSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Rate Your Experience',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: FutureBuilder<double>(
                future: _fetchRating(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    );
                  }
                  double initialRating = snapshot.data ?? 0.0;

                  return Column(
                    children: [
                      RatingBar.builder(
                        initialRating: initialRating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 40,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) => _saveRating(rating, context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to rate your experience',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(DateTime startDate, DateTime endDate) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Trip Details'),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              'Date',
              startDate == endDate
                  ? DateFormat('MMM d, yyyy').format(startDate)
                  : "${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}",
            ),
            _buildInfoRow(
                Icons.time_to_leave,
                'Meeting Time',
                tripData['meetingTime']?.toString() ?? 'Not provided',
              ),
            _buildInfoRow(Icons.location_on, 'Location', tripData['placeName']),
            _buildInfoRow(Icons.location_city, 'State', tripData['state']),
            _buildInfoRow(Icons.person, 'Organizer', tripData['organizerName']),
            _buildInfoRow(
            Icons.group,
            'Spots',
            '${tripData['participantCount'] ?? 0}/${tripData['maxParticipantCount'] ?? 0}',
          ),
            const Divider(height: 32),
            _buildSectionTitle('Trip Information'),
            const SizedBox(height: 16),
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
            const Divider(height: 32),
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
            const Divider(height: 32),
            _buildSectionTitle('Additional Information'),
            const SizedBox(height: 16),
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
  List<dynamic> imageUrls = tripData['imageUrls'] as List<dynamic>? ?? [];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border(left: BorderSide(color: Colors.green.shade700, width: 4)),
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
        _buildNoImagesPlaceholder()
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
            final imageUrl = imageUrls[index]?.toString();
            return GestureDetector(
              onTap: () => _showFullImage(context, imageUrl),
              child: _buildImageTile(imageUrl),
            );
          },
        ),
    ],
  );
}

Widget _buildNoImagesPlaceholder() {
  return Container(
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
  );
}

Widget _buildImageTile(String? imageUrl) {
  return Container(
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
      child: (imageUrl != null && imageUrl.startsWith('http'))
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset('assets/image_not_available.png', fit: BoxFit.cover);
              },
            )
          : Image.asset(
              'assets/image_not_available.png',
              fit: BoxFit.cover,
            ),
    ),
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
}