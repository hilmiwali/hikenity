// edit_trip_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as Path;
import 'package:intl/intl.dart';

class EditTripPage extends StatefulWidget {
  final String tripId;

  const EditTripPage({super.key, required this.tripId});

  @override
  _EditTripPageState createState() => _EditTripPageState();
}

class _EditTripPageState extends State<EditTripPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _meetingPointController = TextEditingController();
  final TextEditingController _trackLengthController = TextEditingController();
  final TextEditingController _mountainHeightController = TextEditingController();
  final TextEditingController _mgpInfoController = TextEditingController();
  final TextEditingController _whatsappLinkController = TextEditingController();
  final TextEditingController _maxParticipantCountController = TextEditingController();

  List<File> _images = [];
  List<String> _uploadedFileURLs = [];
  final picker = ImagePicker();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _meetingTime = TimeOfDay.now();

  String _selectedState = 'Select State';
  final List<String> _states = [
    'Select State',
    'Perlis',
    'Kedah',
    'Pulau Pinang',
    'Perak',
    'Kelantan',
    'Terengganu',
    'Pahang',
    'Johor',
    'Negeri Sembilan',
    'Melaka',
    'Kuala Lumpur',
    'Selangor',
    'Sabah',
    'Sarawak',
    'Labuan'
  ];

  String _selectedDifficulty = 'Select Difficulty';
  final List<String> _difficultyLevels = [
    'Select Difficulty',
    'Easy',
    'Medium',
    'Hard'
  ];

  bool _isRange = false;
  bool _isRationProvided = false;
  bool _is4x4Provided = false;
  bool _isCampingRequired = false;
  bool _bringOwnCamp = false;
  bool _isFreeTrip = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  Future<void> _loadTripData() async {
    var tripSnapshot = await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .get();

    if (tripSnapshot.exists) {
      var tripData = tripSnapshot.data()!;

      setState(() {
        _placeNameController.text = tripData['placeName'] ?? '';
        _priceController.text = tripData['price'].toString();
        _descriptionController.text = tripData['description'] ?? '';
        _meetingPointController.text = tripData['meetingPointLink'] ?? '';
        _trackLengthController.text = tripData['trackLength'].toString();
        _mountainHeightController.text = tripData['mountainHeight'].toString();
        _mgpInfoController.text = tripData['mgpInfo'] ?? '';
        _whatsappLinkController.text = tripData['whatsappLink'] ?? '';
        _maxParticipantCountController.text =
            tripData['maxParticipantCount'].toString();
        _selectedState = tripData['state'] ?? 'Select State';
        _selectedDifficulty = tripData['difficultyLevel'] ?? 'Select Difficulty';
        _isRationProvided = tripData['isRationProvided'] ?? false;
        _is4x4Provided = tripData['is4x4Provided'] ?? false;
        _isCampingRequired = tripData['isCampingRequired'] ?? false;
        _bringOwnCamp = tripData['bringOwnCamp'] ?? false;
        _isFreeTrip = tripData['isFreeTrip'] ?? false;

        _startDate = (tripData['startDate'] as Timestamp).toDate();
        _endDate = (tripData['endDate'] as Timestamp).toDate();
        _meetingTime = TimeOfDay.fromDateTime(_startDate);
        _uploadedFileURLs = List<String>.from(tripData['imageUrls'] ?? []);
      });
    }
  }

  Future<void> chooseFiles() async {
    final List<XFile>? pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _images = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> uploadFiles() async {
    if (_images.isEmpty) {
      Fluttertoast.showToast(msg: "No images selected.");
      return;
    }

    try {
      List<String> downloadURLs = [];
      for (File image in _images) {
        String fileName = Path.basename(image.path);
        final ref = FirebaseStorage.instance.ref('trip_images/$fileName');
        await ref.putFile(image);
        String downloadURL = await ref.getDownloadURL();
        downloadURLs.add(downloadURL);
      }

      setState(() {
        _uploadedFileURLs = downloadURLs;
      });

      Fluttertoast.showToast(msg: "Images uploaded successfully!");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to upload images: $e");
    }
  }

  void _pickStartDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
      });
    }
  }

  void _pickEndDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      setState(() => _endDate = pickedDate);
    }
  }

  void _pickMeetingTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _meetingTime,
    );
    if (pickedTime != null) {
      setState(() => _meetingTime = pickedTime);
    }
  }

  void _saveTrip() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await uploadFiles();
        await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).update({
          'placeName': _placeNameController.text,
          'state': _selectedState,
          'price': _isFreeTrip ? 0.0 : double.parse(_priceController.text),
          'isFreeTrip': _isFreeTrip,
          'description': _descriptionController.text,
          'meetingPointLink': _meetingPointController.text,
          'trackLength': double.parse(_trackLengthController.text),
          'mountainHeight': double.parse(_mountainHeightController.text),
          'difficultyLevel': _selectedDifficulty,
          'mgpInfo': _mgpInfoController.text,
          'startDate': _startDate,
          'endDate': _endDate,
          'meetingTime': '${_meetingTime.hour}:${_meetingTime.minute.toString().padLeft(2, '0')}',
          'maxParticipantCount': int.parse(_maxParticipantCountController.text),
          'whatsappLink': _whatsappLinkController.text,
          'isRationProvided': _isRationProvided,
          'is4x4Provided': _is4x4Provided,
          'isCampingRequired': _isCampingRequired,
          'bringOwnCamp': _bringOwnCamp,
          'imageUrls': _uploadedFileURLs,
        });

        Fluttertoast.showToast(msg: 'Trip updated successfully');
        Navigator.pop(context);
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Trip',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
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
                      return DropdownMenuItem(
                        value: state,
                        child: Text(state),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedState = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: '',
                      prefixIcon: const Icon(Icons.map, color: Colors.green),
                      filled: true,
                      fillColor: Colors.green[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _placeNameController,
                    decoration: InputDecoration(
                      labelText: 'Place Name',
                      prefixIcon: const Icon(Icons.place, color: Colors.green),
                      filled: true,
                      fillColor: Colors.green[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the place name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height:20),

                  ElevatedButton(
                    onPressed: chooseFiles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Choose Images'),
                  ),
                  if (_images.isNotEmpty)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _images
                          .map((image) => Image.file(image, width: 100, height: 100))
                          .toList(),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: uploadFiles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Upload Images'),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('Is this a multi-day trip?'),
                    value: _isRange,
                    activeColor: Colors.green,
                    onChanged: (bool value) {
                      setState(() {
                        _isRange = value;
                        });
                      },
                    ),

                  const SizedBox(height: 10),
                  Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Start Date: ${DateFormat('yMMMd').format(_startDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: _pickStartDate,
                  ),
                ],
              ),
              if (_isRange) Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'End Date: ${DateFormat('yMMMd').format(_endDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: _pickEndDate,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Meeting Time: ${_meetingTime.format(context)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.access_time),
                    onPressed: _pickMeetingTime,
                  ),
                ],
              ),
                  const SizedBox(height: 5),
                  SwitchListTile(
                    title: const Text('Is this a free trip?'),
                    value: _isFreeTrip,
                    activeColor: Colors.green,
                    onChanged: (value) {
                      setState(() {
                        _isFreeTrip = value;
                        if (value) {
                          _priceController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price (MYR)',
                      prefixIcon: const Icon(Icons.monetization_on,
                          color: Colors.green),
                      filled: true,
                      fillColor: Colors.green[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_isFreeTrip,
                    validator: (value) {
                      if (!_isFreeTrip && (value == null || value.isEmpty)) {
                        return 'Please enter the price';
                      }
                      if (!_isFreeTrip && double.tryParse(value!) == null) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description/Announcement',
                      prefixIcon: const Icon(Icons.description,
                          color: Colors.green),
                      filled: true,
                      fillColor: Colors.green[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description or announcement';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height:20),
                  TextFormField(
                    controller: _meetingPointController,
                    decoration: InputDecoration(
                      labelText: 'Meeting Point Link',
                      prefixIcon: const Icon(Icons.link, color: Colors.green),
                      filled: true,
                      fillColor: Colors.green[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                        ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the meeting point link';
                            }
                            // Optional: Add validation for URLs
                            if (!Uri.parse(value).isAbsolute) {
                              return 'Please enter a valid URL';
                              }
                              return null;
                              },
                            ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _trackLengthController,
                    decoration: InputDecoration(
                      labelText: 'Track Length (km)',
                      prefixIcon: const Icon(Icons.terrain, color: Colors.green),
                      filled: true,
                      fillColor: Colors.green[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
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
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _mountainHeightController,
                    decoration: InputDecoration(
                      labelText: 'Mountain Height (Meters)',
                      prefixIcon: const Icon(Icons.landscape, color: Colors.green),
                      filled: true,
                      fillColor: Colors.green[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                        ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the mountain height';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                              }
                              return null;
                              },
                              ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    items: _difficultyLevels.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: '',
                      prefixIcon: const Icon(Icons.signal_cellular_alt,
                          color: Colors.green),
                      filled: true,
                      fillColor: Colors.green[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == 'Select Difficulty') {
                        return 'Please select a difficulty level';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _mgpInfoController,
                    decoration: InputDecoration(
                      labelText: 'MGP (Malim Gunung Perhutanan) Info',
                      prefixIcon: const Icon(Icons.info_outline,
                          color: Colors.green),
                      filled: true,
                      fillColor: Colors.green[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter MGP info';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _whatsappLinkController,
                    decoration: InputDecoration(
                      labelText: 'WhatsApp Group Link',
                      prefixIcon: const Icon(Icons.link, color: Colors.green),
                      filled: true,
                      fillColor: Colors.green[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the WhatsApp group link';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _maxParticipantCountController,
                    decoration: InputDecoration(
                      labelText: 'Max Participants',
                      prefixIcon: const Icon(Icons.people, color: Colors.green),
                      filled: true,
                      fillColor: Colors.green[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the maximum number of participants';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Is Ration Provided?'),
                    value: _isRationProvided,
                    activeColor: Colors.green,
                    onChanged: (value) {
                      setState(() {
                        _isRationProvided = value;
                      });
                    },
                  ),
                  const SizedBox(height:10),
                  SwitchListTile(
                    title: const Text('Is 4x4 Provided?'),
                    value: _is4x4Provided,
                    activeColor: Colors.green,
                    onChanged: (bool value) {
                      setState(() {
                        _is4x4Provided = value;
                        });
                      },
                    ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Is Night Sleep (Camping) Required?'),
                    value: _isCampingRequired,
                    activeColor: Colors.green,
                    onChanged: (value) {
                      setState(() {
                        _isCampingRequired = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (_isCampingRequired)
                    SwitchListTile(
                      title: const Text(
                          'Do Participants Need to Bring Their Own Camp?'),
                      value: _bringOwnCamp,
                      activeColor: Colors.green,
                      onChanged: (value) {
                        setState(() {
                          _bringOwnCamp = value;
                        });
                      },
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveTrip,
                    child: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
