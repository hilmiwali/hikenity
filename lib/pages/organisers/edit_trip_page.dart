//edit_trip_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditTripPage extends StatefulWidget {
  final String tripId;

  const EditTripPage({super.key, required this.tripId});

  @override
  _EditTripPageState createState() => _EditTripPageState();
}

class _EditTripPageState extends State<EditTripPage> {
  late TextEditingController _placeNameController;
  late TextEditingController _stateController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _trackLengthController;
  late TextEditingController _difficultyLevelController;
  late TextEditingController _mgpInfoController;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();

    _placeNameController = TextEditingController();
    _stateController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _trackLengthController = TextEditingController();
    _difficultyLevelController = TextEditingController();
    _mgpInfoController = TextEditingController();

    _loadTripData();
  }

  @override
  void dispose() {
    _placeNameController.dispose();
    _stateController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _trackLengthController.dispose();
    _difficultyLevelController.dispose();
    _mgpInfoController.dispose();
    super.dispose();
  }

  void _loadTripData() async {
    var tripSnapshot = await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .get();

    if (tripSnapshot.exists) {
      var tripData = tripSnapshot.data()!;

      Timestamp timestamp = tripData['date'];
      DateTime dateTime = timestamp.toDate();
      _selectedDate = dateTime;
      _selectedTime = TimeOfDay.fromDateTime(dateTime);

      setState(() {
        _placeNameController.text = tripData['placeName'] ?? '';
        _stateController.text = tripData['state'] ?? '';
        _priceController.text = tripData['price'].toString();
        _descriptionController.text = tripData['description'] ?? '';
        _trackLengthController.text = tripData['trackLength'].toString();
        _difficultyLevelController.text = tripData['difficultyLevel'].toString();
        _mgpInfoController.text = tripData['mgpInfo'] ?? '';
      });
    }
  }

  Future<String?> _getOrganizerName() async {
    String? organizerId = FirebaseAuth.instance.currentUser?.uid;
    if (organizerId != null) {
      var organiserSnapshot = await FirebaseFirestore.instance
          .collection('organisers')
          .doc(organizerId)
          .get();
      return organiserSnapshot.data()?['fullName'];
    }
    return null;
  }

  void _pickDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
      }
    }
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _saveTrip() async {
    DateTime combinedDateTime = _combineDateTime(_selectedDate, _selectedTime);
    String? organizerName = await _getOrganizerName();

    if (organizerName == null) {
      Fluttertoast.showToast(msg: 'Error: Could not fetch organizer name.');
      return;
    }

    await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).update({
      'placeName': _placeNameController.text,
      'state': _stateController.text,
      'organizerName': organizerName,
      'date': combinedDateTime,
      'price': int.tryParse(_priceController.text) ?? 0,
      'description': _descriptionController.text,
      'trackLength': int.tryParse(_trackLengthController.text) ?? 0,
      'difficultyLevel': int.tryParse(_difficultyLevelController.text) ?? 0,
      'mgpInfo': _mgpInfoController.text,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Trip'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _placeNameController,
                decoration: const InputDecoration(labelText: 'Place Name'),
              ),
              TextField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'State'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Date: ${DateFormat('yMMMd').format(_selectedDate)}, Time: ${_selectedTime.format(context)}',
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDateTime,
                    child: const Text('Select Date & Time'),
                  ),
                ],
              ),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (USD)'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: _trackLengthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Track Length'),
              ),
              TextField(
                controller: _difficultyLevelController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Difficulty Level'),
              ),
              TextField(
                controller: _mgpInfoController,
                decoration: const InputDecoration(labelText: 'MGP Info'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveTrip,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

