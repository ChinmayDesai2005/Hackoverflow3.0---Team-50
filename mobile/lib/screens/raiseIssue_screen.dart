import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/services/api_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile/widgets/header.dart';
import 'package:mobile/widgets/footer.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RaiseIssueScreen extends StatefulWidget {
  const RaiseIssueScreen({super.key});

  @override
  State<RaiseIssueScreen> createState() => _RaiseIssueScreenState();
}

class PageTitle extends StatelessWidget {
    const PageTitle({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: 'Raise an ',
                style: const TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B3674),
                ),
                children: [
                  TextSpan(
                    text: 'Issue',
                    style: const TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFC7753),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 3,
              color: const Color(0xFFFC7753),
              width: 230,
            ),
          ],
        ),
      );
    }
  }


Widget _styledButtonWithBorder({
  required String text,
  required IconData icon,
  VoidCallback? onPressed,  // Make it nullable
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,  // ElevatedButton accepts nullable callback
    icon: Icon(icon, color: const Color(0xFF2B3674)),
    label: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF2B3674),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      side: const BorderSide(color: Color(0xFF2B3674), width: 1),
      elevation: 3,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ),
  );
}



class _RaiseIssueScreenState extends State<RaiseIssueScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  String? _title;
  String? _description;
  String? _selectedCategory;
  Position? _currentPosition;
  bool _isSubmitting = false;
  String? _userId;

  final List<String> _categories = [
    "Natural Disaster",
    "Medical",
    "Fire",
    "Infrastructure",
    "Other"
  ];

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
  }


  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      // Keep existing camera permission logic
      final permission = await Permission.camera.request();
      
      if (!permission.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to take a photo.'),
          ),
        );
        return;
      }
    }

    // Use ImagePicker directly without storage permission check for gallery
    final pickedFile = await _imagePicker.pickImage(source: source);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No image selected.'),
        ),
      );
    }
  }

  Future<void> _locateUser() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location services")),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission is denied")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Location permission is permanently denied")),
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Location fetched: ${position.latitude}, ${position.longitude}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch location: $e")),
      );
    }
  }

  Future<void> _submitIssue() async {
  // Validate all required fields
  if (_selectedImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select an image")),
    );
    return;
  }

  if (_title == null || _title!.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter a title")),
    );
    return;
  }

  if (_description == null || _description!.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter a description")),
    );
    return;
  }

  if (_selectedCategory == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select a category")),
    );
    return;
  }

  if (_currentPosition == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please get your current location")),
    );
    return;
  }

  setState(() {
    _isSubmitting = true;
  });

  try {
    // Read and compress the image
    final originalBytes = await _selectedImage!.readAsBytes();
    final compressedBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      quality: 70,
    );

    // Encode the compressed image to Base64
    final String photoBase64 = base64Encode(compressedBytes);
    final String location =
        "${_currentPosition!.latitude},${_currentPosition!.longitude}";

    // Make API call
    final response = await ApiService.addIssue(
      photoBase64: photoBase64,
      title: _title!,
      description: _description!,
      emergencyType: _selectedCategory!,
      location: location,
      userId: _userId!, // This is no longer needed in the method
    );

    // Check if response is not null and has a message
    if (response != null) {
      String message = 'Issue submitted successfully';
      
      // Try to get message from response, fallback to default
      if (response is Map && response.containsKey('message')) {
        message = response['message'] ?? message;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _resetForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Received null response from server'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    // More detailed error handling
    print('Submission error: $e'); // Log the full error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to submit issue: ${e.toString()}"),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() {
      _isSubmitting = false;
    });
  }
}

void _resetForm() {
  setState(() {
    _selectedImage = null;
    _title = null;
    _description = null;
    _selectedCategory = null;
    _currentPosition = null;
  });
  
  // Navigate back to the first page
  _navigateToPage(0);
}

  void _navigateToPage(int pageIndex) {
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _styledButton(String text, bool isPrimary, VoidCallback? onPressed) {
    return GestureDetector(
      onTap: onPressed != null && !_isSubmitting ? onPressed : null,  // Only call if not null and not submitting
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
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Page 1: Upload Image
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Header(),
                  const SizedBox(height: 20),
                  const PageTitle(),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Step 1: Upload Image',
                      style: TextStyle(
                        fontSize: 24,
                        color: Color(0xFF2B3674),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _styledButtonWithBorder(
                                text: "Camera",
                                icon: Icons.camera,
                                onPressed: () => _pickImage(ImageSource.camera),
                              ),
                              _styledButtonWithBorder(
                                text: "Gallery",
                                icon: Icons.photo_library,
                                onPressed: () => _pickImage(ImageSource.gallery),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue, width: 2),
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Center(
                                    child: Text(
                                      'No image selected',
                                      style: TextStyle(fontSize: 16, color: Colors.blue),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: _styledButton("Next", true, () => _navigateToPage(1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page 2: Title, Description, and Category
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Header(),
                  const SizedBox(height: 20),
                  const PageTitle(),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Step 2: Details',
                      style: TextStyle(
                        fontSize: 24,
                        color: Color(0xFF2B3674),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                                labelText: 'Title', border: OutlineInputBorder()),
                            onChanged: (value) => _title = value,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            decoration: const InputDecoration(
                                labelText: 'Description', border: OutlineInputBorder()),
                            onChanged: (value) => _description = value,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                                labelText: "Category", border: OutlineInputBorder()),
                            value: _selectedCategory,
                            items: _categories
                                .map((category) => DropdownMenuItem(
                                    value: category, child: Text(category)))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            hint: const Text("Select a Category"),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: _styledButton("Previous", false, () => _navigateToPage(0)),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: _styledButton("Next", true, () => _navigateToPage(2)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

           SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Header(),
            const SizedBox(height: 20),
            const PageTitle(),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Step 3: Location & Submit',
                style: TextStyle(
                  fontSize: 24,
                  color: Color(0xFF2B3674),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _styledButtonWithBorder(
                      text: "Get Current Location",
                      icon: Icons.location_on,
                      onPressed: _locateUser,
                    ),
                    const SizedBox(height: 20),
                    if (_currentPosition != null)
                      Text(
                        "Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2B3674), // Styled location text
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _styledButton("Previous", false, () => _navigateToPage(1)),
                        _styledButton(
                          "Submit",
                          true,
                          _isSubmitting ? null : _submitIssue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

          ],
        ),
      ),
      bottomNavigationBar: Footer(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}