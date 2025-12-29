//gpx_service.dart
import 'dart:io';
import 'package:gpx/gpx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart'; // NEW
import 'package:cloud_firestore/cloud_firestore.dart';

/// A service class to handle GPX creation, saving, uploading, and parsing.
class GpxService {
  /// 1) Generate a GPX string from location data
  ///
  /// [userIdOrTripId] is just a name or ID to put in the GPX metadata (for reference).
  /// [locations] is a list of maps like:
  ///   {
  ///     'latitude': 3.14159,
  ///     'longitude': 101.6869,
  ///     'timestamp': '2023-10-05T12:34:56.789Z'  // or ISO8601
  ///   }
  Future<String> generateGpx(
    String userIdOrTripId,
    List<Map<String, dynamic>> locations,
  ) async {
    // Guard: if no locations, bail out
    if (locations.isEmpty) {
      throw ArgumentError('No location data provided for GPX generation.');
    }

    try {
      // Create a GPX instance
      final gpx = Gpx()
        ..metadata = Metadata(
          name: 'GPX for $userIdOrTripId',
          desc: 'Auto-generated GPX track or waypoints.',
        )
        ..wpts = locations.map((location) {
          final lat = location['latitude'];
          final lon = location['longitude'];
          final timeStr = location['timestamp'];

          if (lat == null || lon == null || timeStr == null) {
            throw Exception('Invalid waypoint data: $location');
          }

          return Wpt(
            lat: lat,
            lon: lon,
            time: DateTime.parse(timeStr),
          );
        }).toList();

      // Convert the GPX object to a pretty-printed String
      final gpxString = GpxWriter().asString(gpx, pretty: true);

      print('GPX generated successfully for: $userIdOrTripId');
      return gpxString;
    } catch (e) {
      print('Error generating GPX: $e');
      rethrow;
    }
  }

  /// 2) Save a GPX string to a local .gpx file
  ///
  /// [fileName] should not include the ".gpx" extension (we add it).
  /// Returns the absolute local file path to the saved file.
  Future<String> saveGpxToFile(String fileName, String gpxContent) async {
    try {
      // e.g., getApplicationDocumentsDirectory: /data/data/<app_id>/files
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.gpx';
      final file = File(filePath);

      // Write text to file
      await file.writeAsString(gpxContent);

      print('GPX file saved at: $filePath');
      return filePath;
    } catch (e) {
      print('Error saving GPX to file: $e');
      rethrow;
    }
  }

  /// 3) Upload a local GPX file to Firebase Storage and return a download URL.
  ///
  /// [fileName] is a short name without ".gpx". We'll store it under "gpx_files/{fileName}.gpx".
  /// [localFile] is the .gpx file to be uploaded.
  Future<String> uploadGpxFile(String fileName, File localFile) async {
    try {
      // Example Storage path: "gpx_files/trip_<id>.gpx"
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('gpx_files/$fileName.gpx');

      // Upload the file
      final uploadTask = storageRef.putFile(localFile);
      final snapshot = await uploadTask.whenComplete(() => null);

      // Fetch the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('GPX file uploaded. Download URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('Error uploading GPX file: $e');
      rethrow;
    }
  }

  /// 4) Parse a local GPX file on the device, returning a list of [Wpt].
  ///
  /// This requires the file to exist at [gpxFilePath].
  Future<List<Wpt>> parseGpxFile(String gpxFilePath) async {
    final file = File(gpxFilePath);

    if (!await file.exists()) {
      throw Exception('GPX file does not exist: $gpxFilePath');
    }

    try {
      final gpxContent = await file.readAsString();
      final gpx = GpxReader().fromString(gpxContent);

      // If the GPX has no wpts, we throw an exception
      if (gpx.wpts == null || gpx.wpts!.isEmpty) {
        throw Exception('No waypoints found in GPX file.');
      }

      print('Parsed ${gpx.wpts!.length} waypoints from GPX file.');
      return gpx.wpts!;
    } catch (e) {
      print('Error parsing local GPX file: $e');
      throw Exception('Failed to parse local GPX file: $e');
    }
  }

  /// 5) Parse a raw GPX string (e.g., downloaded from a Firebase Storage URL),
  /// returning a list of [Wpt].
  Future<List<Wpt>> parseGpxString(String gpxContent) async {
    try {
      final gpx = GpxReader().fromString(gpxContent);

      if (gpx.wpts == null || gpx.wpts!.isEmpty) {
        throw Exception('No waypoints found in GPX data.');
      }

      print('Parsed ${gpx.wpts!.length} waypoints from GPX string.');
      return gpx.wpts!;
    } catch (e) {
      print('Error parsing GPX string: $e');
      throw Exception('Failed to parse GPX string: $e');
    }
  }
}