//gpx_map_viewer.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hikenity_app/services/gpx_service.dart';
import 'package:http/http.dart' as http;

class GpxMapViewer extends StatefulWidget {
  final String gpxFilePath;
  const GpxMapViewer({Key? key, required this.gpxFilePath}) : super(key: key);

  @override
  _GpxMapViewerState createState() => _GpxMapViewerState();
}

class _GpxMapViewerState extends State<GpxMapViewer> {
  final GpxService _gpxService = GpxService();
  List<LatLng> waypoints = [];
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    loadGPXWaypoints();
  }

  Future<void> loadGPXWaypoints() async {
    try {
      // If gpxFilePath is a remote URL, fetch it:
      final uri = Uri.parse(widget.gpxFilePath);
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch GPX file (status: ${response.statusCode})');
      }

      final gpxData = response.body;
      
      // We can reuse GpxService to parse a raw string (add a new parseGpxString method)
      final wpts = await _gpxService.parseGpxString(gpxData); 
      
      setState(() {
        waypoints = wpts.map((wpt) => LatLng(wpt.lat!, wpt.lon!)).toList();
      });

      if (_mapController != null && waypoints.isNotEmpty) {
        fitMapToBounds();
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load GPX from URL: $e')),
      );
    }
  }

  void fitMapToBounds() { 
    if (waypoints.isEmpty || _mapController == null) return;
    final bounds = LatLngBounds(
      southwest: waypoints.reduce((a, b) => LatLng(
        a.latitude < b.latitude ? a.latitude : b.latitude,
        a.longitude < b.longitude ? a.longitude : b.longitude,
      )),
      northeast: waypoints.reduce((a, b) => LatLng(
        a.latitude > b.latitude ? a.latitude : b.latitude,
        a.longitude > b.longitude ? a.longitude : b.longitude,
      )),
    );
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPX Viewer'),
        backgroundColor: Colors.green,
      ),
      body: waypoints.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: waypoints.first,
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                fitMapToBounds();
              },
              markers: waypoints
                  .map((point) => Marker(
                        markerId: MarkerId(point.toString()),
                        position: point,
                      ))
                  .toSet(),
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: waypoints,
                  color: Colors.blue,
                  width: 4,
                ),
              },
            ),
    );
  }
}