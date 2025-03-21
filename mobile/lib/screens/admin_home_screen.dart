import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mobile/screens/admin_shareLocation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/screens/admin_reportIssue_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 20), // Added padding from the top
          _buildHeader(context),
          const SizedBox(height: 20), // Space below the header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Image.asset(
                'assets/images/Auth_Logo.png',
                height: 150, // Adjust size as needed
              ),
            ),
          ),
          const SizedBox(height: 40), // Space below the image
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildButton(
                      context,
                      text: 'Report an Issue',
                      borderColor: const Color(0xFF2B3674),
                      onPressed: () {
                        // Navigate to AdminReportIssueScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AdminReportIssueScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildButton(
                      context,
                      text: 'Live Tracking',
                      borderColor: const Color(0xFFFC7753),
                      onPressed: () {
                        // Navigate to AdminShareLocationScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AdminShareLocationScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

  void _showSidebar(BuildContext context) {
    print("Sidebar triggered");
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)), // Increased radius for more rounded effect
      ),
      elevation: 10, // Elevation to make the bottom sheet look more elevated
      isScrollControlled: true, // Allow the sheet to have flexible height
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile ListTile
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF2B3674), size: 28),
                title: Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B3674), // Matching the color of the icon
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                onTap: () {
                  print("Profile tapped");
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin_profile_screen');
                },
              ),
              Divider(
                color: Colors.grey.withOpacity(0.5), // Subtle divider
                thickness: 1,
              ),
              // Logout ListTile
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red, size: 28),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                onTap: () {
                  print("Logout tapped");
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildButton(
    BuildContext context, {
    required String text,
    required Color borderColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7, // 70% of screen width
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // Button background color
          side: BorderSide(color: borderColor, width: 2), // Border color and thickness
          padding: const EdgeInsets.symmetric(vertical: 20), // Vertical padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), // Rounded corners
          ),
          elevation: 4, // Slight shadow for a lifted look
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: borderColor, // Text color matches border
          ),
        ),
      ),
    );
  }
}
