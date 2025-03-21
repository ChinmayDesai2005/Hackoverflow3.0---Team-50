import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/widgets/header.dart';
import 'package:mobile/widgets/footer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, String> userDetails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userDetails = {
        'name': prefs.getString('userName') ?? 'Not found',
        'email': prefs.getString('userEmail') ?? 'Not found',
        'phoneNumber': prefs.getString('userPhoneNumber') ?? 'Not found',
        'gender': prefs.getString('userGender') ?? 'Not found',
        'state': prefs.getString('userState') ?? 'Not found',
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
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Column(
          children: [
            const Header(), // Add the Header widget here
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Profile Header
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
                                    backgroundImage: AssetImage('assets/images/Avatar.png'),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userDetails['name'] ?? 'User',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          userDetails['email'] ?? 'No email',
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

                            // Profile Details
                            _buildProfileDetailCard(
                              icon: Icons.phone,
                              title: 'Phone Number',
                              value: userDetails['phoneNumber'] ?? 'Not provided',
                              iconColor: Colors.green,
                            ),
                            _buildProfileDetailCard(
                              icon: Icons.person_outline,
                              title: 'Gender',
                              value: userDetails['gender'] ?? 'Not specified',
                              iconColor: Colors.purple,
                            ),
                            _buildProfileDetailCard(
                              icon: Icons.location_on,
                              title: 'State',
                              value: userDetails['state'] ?? 'Not specified',
                              iconColor: Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Footer(
        currentIndex: 3, // Set the correct index for the Profile screen
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }
}
