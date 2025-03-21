import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/services/api_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';


class AdminReportIssueScreen extends StatefulWidget {
  const AdminReportIssueScreen({Key? key}) : super(key: key);

  @override
  _AdminReportIssueScreenState createState() => _AdminReportIssueScreenState();
}

class _AdminReportIssueScreenState extends State<AdminReportIssueScreen> {
  File? _imageFile;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedEmergencyType = 'Fire'; // Default value for the dropdown
  bool _isSubmitting = false;

  final List<String> _emergencyTypes = [
    'Fire',
    'Flood',
    'Accident',
    'Earthquake',
    'Other'
  ];

 Future<void> _pickImage(ImageSource source) async {
  if (source == ImageSource.camera) {
    // Request camera permission only when the source is camera
    final permission = await Permission.camera.request();

    if (!permission.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required to take a photo.')),
      );
      return;
    }
  }

  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source);

  if (pickedFile != null) {
    setState(() {
      _imageFile = File(pickedFile.path);
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No image selected.')),
    );
  }
}


  Future<void> _submitReport() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required!')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String base64Image = base64Encode(_imageFile!.readAsBytesSync());

      final response = await ApiService.addAdminReportIssue(
        photoBase64: base64Image,
        title: _titleController.text,
        description: _descriptionController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue reported successfully!')),
      );

      // Clear form after successful submission
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      setState(() {
        _imageFile = null;
        _selectedEmergencyType = _emergencyTypes[0];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report issue: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _logoutAdmin(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear admin-specific data
      await prefs.remove('adminMobileNumber');
      await prefs.remove('adminFcmToken');
      await prefs.remove('adminUserId');
      await prefs.remove('adminJwtToken');
      await prefs.remove('adminType');
      await prefs.setBool('isAdminLoggedIn', false);

      // Navigate to the authentication screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/auth_screen',
        (route) => false,
      );
    } catch (e) {
      // Handle errors gracefully and show a snackbar
      print('Error during admin logout: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('logout_failed'.tr(args: [e.toString()]))),
      );
    }
  }

    void _showSidebar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin_profile_screen');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Do you really want to logout?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _logoutAdmin(context); // Perform the logout
              },
            ),
          ],
        );
      },
    );
  }

   Widget _styledButton(String text, bool isPrimary, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.4,
          minWidth: 120,
        ),
        height: 45,
        decoration: ShapeDecoration(
          color: isPrimary ? const Color(0xFF2B3674) : Colors.transparent,
          shape: RoundedRectangleBorder(
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(width: 1, color: Color(0xFF2B3674)),
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isPrimary ? Colors.white : const Color(0xFF2B3674),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report an Issue',
                    style: const TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B3674),
                    ),
                  ),
                  const SizedBox(height: 0.5), // Adjust spacing between text and underline
                  Container(
                    width: 250, // Match the width of the text or adjust as needed
                    height: 3,
                    color: const Color(0xFFFC7753),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey, width: 1),
                        ),
                        child: _imageFile == null
                            ? const Center(
                                child: Text(
                                  'No image selected',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _styledButton(
                            'Pick from Gallery',
                            false,
                            () => _pickImage(ImageSource.gallery),
                          ),
                          _styledButton(
                            'Use Camera',
                            true,
                            () => _pickImage(ImageSource.camera),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(10),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: _styledButton(
                          _isSubmitting ? 'Submitting...' : 'Report Issue',
                          true,
                          (_isSubmitting ? null : _submitReport) as VoidCallback,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

    Widget _buildHeader(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(top: 20.0), // Padding of 20 added to the header
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/admin_home_screen',
                      (route) => false,
                    );
                  },
                ),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/Header_Logo.png',
                      height: 40,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    print("Avatar tapped");
                    _showSidebar(context);
                  },
                  child: const CircleAvatar(
                    backgroundImage: AssetImage('assets/images/Avatar.png'),
                    radius: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }


  