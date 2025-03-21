import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile/services/api_service.dart'; // Adjust the path as needed
import 'dart:async';

class AdminShareLocationScreen extends StatefulWidget {
  const AdminShareLocationScreen({Key? key}) : super(key: key);

  @override
  State<AdminShareLocationScreen> createState() =>
      _AdminShareLocationScreenState();
}

class _AdminShareLocationScreenState extends State<AdminShareLocationScreen> {
  bool isSharing = false;
  Position? currentPosition;
  Position? lastSentPosition;
  String statusMessage = "Press the button to share your live location.";
  Timer? periodicTimer;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  /// Check and request location permissions
  Future<void> _checkPermissions() async {
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
    if (await Permission.location.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  /// Get the current location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          "Location permissions are permanently denied. Enable them in settings.");
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  /// Start sharing location
  Future<void> _startSharingLocation() async {
    setState(() {
      isSharing = true;
      statusMessage = "Sharing your live location...";
    });

    try {
      await ApiService.initWebSocket(); // Ensure WebSocket is connected

      // Continuously listen for location updates
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Minimum distance to trigger an update
        ),
      ).listen((Position position) async {
        setState(() {
          currentPosition = position;
        });

        // Check if the user has moved more than 10 meters
        if (_hasMovedMoreThan10Meters(lastSentPosition, position)) {
          await _sendLiveLocation(position);
        }
      });

      // Set up a periodic timer for fallback updates
      periodicTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        if (currentPosition != null) {
          await _sendLiveLocation(currentPosition!);
        }
      });
    } catch (error) {
      setState(() {
        isSharing = false;
        statusMessage = "Error: $error";
      });
    }
  }

  /// Stop sharing location
  void _stopSharingLocation() {
    ApiService.closeWebSocket(); // Close WebSocket connection
    periodicTimer?.cancel(); // Stop the periodic timer
    setState(() {
      isSharing = false;
      statusMessage = "Location sharing stopped.";
    });
  }

  /// Send live location
  Future<void> _sendLiveLocation(Position position) async {
    try {
      await ApiService.sendLiveLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() {
        lastSentPosition = position;
      });
      print("Location sent: ${position.latitude}, ${position.longitude}");
    } catch (error) {
      print("Error sending location: $error");
    }
  }

  /// Check if the user has moved more than 10 meters
  bool _hasMovedMoreThan10Meters(Position? lastPosition, Position newPosition) {
    if (lastPosition == null) return true;
    double distanceInMeters = Geolocator.distanceBetween(
      lastPosition.latitude,
      lastPosition.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    return distanceInMeters > 10;
  }

  @override
  void dispose() {
    ApiService.closeWebSocket();
    periodicTimer?.cancel();
    super.dispose();
  }

  /// Header Widget
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0),
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

  /// Sidebar
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

  Future<void> _logoutAdmin(BuildContext context) async {
    print("Admin logged out"); // Add your logout logic here
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
    body: Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9, // Reduce container width
              height: MediaQuery.of(context).size.height * 0.4, // Adjust container height
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3), // Increase shadow opacity
                    spreadRadius: 3, // Increase spread radius
                    blurRadius: 10, // Increase blur radius
                    offset: const Offset(0, 5), // Increase shadow offset
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold, // Make text bold
                        color: Color(0xFF2B3674),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (currentPosition != null)
                      Text(
                        "Current Location: \nLatitude: ${currentPosition!.latitude}, Longitude: ${currentPosition!.longitude}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold, // Make text bold
                          color: Color(0xFF2B3674),
                        ),
                      ),
                    const SizedBox(height: 40),
                    _styledButton(
                      isSharing ? "Stop Sharing" : "Start Sharing",
                      isSharing,
                      isSharing ? _stopSharingLocation : _startSharingLocation,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


}