// trip_details_common.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:gal/gal.dart'; // For saving images to gallery
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class TripDetailsCommon extends StatelessWidget {
   final DocumentSnapshot<Object?>? trip; // Make this nullable
   final String tripId;
   final List<dynamic> imageUrls;

  const TripDetailsCommon({super.key, this.trip, required this.tripId, required this.imageUrls});

  String _formatDate(Timestamp timestamp) {
    return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
  var tripData = trip?.data() as Map<String, dynamic>;
  var startDate = tripData['startDate'] != null 
      ? _formatDate(tripData['startDate'] as Timestamp) 
      : 'Not provided';
  var endDate = tripData['endDate'] != null 
      ? _formatDate(tripData['endDate'] as Timestamp) 
      : 'Not provided';
  String dateRange = startDate == endDate ? startDate : "$startDate to $endDate";

  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.green.shade50, Colors.white],
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade700],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.place, color: Colors.white, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      trip?['placeName'] ?? 'Trip Details',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection('Location Details', [
                    _buildTripInfoRow(Icons.location_city, 'State', trip?['state']),
                    _buildTripInfoRow(Icons.person, 'Organizer', trip?['organizerName']),
                  ]),
                  _buildInfoSection('Trip Details', [
                    _buildTripInfoRow(Icons.calendar_today, 'Date', dateRange),
                    _buildTripInfoRow(
                        Icons.time_to_leave, 
                        'Meeting Time', 
                        tripData['meetingTime'] ?? 'Not provided'
                      ),
                    _buildTripInfoRow(Icons.attach_money, 'Price', 'RM${trip?['price']}0'),
                    _buildTripInfoRow(Icons.track_changes, 'Track Length', '${trip?['trackLength']} km'),
                    _buildTripInfoRow(Icons.track_changes, 'Elevation Gain', '${trip?['mountainHeight']}m'),
                    _buildTripInfoRow(
                      Icons.group,
                      'Spots',
                      '${tripData['participantCount'] ?? 0}/${tripData['maxParticipantCount'] ?? 0}',
                      ),
                    _buildTripInfoRow(Icons.bar_chart, 'Difficulty Level', trip?['difficultyLevel']),
                  ]),
                  _buildInfoSection('Trip Features', [
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
                              ]
                            ),
                  _buildInfoSection('Additional Information', [
                    _buildTripInfoRow(Icons.info_outline, 'MGP Info', trip?['mgpInfo']),
                    _buildTripInfoRow(Icons.description, 'Description', trip?['description']),
                    if (tripData['meetingPointLink'] != null)
                        _buildMeetingPointButton(tripData['meetingPointLink'], context),
                      if (tripData['whatsappLink'] != null)
                        _buildWhatsAppButton(tripData['whatsappLink'], context),
                  ]),
                  _buildImagesSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildMeetingPointButton(String meetingPointLink, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton.icon(
        onPressed: () async {
          Uri meetingPointUri = Uri.parse(meetingPointLink);
          if (await canLaunchUrl(meetingPointUri)) {
            await launchUrl(meetingPointUri);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
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

  Widget _buildWhatsAppButton(String whatsappLink, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton.icon(
        onPressed: () async {
          Uri whatsappUri = Uri.parse(whatsappLink);
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

Widget _buildInfoSection(String title, List<Widget> children) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border(
              left: BorderSide(color: Colors.green.shade700, width: 4),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ),
        ...children,
      ],
    ),
  );
}

  Widget _buildTripInfoRow(IconData icon, String title, String? value) {
    // If the field doesn't exist or is null, show 'Not provided'.
  String displayValue = (value != null && value.toString().isNotEmpty)
      ? value.toString()
      : 'Not provided';
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.green.shade700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value ?? 'Not provided',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildImagesSection(BuildContext context) {
  final tripData = trip?.data() as Map<String, dynamic>?;
  List<dynamic>? imageUrls = tripData?['imageUrls'] as List<dynamic>? ?? [];

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

  // Function to display image in full screen
  void _showFullImage(BuildContext context, String imageUrl) {
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
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _downloadImage(imageUrl, context),
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text(
                  'Download Image',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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


}