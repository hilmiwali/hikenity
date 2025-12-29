import 'package:flutter/material.dart';
import 'package:hikenity_app/services/location_tracking_service.dart';
import 'package:hikenity_app/services/gpx_service.dart';

class GPXTestPage extends StatefulWidget {
  final String tripId;
  const GPXTestPage({Key? key, required this.tripId}) : super(key: key);

  @override
  _GPXTestPageState createState() => _GPXTestPageState();
}

class _GPXTestPageState extends State<GPXTestPage> {
  final LocationTrackingService _locationTrackingService = LocationTrackingService();
  final GpxService _gpxService = GpxService();

  String? gpxFilePath;
  String? parsedWaypoints;

  Future<void> simulateAndTestGPX() async {
    try {
      // Step 1: Simulate participant location data
      await _locationTrackingService.saveParticipantLocation(
        widget.tripId,
        "participant_1",
        3.1390, // Example latitude (Kuala Lumpur)
        101.6869, // Example longitude
      );
      await _locationTrackingService.saveParticipantLocation(
        widget.tripId,
        "participant_2",
        3.1500,
        101.7000,
      );

      // Step 2: Fetch participant locations
      final locations = await _locationTrackingService.fetchParticipantLocations(widget.tripId);
      print("Fetched Locations: $locations");

      // Step 3: Generate GPX string
      final gpxString = await _gpxService.generateGpx(widget.tripId, locations);
      print("Generated GPX String: $gpxString");

      // Step 4: Save GPX to file
      final savedFilePath = await _gpxService.saveGpxToFile('trip_${widget.tripId}', gpxString);
      print("Saved GPX File Path: $savedFilePath");

      setState(() {
        gpxFilePath = savedFilePath;
      });

      // Step 5: Parse the GPX file
      final waypoints = await _gpxService.parseGpxFile(savedFilePath);
      print("Parsed Waypoints: $waypoints");

      setState(() {
        parsedWaypoints = waypoints
            .map((wpt) => 'Lat: ${wpt.lat}, Lon: ${wpt.lon}, Time: ${wpt.time}')
            .join('\n');
      });
    } catch (e) {
      print("Error during GPX testing: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test GPX Functionality'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: simulateAndTestGPX,
              child: const Text('Test GPX Functionality'),
            ),
            if (gpxFilePath != null)
              Text('GPX File Path:\n$gpxFilePath', textAlign: TextAlign.center),
            const SizedBox(height: 10),
            if (parsedWaypoints != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text('Parsed Waypoints:\n$parsedWaypoints'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
