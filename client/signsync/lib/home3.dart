import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({
    super.key, 
    this.userName = 'Horris',
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            // Corrected gradient background for top right corner
  Positioned(
  top: -10,
  right: -10, // Kept the same for positioning
  width: MediaQuery.of(context).size.width * 0.47, // Increased from 0.25 to 0.35 (35% of screen width)
  height: MediaQuery.of(context).size.height * 0.65,
  child: Container(
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0.5, -0.5), // Center near the top-right
        radius: 0.8, // Kept the same for the spread
        colors: [
          Color.fromARGB(255, 225, 200, 251), // Light purple at the top
          Color.fromARGB(255, 254, 223, 233), // Light pink below
          Colors.white, // Fades to white
        ],
        stops: [0.0, 0.4, 0.8], // Purple at the start, quick transition to pink, then fade to white
      ),
    ),
  ),
),
            
            SafeArea(
              child: Column(
                children: [
                  // App Bar with proper sizing
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: _buildAppBar(),
                  ),
                  
                  // Line below the navbar
                  const Divider(height: 1, thickness: 0.5),
                  
                  // Main scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height - 180, // Ensure content fills screen properly
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              
                              // Welcome Text
                              Text(
                                'Hello ${widget.userName}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Subtitle - Modified to display on two lines
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Enjoy frictionless',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'communication - Made with ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Icon(Icons.favorite, color: Colors.red, size: 16),
                                    ],
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Feature Cards Row - with fixed height
                              SizedBox(
                                height: 230, // Fixed height to match design
                                child: _buildFeatureCards(),
                              ),
                              
                              const SizedBox(height: 30), // Increased spacing
                              
                              // FAQ Section - now properly positioned
                              _buildFAQSection(),
                              
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1, thickness: 0.5), // Thin line above navbar
                  _buildBottomNavigationBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SizedBox(
      height: 40, // Increased height for navbar
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo with SL Hand
          Image.asset(
            'assets/signsync_logo.png',
            height: 35,
          ),
          
          // Menu Button - Made clickable
          GestureDetector(
            onTap: () {
              // Handle menu tap
              showMenu(
                context: context,
                position: const RelativeRect.fromLTRB(100, 50, 0, 0),
                items: [
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: Text('Settings'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Text('Profile'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ],
              );
            },
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live Sign Translation Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Navigate to Live Sign Translation
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Placeholder()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8E1FF), // Light purple
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(Icons.camera_alt, size: 24),
                  ),
                  const Spacer(),
                  const Text(
                    'Live Sign\nTranslation',
                    style: TextStyle(
                      fontSize: 21.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Point your camera to translate signs to text or audio.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Right Column Cards
        Expanded(
          child: Column(
            children: [
              // Chat Card
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Navigate to Chat
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Placeholder()),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 248, 246, 246),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Chat',
                              style: TextStyle(
                                fontSize: 21.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Icon(Icons.chat_bubble_outline, size: 20),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Pass the phone or\nconnect locally',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // SL Handmoji Card - Now non-clickable and column format
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.grey.shade600),
                        ),
                        child: const Icon(
                          Icons.front_hand_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'SL Handmoji',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAQSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F1FF), // Light blue
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FAQ\'s',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 17),
          _buildFAQItem(
            'How do I use the camera translator?', 
            Icons.camera_alt,
            () {
              // Navigate to camera translator FAQ
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Placeholder()),
              );
            },
          ),
          const Divider(height: 17),
          _buildFAQItem(
            'How do I use SignSync Chat Feature?', 
            Icons.chat_bubble_outline,
            () {
              // Navigate to chat FAQ
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Placeholder()),
              );
            },
          ),
          const Divider(height: 17),
          _buildFAQItem(
            'What is the SL Handmoji?', 
            Icons.front_hand_outlined,
            () {
              // Navigate to Handmoji FAQ
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Placeholder()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16), // Increased padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 0),
          _buildNavItem(Icons.camera_alt, 1),
          _buildNavItem(Icons.chat_bubble_outline, 2),
          _buildNavItem(Icons.person, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        // Navigate to corresponding screen based on index
        switch (index) {
          case 0:
            // Already on home page
            break;
          case 1:
            // Navigate to camera page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Placeholder()),
            );
            break;
          case 2:
            // Navigate to chat page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Placeholder()),
            );
            break;
          case 3:
            // Navigate to profile page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Placeholder()),
            );
            break;
        }
      },
      child: Icon(
        icon,
        color: _selectedIndex == index ? Colors.blue : Colors.grey,
        size: 26,
      ),
    );
  }
}

// For the main app
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SignSync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(userName: 'James'),
    );
  }
}

void main() {
  runApp(const MyApp());
}