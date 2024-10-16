//organiser_create_trips.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrganiserCreateTripPage extends StatefulWidget {
  const OrganiserCreateTripPage({super.key});

  @override
  _OrganiserCreateTripPageState createState() =>
      _OrganiserCreateTripPageState();
}

class _OrganiserCreateTripPageState extends State<OrganiserCreateTripPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _trackLengthController = TextEditingController();
  final TextEditingController _mgpInfoController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  String _selectedState = 'Select State';
  final List<String> _states = [
    'Select State', 'Perlis', 'Kedah', 'Pulau Pinang', 'Perak', 'Kelantan',
    'Terengganu', 'Pahang', 'Johor', 'Negeri Sembilan', 'Melaka',
    'Kuala Lumpur', 'Selangor', 'Sabah', 'Sarawak', 'Labuan'
  ];

  String _selectedDifficulty = 'Select Difficulty';
  final List<String> _difficultyLevels = ['Select Difficulty', 'Easy', 'Medium', 'Hard'];

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

  bool _isLoading = false;

  Future<String?> _getOrganizerName() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        var organiserSnapshot = await FirebaseFirestore.instance
            .collection('organisers')
            .doc(uid)
            .get();
        return organiserSnapshot.data()?['fullName'];
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching organizer name: $e');
    }
    return null;
  }

  void _createTrip() async {
    setState(() {
      _isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      if (_selectedState == 'Select State') {
        Fluttertoast.showToast(msg: 'Please select a valid state.');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      if (_selectedDifficulty == 'Select Difficulty') {
        Fluttertoast.showToast(msg: 'Please select a difficulty level.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        DateTime combinedDateTime = _combineDateTime(_selectedDate, _selectedTime);
        String? fullName = await _getOrganizerName();
        String? organizerId = FirebaseAuth.instance.currentUser?.uid;

        if (fullName == null || organizerId == null) {
          Fluttertoast.showToast(msg: 'Error: Could not fetch organizer info.');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        DocumentReference newTripRef = FirebaseFirestore.instance.collection('trips').doc();

        await FirebaseFirestore.instance.collection('trips').add({
          'tripId': newTripRef.id,
          'placeName': _placeNameController.text,
          'organizerName': fullName,
          'organizerId': organizerId,
          'price': double.parse(_priceController.text), // Price in USD
          'description': _descriptionController.text,
          'state': _selectedState,
          'trackLength': double.parse(_trackLengthController.text),
          'difficultyLevel': _selectedDifficulty,
          'mgpInfo': _mgpInfoController.text,
          'date': combinedDateTime,
          'createdAt': Timestamp.now(),
        });

        Fluttertoast.showToast(msg: 'Trip Created Successfully');
        Navigator.pushReplacementNamed(context, '/organiserMain');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _placeNameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _trackLengthController.dispose();
    _mgpInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Stack(
            children: [
              ListView(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedState,
                    items: _states.map((state) {
                      return DropdownMenuItem(value: state, child: Text(state));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedState = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Select State'),
                    validator: (value) {
                      if (value == 'Select State') {
                        return 'Please select a state';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _placeNameController,
                    decoration: const InputDecoration(labelText: 'Place Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the place name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price (USD)'), // Price label updated to USD
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _trackLengthController,
                    decoration: const InputDecoration(labelText: 'Track Length (km)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the track length';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid track length';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    items: _difficultyLevels.map((level) {
                      return DropdownMenuItem(value: level, child: Text(level));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Difficulty Level'),
                    validator: (value) {
                      if (value == 'Select Difficulty') {
                        return 'Please select a difficulty level';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _mgpInfoController,
                    decoration: const InputDecoration(labelText: 'MGP (Malim Gunung Perhutanan) Info'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter MGP info';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _createTrip,
                    child: const Text('Create'),
                  ),
                ],
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


