// participant_location_page.dart

import 'package:flutter/material.dart';
import 'package:hikenity_app/pages/participants/location_tracking_manager.dart';

// We still use your location_tracking_service.dart for the *one-time* share
import 'package:hikenity_app/services/location_tracking_service.dart';

class ParticipantLocationPage extends StatefulWidget {
  final String tripId;
  final String participantId;

  const ParticipantLocationPage({
    Key? key,
    required this.tripId,
    required this.participantId,
  }) : super(key: key);

  @override
  _ParticipantLocationPageState createState() => _ParticipantLocationPageState();
}

class _ParticipantLocationPageState extends State<ParticipantLocationPage> {
  // For one-time share
  final LocationTrackingService _locationTrackingService = LocationTrackingService();

  // For real-time tracking
  final LocationTrackingManager _locationManager = LocationTrackingManager();

  bool _isTracking = false;
  String? _statusMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check if manager is already tracking from a previous session:
    _isTracking = _locationManager.isTracking;
  }

  // 1) One-time location share
  Future<void> _shareLocationOnce() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    try {
      // This uses your old single-shot approach from location_tracking_service
      await _locationTrackingService.checkAndRequestPermissions();
      await _locationTrackingService.startTracking(widget.tripId, widget.participantId);

      setState(() {
        _statusMessage = 'Location shared once successfully.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error sharing location: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 2) Real-time tracking using the global manager
  Future<void> _startRealTimeTracking() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    try {
      // Use the manager now instead of location_tracking_service
      await _locationManager.startRealTimeTracking(widget.tripId, widget.participantId);

      setState(() {
        _isTracking = _locationManager.isTracking; // should now be true
        _statusMessage = 'Real-time tracking started (via global manager).';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error starting real-time tracking: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _stopRealTimeTracking() async {
    // We call the manager's stop method
    await _locationManager.stopRealTimeTracking();
    setState(() {
      _isTracking = _locationManager.isTracking; // should now be false
      _statusMessage = 'Real-time tracking stopped.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share My Location'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status message
            if (_statusMessage != null)
              Text(
                _statusMessage!,
                style: const TextStyle(color: Colors.blue),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),

            // 1) One-time share button
            ElevatedButton(
              onPressed: _isLoading ? null : _shareLocationOnce,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Share Location (One-Time)'),
            ),
            const SizedBox(height: 20),

            // 2) Start real-time tracking
            ElevatedButton(
              onPressed: (_isLoading || _isTracking) ? null : _startRealTimeTracking,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Start Real-Time Tracking'),
            ),
            const SizedBox(height: 20),

            // 3) Stop real-time tracking
            ElevatedButton(
              onPressed: _isTracking ? _stopRealTimeTracking : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Stop Real-Time Tracking'),
            ),
          ],
        ),
      ),
    );
  }
}
