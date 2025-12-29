//trip_tracking_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hikenity_app/services/gpx_service.dart';
import 'package:hikenity_app/services/location_tracking_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hikenity_app/theme/app_colors.dart';

class TripTrackingPage extends StatefulWidget {
  final String tripId;
  const TripTrackingPage({Key? key, required this.tripId}) : super(key: key);

  @override
  _TripTrackingPageState createState() => _TripTrackingPageState();
}

class _TripTrackingPageState extends State<TripTrackingPage> {
  final GpxService _gpxService = GpxService();
  final LocationTrackingService _locationTrackingService = LocationTrackingService();
  String? gpxFileUrl;
  bool isLoading = false;

  /// Generate a GPX string from participant locations, save locally (optional),
  /// then upload the file to Firebase Storage so other devices can see the same GPX.
  Future<void> generateAndUploadGPX() async {
    setState(() => isLoading = true);

    try {
      // 1) Fetch participant locations from Firestore
      final locations = await _locationTrackingService.fetchParticipantLocations(widget.tripId);

      if (locations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No participant locations available.')),
        );
        return;
      }

      // 2) Generate GPX string
      final gpxString = await _gpxService.generateGpx(widget.tripId, locations);

      // 3) (Optional) Save the GPX file locally
      final localPath = await _gpxService.saveGpxToFile('trip_${widget.tripId}', gpxString);
      final localFile = File(localPath);

      if (!await localFile.exists()) {
        throw Exception('File saving failed.');
      }

      // 4) Upload to Firebase Storage
      final downloadUrl = await _gpxService.uploadGpxFile('trip_${widget.tripId}', localFile);

      // 5) Update Firestore with the download URL instead of a local file path
      await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).update({
        'gpxFilePath': downloadUrl,
      });

      setState(() {
        gpxFileUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPX uploaded. URL: $downloadUrl')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate or upload GPX file: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trip Tracking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  'Generate and Upload GPX',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Button to generate & upload the GPX file
                ElevatedButton.icon(
                  onPressed: isLoading ? null : generateAndUploadGPX,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.file_upload, color: Colors.white),
                  label: Text(
                    isLoading ? 'Uploading...' : 'Generate & Upload GPX',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 30),

                // Show the GPX URL if available
                if (gpxFileUrl != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'GPX Download URL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          gpxFileUrl!,
                          style: const TextStyle(color: Colors.blue),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
