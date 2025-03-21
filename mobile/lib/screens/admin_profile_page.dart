import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  Map<String, String> adminDetails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      adminDetails = {
        'mobileNumber': prefs.getString('adminMobileNumber') ?? 'Not found',
        'userId': prefs.getString('adminUserId') ?? 'Not found',
        'type': prefs.getString('adminType') ?? 'Not found',
      };
      _isLoading = false;
    });
  }

  Widget _buildProfileDetailCard({
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? Colors.blue,
          size: 30,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
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
                  Navigator.pop(context);
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
                onTap: () => _showSidebar(context),
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
              leading: const Icon(Icons.home, color: Color.fromARGB(255, 5, 41, 70)),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin_home_screen');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Admin Header with Avatar
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 40,
                                    backgroundImage:
                                        AssetImage('assets/images/Avatar.png'), // Avatar image from assets
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Admin',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          adminDetails['type'] ?? 'Admin',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Admin Details (Phone Number, User ID, and User Type)
                            _buildProfileDetailCard(
                              icon: Icons.phone,
                              title: 'Mobile Number',
                              value: adminDetails['mobileNumber'] ?? 'Not provided',
                              iconColor: Colors.green,
                            ),
                            _buildProfileDetailCard(
                              icon: Icons.perm_identity,
                              title: 'User ID',
                              value: adminDetails['userId'] ?? 'Not provided',
                              iconColor: Colors.blue,
                            ),
                            _buildProfileDetailCard(
                              icon: Icons.admin_panel_settings,
                              title: 'User Type',
                              value: adminDetails['type'] ?? 'Admin',
                              iconColor: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
