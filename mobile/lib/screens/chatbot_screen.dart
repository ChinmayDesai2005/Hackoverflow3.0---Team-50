import 'package:flutter/material.dart';
import 'package:mobile/widgets/header.dart';
import 'package:mobile/widgets/footer.dart';

class ChatbotPage extends StatefulWidget {
  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  int _currentIndex = 0; // To manage the bottom navigation bar state

  /// Handles navigation logic when an item is tapped in the footer
  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Add logic to navigate to specific screens based on the index
    // Example:
    if (index == 0) {
      Navigator.pop(context); // Return to the previous screen
    } else if (index == 1) {
      // Navigate to another screen if needed
      // Navigator.push(context, MaterialPageRoute(builder: (_) => AnotherScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Custom Header widget
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100.0), // Height of your header
        child: Header(), // Custom header widget
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Bot's initial message
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/Bot_Image.png'),
                  radius: 20, // Reduced size
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "I am here to help you, Ask me anything.",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // User's message
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "I am heavily bleeding from my leg, what should I do?",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/Avatar.png'),
                  radius: 20, // Reduced size
                ),
              ],
            ),
            SizedBox(height: 16),
            // Bot's response
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/Bot_Image.png'),
                  radius: 20, // Reduced size
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "I'm here to help. If you're heavily bleeding from your leg, follow these steps immediately to stop the bleeding:",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 12),
                        Text("1. Apply direct pressure: Use a clean cloth, towel, or gauze to press firmly on the wound. Keep the pressure constant to slow the bleeding."),
                        SizedBox(height: 8),
                        Text("2. Elevate the leg: If possible, raise your leg above the level of your heart. This can reduce blood flow to the injured area."),
                        SizedBox(height: 8),
                        Text("3. Use a tourniquet as a last resort: If the bleeding is life-threatening and won't stop with pressure, you can try using a belt or strip of cloth to create a tourniquet. Place it above the wound, not on the joint, and tighten it until the bleeding slows."),
                        SizedBox(height: 8),
                        Text("4. Keep calm and stay still: Try to stay as calm as possible and avoid moving around to prevent further injury."),
                        SizedBox(height: 8),
                        Text("5. Call emergency services (911 or your local emergency number): Get professional medical help as soon as possible. Even if you manage to stop the bleeding, you still need medical attention."),
                        SizedBox(height: 12),
                        Text(
                          "Stay strong!",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 100), // Space for footer
          ],
        ),
      ),
      bottomNavigationBar: Footer(
        currentIndex: _currentIndex, // Active index for footer
        onTap: _navigateTo, // Handle footer navigation
      ),
    );
  }
}
