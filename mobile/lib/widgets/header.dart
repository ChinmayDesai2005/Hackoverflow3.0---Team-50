import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/issuesRaised_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Header extends StatelessWidget {
  const Header({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/auth_screen',
      (route) => false,
    );
  }

  Future<void> _navigateToIssuesRaised(BuildContext context) async {
    // Use a ScaffoldState to show SnackBar more reliably
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final issues = await ApiService.fetchPersonalIssues();
      print(issues);
      
      // Check if the context is still valid before navigating
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IssuesRaisedScreen(),
          ),
        );
      }
    } catch (error) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error fetching issues: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _openUserSidebar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              _buildSidebarOption(
                context,
                icon: Icons.person,
                text: 'Profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile_screen');
                },
              ),
              const SizedBox(height: 15),
              _buildSidebarOption(
                context,
                icon: Icons.report_problem,
                text: 'Issues Raised by You',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/issues_raised_screen');
                },
              ),
              const SizedBox(height: 15),
              _buildSidebarOption(
                context,
                icon: Icons.logout,
                text: 'Logout',
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
                isLogout: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarOption(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        decoration: BoxDecoration(
          color: isLogout ? Colors.red.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: isLogout ? Colors.red : Colors.black87),
            const SizedBox(width: 15),
            Text(
              text,
              style: TextStyle(
                color: isLogout ? Colors.red : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
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
                    '/home_screen',
                    (route) => false,
                  );
                },
              ),
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/images/Layer1.png',
                    height: 40,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _openUserSidebar(context),
                child: CircleAvatar(
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