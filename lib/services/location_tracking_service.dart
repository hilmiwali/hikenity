//location_tracking_service.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';

class LocationTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Location _location = Location();

  /// Fetch participant locations for a specific trip
  Future<List<Map<String, dynamic>>> fetchParticipantLocations(String tripId) async {
    try {
      final querySnapshot = await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('participant_locations')
          .orderBy('timestamp', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'timestamp': data['timestamp']?.toDate()?.toIso8601String(),
        };
      }).toList();
    } catch (e) {
      print('Error fetching participant locations: $e');
      rethrow;
    }
  }

  /// Save participant location dynamically
  Future<void> saveParticipantLocation(String tripId, String participantId, double latitude, double longitude) async {
    try {
      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('participant_locations')
          .doc(participantId)
          .set({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Location saved: Trip ID: $tripId, Participant ID: $participantId, Latitude: $latitude, Longitude: $longitude');
    } catch (e) {
      print('Error saving participant location: $e');
      rethrow;
    }
  }

  /// Check and request location permissions
  Future<void> checkAndRequestPermissions() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          throw Exception('Location service is disabled.');
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          throw Exception('Location permission not granted.');
        }
      }
    } catch (e) {
      print('Error requesting location permissions: $e');
      rethrow;
    }
  }

  /// Start tracking and saving participant location manually
  Future<void> startTracking(String tripId, String participantId) async {
    try {
      await checkAndRequestPermissions();

      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        await saveParticipantLocation(
          tripId,
          participantId,
          locationData.latitude!,
          locationData.longitude!,
        );
      }
    } catch (e) {
      print('Error tracking location: $e');
      rethrow;
    }
  }

  StreamSubscription<LocationData>? _locationSubscription;
  /// Start real-time location updates
  Future<void> startRealTimeTracking(String tripId, String participantId) async {
  try {
    await checkAndRequestPermissions();
    _locationSubscription = _location.onLocationChanged.listen((locationData) async {
        if (locationData.latitude != null && locationData.longitude != null) {
          await saveParticipantLocation(
            tripId,
            participantId,
            locationData.latitude!,
            locationData.longitude!,
          );
        }
      });
    } catch (e) {
      print('Error starting real-time tracking: $e');
      rethrow;
    }
  }

  /// Stop real-time tracking (placeholder)
  Future<void> stopRealTimeTracking() async {
  if (_locationSubscription != null) {
    await _locationSubscription!.cancel();
    _locationSubscription = null;
    print('Real-time tracking canceled.');
  }
  }
}