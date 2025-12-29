// location_tracking_manager.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';

/// A global/singleton manager for real-time location tracking,
/// so state persists even if the UI is rebuilt.
class LocationTrackingManager {
  // 1) The singleton instance
  static final LocationTrackingManager _instance = LocationTrackingManager._internal();
  factory LocationTrackingManager() => _instance;
  LocationTrackingManager._internal();

  // 2) The location plugin & Firestore reference
  final Location _location = Location();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 3) Subscription for streaming location data
  StreamSubscription<LocationData>? _locationSubscription;

  // 4) A simple boolean for UI to know if we are currently tracking
  bool isTracking = false;

  // (Optional) Stash which trip/participant is being tracked, for reference
  String? _tripId;
  String? _participantId;

  /// Start real-time tracking if not already tracking
  Future<void> startRealTimeTracking(String tripId, String participantId) async {
    // If we're already tracking, do nothing
    if (isTracking) return;

    _tripId = tripId;
    _participantId = participantId;

    // Request location permissions & check if enabled
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        throw Exception('Location service is disabled.');
      }
    }

    PermissionStatus permissionStatus = await _location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await _location.requestPermission();
      if (permissionStatus != PermissionStatus.granted) {
        throw Exception('Location permission denied.');
      }
    }

    // Start streaming
    _locationSubscription = _location.onLocationChanged.listen((locationData) async {
      if (locationData.latitude != null && locationData.longitude != null) {
        await _saveParticipantLocation(
          _tripId!,
          _participantId!,
          locationData.latitude!,
          locationData.longitude!,
        );
      }
    });

    isTracking = true;
    print('Global Manager: Real-time tracking started for participantId=$_participantId on tripId=$_tripId');
  }

  /// Stop streaming
  Future<void> stopRealTimeTracking() async {
    if (_locationSubscription != null) {
      await _locationSubscription!.cancel();
      _locationSubscription = null;
      print('Global Manager: Real-time tracking subscription canceled.');
    }
    isTracking = false;
    _tripId = null;
    _participantId = null;
  }

  // Private helper to save location in Firestore
  Future<void> _saveParticipantLocation(
    String tripId,
    String participantId,
    double lat,
    double lon,
  ) async {
    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('participant_locations')
        .doc(participantId)
        .set({
      'latitude': lat,
      'longitude': lon,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('Global Manager: Location saved for $participantId on trip $tripId');
  }
}
