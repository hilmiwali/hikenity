//organiser_profile_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage for image upload
import 'dart:io'; // For handling file operations

class OrganiserProfilePage extends StatefulWidget {
  const OrganiserProfilePage({super.key});

  @override
  _OrganiserProfilePageState createState() => _OrganiserProfilePageState();
}

class _OrganiserProfilePageState extends State<OrganiserProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();

  String? _fullName;
  String? _email;
  String? _phoneNumber;
  String? _profileImageUrl;
  File? _profileImage;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Function to load user profile from Firestore
  Future<void> _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot snapshot = await _firestore.collection('organisers').doc(user.uid).get();
        if (snapshot.exists) {
          Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
          setState(() {
            _fullName = data?['fullName'] ?? '';
            _phoneNumber = data?['phoneNumber'] ?? '';
            _profileImageUrl = data?['profileImageUrl'] ?? '';
            _fullNameController.text = _fullName ?? '';
            _phoneNumberController.text = _phoneNumber ?? '';
          });
        }
        // Set email from FirebaseAuth
        setState(() {
          _email = user.email;
          _emailController.text = _email ?? '';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    }
  }

  // Function to pick a profile image
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      // After selecting the image, upload it
      _uploadProfileImage();
    }
  }

  // Function to upload profile image to Firebase Storage
  Future<void> _uploadProfileImage() async {
    if (_profileImage != null) {
      try {
        User? user = _auth.currentUser;
        if (user != null) {
          // Create the storage reference
          final storageRef = _storage.ref().child('profile_images/${user.uid}.jpg');

          // Upload the selected image file
          UploadTask uploadTask = storageRef.putFile(_profileImage!);
          TaskSnapshot snapshot = await uploadTask;

          // Get the download URL of the uploaded file
          String downloadUrl = await snapshot.ref.getDownloadURL();

          // Save the download URL in Firestore
          await _firestore.collection('organisers').doc(user.uid).update({
            'profileImageUrl': downloadUrl,
          });

          setState(() {
            _profileImageUrl = downloadUrl;
          });

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile image uploaded successfully')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload profile image: $e')));
      }
    }
  }

  // Function to save the profile to Firestore
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      User? user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore.collection('organisers').doc(user.uid).set({
            'fullName': _fullNameController.text,
            'email': _emailController.text,  // Already filled with Google account email
            'phoneNumber': _phoneNumberController.text,
          }, SetOptions(merge: true)); // Use merge to update or add fields

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile.')));
        }
      }
    }
  }

  // Function to log out the user
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to log out: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout, // Logout function is called when the logout icon is pressed
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : (_profileImage != null
                        ? FileImage(_profileImage!)
                        : const AssetImage('assets/default_profile.png')) as ImageProvider,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Tap to change profile picture', textAlign: TextAlign.center),
            const SizedBox(height: 30),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email Address'),
                    readOnly: true, // Email field should be read-only
                  ),
                  TextFormField(
                    controller: _phoneNumberController,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save Profile'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/notificationSettings');
                    },
                    child: const Text('Notification Settings'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _logout,
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
