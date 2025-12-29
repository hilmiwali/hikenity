//participant_profile_page.dart
import 'package:flutter/material.dart';
import 'package:hikenity_app/pages/privacy_policy_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'receipts_page.dart';

class ParticipantProfilePage extends StatefulWidget {
  const ParticipantProfilePage({super.key});

  @override
  _ParticipantProfilePageState createState() => _ParticipantProfilePageState();
}

class _ParticipantProfilePageState extends State<ParticipantProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();

  String? _fullName;
  String? _email;
  String? _phoneNumber;
  String? _emergencyNumber;
  String? _profileImageUrl;
  String? _nickname; 
  String? _icNumber; 
  String? _homeAddress;
  File? _profileImage;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emergencyNumberController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _icNumberController = TextEditingController();
  final TextEditingController _homeAddressController = TextEditingController();

  bool _canChangePassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkAuthProvider();
  }

  void _checkAuthProvider() {
  User? user = FirebaseAuth.instance.currentUser;
  print("Provider data length: ${user?.providerData.length}"); // Check how many providers are associated

  for (var provider in user!.providerData) {
    print("Provider ID: ${provider.providerId}"); // This should show 'password' for email/password
  }

  String? providerId = user.providerData[0].providerId; // Consider checking each provider if multiple exist
  if (providerId == 'password') {
    _canChangePassword = true;
  } else {
    _canChangePassword = false;
  }
}

  Future<void> _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot snapshot = await _firestore.collection('participant').doc(user.uid).get();
        if (snapshot.exists) {
          Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
          setState(() {
            _fullName = data?['fullName'] ?? '';
            _nickname = data?['nickname'] ?? '';
            _icNumber = data?['icNumber'] ?? '';
            _homeAddress = data?['homeAddress'] ?? '';
            _phoneNumber = data?['phoneNumber'] ?? '';
            _emergencyNumber = data?['emergencyNumber'] ?? '';
            _profileImageUrl = data?['profileImageUrl'] ?? '';

            _fullNameController.text = _fullName ?? '';
            _nicknameController.text = _nickname ?? '';
            _icNumberController.text = _icNumber ?? '';
            _homeAddressController.text = _homeAddress ?? '';
            _phoneNumberController.text = _phoneNumber ?? '';
            _emergencyNumberController.text = _emergencyNumber ?? '';
          });
        }
        setState(() {
          _email = user.email;
          _emailController.text = _email ?? '';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load profile: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      _uploadProfileImage();
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage != null) {
      try {
        User? user = _auth.currentUser;
        if (user != null) {
          final storageRef = _storage.ref().child('profile_images/${user.uid}.jpg');
          UploadTask uploadTask = storageRef.putFile(_profileImage!);
          TaskSnapshot snapshot = await uploadTask;
          String downloadUrl = await snapshot.ref.getDownloadURL();

          await _firestore.collection('participant').doc(user.uid).update({
            'profileImageUrl': downloadUrl,
          });

          setState(() {
            _profileImageUrl = downloadUrl;
          });

          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile image uploaded successfully')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload profile image: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      User? user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore.collection('participant').doc(user.uid).set({
            'fullName': _fullNameController.text,
            'nickname': _nicknameController.text,
            'icNumber': _icNumberController.text,
            'homeAddress': _homeAddressController.text,
            'email': _emailController.text,
            'phoneNumber': _phoneNumberController.text,
            'emergencyNumber': _emergencyNumberController.text,
          }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update profile.')));
        }
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log out: $e')));
    }
  }

  // This method shows the popup with three password fields
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    // You can define these controllers inside the dialog method
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current Password
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // New Password
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Confirm New Password
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: () async {
                // Attempt to change the password
                await _changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                  confirmPasswordController.text,
                );
                // If desired, automatically close the dialog after success
                // (the _changePassword method can handle errors).
                Navigator.of(context).pop();
              },
              child: const Text('Update Password'),
            ),
          ],
        );
      },
    );
  }

  // Change password logic
  Future<void> _changePassword(
    String currentPassword, 
    String newPassword, 
    String confirmPassword,
  ) async {
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all password fields.")),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New passwords do not match.")),
      );
      return;
    }

    User? user = _auth.currentUser;
    if (user != null && user.email != null) {
      try {
        // Re-authenticate
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);

        // Update password
        await user.updatePassword(newPassword);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password successfully updated.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to change password: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid user data. Please log in again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.lightGreen,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/hutan.jpg',
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 60,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                      ? NetworkImage(_profileImageUrl!)
                                      : (_profileImage != null
                                          ? FileImage(_profileImage!)
                                          : const AssetImage('assets/default_profile.png')) as ImageProvider,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Text(
                        _nickname ?? 'Your Name',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                ),
              ],
            ),
          ];
        },
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildSectionTitle('Basic Information'),
                      _buildProfileCard([
                        _buildTextFormField('Full Name', _fullNameController, icon: Icons.person),
                        _buildTextFormField('Nickname', _nicknameController, icon: Icons.face),
                        _buildTextFormField('Email Address', _emailController, readOnly: true, icon: Icons.email),
                      ]),
                      
                      const SizedBox(height: 20),
                      _buildSectionTitle('Personal Details'),
                      _buildProfileCard([
                        _buildTextFormField('IC Number', _icNumberController, icon: Icons.credit_card),
                        _buildTextFormField('Home Address', _homeAddressController, icon: Icons.home),
                      ]),
                      
                      const SizedBox(height: 20),
                      _buildSectionTitle('Contact Information'),
                      _buildProfileCard([
                        _buildTextFormField('Phone Number', _phoneNumberController, icon: Icons.phone),
                        _buildTextFormField('Emergency Contact', _emergencyNumberController, icon: Icons.emergency),
                      ]),
                      
                      const SizedBox(height: 30),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildProfileCard(List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children.map((child) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: child,
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildTextFormField(String label, TextEditingController controller, {
    bool readOnly = false,
    bool obscure = false,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        return null;
      },
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          'Save Profile',
          Icons.save,
          Colors.green,
          _saveProfile,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'View Receipts',
          Icons.receipt,
          Colors.orange,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiptsPage())),
        ),
        if (_canChangePassword) ...[
          const SizedBox(height: 12),
          _buildActionButton(
            'Change Password',
            Icons.lock_outline,
            Colors.blue,
            () => _showChangePasswordDialog(context),
          ),
        ],
        const SizedBox(height: 12),
        _buildActionButton(
          'Privacy Policy',
          Icons.privacy_tip,
          Colors.grey,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage())),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
