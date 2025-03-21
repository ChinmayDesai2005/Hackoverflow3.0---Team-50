import 'package:flutter/material.dart';
import 'package:mobile/widgets/header.dart';
import 'package:mobile/widgets/footer.dart';

class ManualsScreen extends StatefulWidget {
  const ManualsScreen({Key? key}) : super(key: key);

  @override
  _ManualsScreenState createState() => _ManualsScreenState();
}

class _ManualsScreenState extends State<ManualsScreen> {
  int _currentIndex = 3; // Index for Manuals in Footer

  void _navigateTo(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home_screen');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/donation_screen');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/raiseIssue_screen');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/manuals_screen');
        break;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Header(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manuals',
                      style: TextStyle(
                        fontSize: 28, // Increased font size
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B3674), // Updated color to #2B3674
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    ManualButton(
                      title: 'CPR Manual',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CPRManualPage(),
                          ),
                        );
                      },
                    ),
                    ManualButton(
                      title: 'Earthquake Manual',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EarthquakeManualPage(),
                          ),
                        );
                      },
                    ),
                    ManualButton(
                      title: 'Fire Extinguisher Manual',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FireExtinguisherManualPage(),
                          ),
                        );
                      },
                    ),
                    ManualButton(
                      title: 'Flood Manual',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FloodManualPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Footer(
        currentIndex: _currentIndex,
        onTap: _navigateTo,
      ),
    );
  }
}

class ManualButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const ManualButton({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: const Color(0xFF2B3674), // Text color set to #2B3674
          backgroundColor: Colors.white, // Button background color set to white
          elevation: 10, // Darker shadow with more depth
          padding: const EdgeInsets.symmetric(vertical: 16.0), // Vertical padding for button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0), // Border radius set to 25
          ),
          shadowColor: Colors.black.withOpacity(0.3), // Darker shadow color
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0), // Add padding to the left of the text
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20.0, // Increased font size
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B3674), // Text color set to #2B3674
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 20.0, color: Color(0xFF2B3674)), // Icon color set to #2B3674
          ],
        ),
      ),
    );
  }
}


class FireExtinguisherManualPage extends StatelessWidget {
  const FireExtinguisherManualPage({Key? key}) : super(key: key);

  final List<String> manualImages = const [
    'assets/images/extinguisher_1.png',
    'assets/images/extinguisher_2.png',
    'assets/images/extinguisher_3.png',
    'assets/images/extinguisher_4.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Header(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  itemCount: manualImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10.0,
                    crossAxisSpacing: 10.0,
                  ),
                  itemBuilder: (context, index) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          manualImages[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Go back to the previous screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                child: const Text(
                  'Look at Other Manuals',
                  style: TextStyle(
                    color: Color(0xFF2B3674),
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // Increased text size
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Footer(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) {
            Navigator.pushReplacementNamed(
              context,
              ['/home_screen', '/donation_screen', '/raiseIssue_screen'][index],
            );
          }
        },
      ),
    );
  }
}

class EarthquakeManualPage extends StatelessWidget {
  const EarthquakeManualPage({Key? key}) : super(key: key);

  final List<String> manualImages = const [
    'assets/images/image 2.png',
    'assets/images/image 4.png',
    'assets/images/image 5.png',
    'assets/images/image 6.png',
    'assets/images/image 7.png',
    'assets/images/image 8.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Header(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  itemCount: manualImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10.0,
                    crossAxisSpacing: 10.0,
                  ),
                  itemBuilder: (context, index) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          manualImages[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                child: const Text(
                  'Look at Other Manuals',
                  style: TextStyle(
                    color: Color(0xFF2B3674),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Footer(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) {
            Navigator.pushReplacementNamed(
              context,
              ['/home_screen', '/donation_screen', '/raiseIssue_screen'][index],
            );
          }
        },
      ),
    );
  }
}

class FloodManualPage extends StatelessWidget {
  const FloodManualPage({Key? key}) : super(key: key);

  final List<String> manualImages = const [
    'assets/images/flood_1.png',
    'assets/images/flood_2.png',
    'assets/images/flood_3.png',
    'assets/images/flood_4.png',
    'assets/images/flood_5.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Header(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  itemCount: manualImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10.0,
                    crossAxisSpacing: 10.0,
                  ),
                  itemBuilder: (context, index) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          manualImages[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                child: const Text(
                  'Look at Other Manuals',
                  style: TextStyle(
                    color: Color(0xFF2B3674),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Footer(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) {
            Navigator.pushReplacementNamed(
              context,
              ['/home_screen', '/donation_screen', '/raiseIssue_screen'][index],
            );
          }
        },
      ),
    );
  }
}

class CPRManualPage extends StatelessWidget {
  const CPRManualPage({Key? key}) : super(key: key);

  final List<String> manualImages = const [
    'assets/images/cpr_1.png',
    'assets/images/cpr_2.png',
    'assets/images/cpr_3.png',
    'assets/images/cpr_4.png',
    'assets/images/cpr_5.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Header(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  itemCount: manualImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10.0,
                    crossAxisSpacing: 10.0,
                  ),
                  itemBuilder: (context, index) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          manualImages[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                child: const Text(
                  'Look at Other Manuals',
                  style: TextStyle(
                    color: Color(0xFF2B3674),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Footer(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) {
            Navigator.pushReplacementNamed(
              context,
              ['/home_screen', '/donation_screen', '/raiseIssue_screen'][index],
            );
          }
        },
      ),
    );
  }
}
