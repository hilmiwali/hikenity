//organiser_profile_page.dart
import 'package:flutter/material.dart';
import 'package:hikenity_app/pages/privacy_policy_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage for image upload
import 'dart:io'; // For handling file operations
import 'package:url_launcher/url_launcher.dart';

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
  String? _certificateUrl;
  String? _rejectionReason;
  bool _isApproved = false;
  File? _profileImage;
  File? _certificateFile;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  bool _canChangePassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkAuthProvider();
  }

  /// 1) Check the auth provider to see if we can show "Change Password"
  void _checkAuthProvider() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (var provider in user.providerData) {
      if (provider.providerId == 'password') {
        _canChangePassword = true;
        break;
      }
    }
  }

  Future<void> _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot snapshot =
            await _firestore.collection('organisers').doc(user.uid).get();
        if (snapshot.exists) {
          Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
          setState(() {
            _fullName = data?['fullName'] ?? '';
            _phoneNumber = data?['phoneNumber'] ?? '';
            _profileImageUrl = data?['profileImageUrl'] ?? '';
            _certificateUrl = data?['certificateUrl'] ?? '';
            _isApproved = data?['isApproved'] ?? false;
            _rejectionReason = data?['rejectionReason'];
            _fullNameController.text = _fullName ?? '';
            _phoneNumberController.text = _phoneNumber ?? '';
          });
        }
        setState(() {
          _email = user.email;
          _emailController.text = _email ?? '';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
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
          final storageRef =
              _storage.ref().child('profile_images/${user.uid}.jpg');
          UploadTask uploadTask = storageRef.putFile(_profileImage!);
          TaskSnapshot snapshot = await uploadTask;
          String downloadUrl = await snapshot.ref.getDownloadURL();
          await _firestore.collection('organisers').doc(user.uid).update({
            'profileImageUrl': downloadUrl,
          });
          setState(() {
            _profileImageUrl = downloadUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile image uploaded successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile image: $e')),
        );
      }
    }
  }

  Future<void> _pickCertificate() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Accept only PDF files
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _certificateFile = File(result.files.single.path!);
      });
      await _uploadCertificate();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to pick file: $e')),
    );
  }
}

  Future<void> _uploadCertificate() async {
    if (_certificateFile != null) {
      try {
        User? user = _auth.currentUser;
        if (user != null) {
          final storageRef =
              _storage.ref().child('organizer_certificates/${user.uid}.pdf');
          UploadTask uploadTask = storageRef.putFile(_certificateFile!);
          TaskSnapshot snapshot = await uploadTask;
          String downloadUrl = await snapshot.ref.getDownloadURL();
          await _firestore.collection('organisers').doc(user.uid).update({
            'certificateUrl': downloadUrl,
            'isApproved': false,
            'rejectionReason': null,
          });
          setState(() {
            _certificateUrl = downloadUrl;
            _isApproved = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Certificate uploaded successfully. Pending approval.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload certificate: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      User? user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore.collection('organisers').doc(user.uid).set({
            'fullName': _fullNameController.text,
            'email': _emailController.text,
            'phoneNumber': _phoneNumberController.text,
          }, SetOptions(merge: true));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile.')),
          );
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
        SnackBar(content: Text('Failed to log out: $e')),
      );
    }
  }

  /// 7) Show the "Change Password" fields in an AlertDialog (popup)
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    // We define these local controllers so they exist only in the dialog scope.
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Update'),
              onPressed: () async {
                // Attempt to change the password
                await _changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                  confirmPasswordController.text,
                );
                // Automatically close the dialog
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// 8) Actually change the password in Firebase
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
      appBar: AppBar(
        title: const Text(
          'Organiser Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade800,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _auth.currentUser != null
            ? _firestore
                .collection('organisers')
                .doc(_auth.currentUser!.uid)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load profile data.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          _fullName = data['fullName'] ?? '';
          _phoneNumber = data['phoneNumber'] ?? '';
          _profileImageUrl = data['profileImageUrl'] ?? '';
          _certificateUrl = data['certificateUrl'] ?? '';
          _isApproved = data['isApproved'] ?? false;
          _rejectionReason = data['rejectionReason'];

          _fullNameController.text = _fullName!;
          _phoneNumberController.text = _phoneNumber!;
          _email = _auth.currentUser?.email ?? '';

          return _buildProfileContent();
        },
      ),
    );
  }

Widget _buildProfileContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade800,
            Colors.green.shade50,
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 75,
                            backgroundColor: Colors.white,
                            backgroundImage: _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : (_profileImage != null
                                    ? FileImage(_profileImage!)
                                    : const AssetImage('assets/default_profile.png'))
                                    as ImageProvider,
                            child: _profileImageUrl == null && _profileImage == null
                                ? const Icon(Icons.camera_alt,
                                    size: 40, color: Colors.green)
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.edit,
                              size: 24, color: Colors.green.shade800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _fullName ?? 'Your Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Section
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isApproved == 'rejected' && _rejectionReason != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade400),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Approval Rejected: $_rejectionReason',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Profile Form Fields
                    _buildFormField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      icon: Icons.person,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter your full name' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _phoneNumberController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter your phone number' : null,
                    ),

                    const SizedBox(height: 24),

                    // Certificate Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.verified_user,
                                  color: Colors.green.shade700),
                              const SizedBox(width: 12),
                              const Text(
                                'Business Certification',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _pickCertificate,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Certificate (PDF)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          if (_certificateUrl != null) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                Uri certificateUri = Uri.parse(_certificateUrl!);
                                if (await canLaunchUrl(certificateUri)) {
                                  await launchUrl(certificateUri,
                                      mode: LaunchMode.externalApplication);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Could not open certificate')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.remove_red_eye),
                              label: const Text('View Certificate'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                color: _isApproved
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isApproved
                                        ? Icons.check_circle
                                        : Icons.pending,
                                    size: 20,
                                    color: _isApproved
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isApproved
                                        ? 'Certificate Approved'
                                        : 'Pending Approval',
                                    style: TextStyle(
                                      color: _isApproved
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'No certificate uploaded yet',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save Profile',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_canChangePassword)
                      OutlinedButton.icon(
                        onPressed: () => _showChangePasswordDialog(context),
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Change Password'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.blue.shade600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.privacy_tip),
                      label: const Text('Privacy Policy'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: Colors.green.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        readOnly: readOnly,
        validator: validator,
        keyboardType: keyboardType,
        cursorColor: Colors.green.shade600,
      ),
    );
  }
}