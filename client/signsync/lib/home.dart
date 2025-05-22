import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sl_translator.dart';
import 'faqs.dart';
import 'profile.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  final String? userName;

  const HomePage({super.key, this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<CameraDescription> cameras;
  bool isCameraInitialized = false;
  int _selectedIndex = 0;
  late String _displayUserName;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _displayUserName = widget.userName ?? 'Guest';
    _initializeCameras();
    _loadUserName();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeCameras() async {
    try {
      cameras = await availableCameras();
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
      }
    } catch (e) {
      print("Error initializing cameras: $e");
    }
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserName = prefs.getString('userName');
    if (mounted && storedUserName != null) {
      // Split the full name and get just the first name
      final firstName = storedUserName.split(' ')[0];
      setState(() {
        _displayUserName = firstName;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userName');
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: -10,
              width: MediaQuery.of(context).size.width * 0.47,
              height: MediaQuery.of(context).size.height * 0.65,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.5, -0.5),
                    radius: 0.8,
                    colors: [
                      Color.fromARGB(255, 225, 200, 251),
                      Color.fromARGB(255, 254, 223, 233),
                      Colors.white,
                    ],
                    stops: [0.0, 0.4, 0.8],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 8.0,
                    ),
                    child: _buildAppBar(),
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            Text(
                              'Hello $_displayUserName',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                                    Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(height: 230, child: _buildFeatureCards()),
                            const SizedBox(height: 30),
                            _buildFAQSection(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1, thickness: 0.5),
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
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/signsync_logo.png', height: 35),
          GestureDetector(
            onTap: () {
              showMenu(
                context: context,
                position: const RelativeRect.fromLTRB(100, 50, 0, 0),
                items: [
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: Text('Settings'),
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
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (cameras != null && cameras.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            SignLanguageTranslatorPage(cameras: cameras),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No cameras available")),
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8E1FF),
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
                    'Point your camera to translate signs to text.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Chat feature coming soon")),
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
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Let conversations \nflow freely',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
        color: const Color(0xFFE1F1FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FAQ\'s',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 17),
          _buildFAQItem(
            'How do I use the camera translator?',
            Icons.camera_alt,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FAQPage(
                        cameras: cameras,
                        question: 'How do I use the camera translator?',
                      ),
                ),
              );
            },
          ),
          const Divider(height: 17),
          _buildFAQItem(
            'Is my data private and secure?',
            Icons.chat_bubble_outline,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FAQPage(
                        cameras: cameras,
                        question: 'Is my data private and secure?',
                      ),
                ),
              );
            },
          ),
          const Divider(height: 17),
          _buildFAQItem(
            'How do I contact support?',
            Icons.front_hand_outlined,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FAQPage(
                        cameras: cameras,
                        question: 'How do I contact support?',
                      ),
                ),
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
          Text(title, style: const TextStyle(fontSize: 14.5)),
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
      padding: const EdgeInsets.symmetric(vertical: 16),
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
      onTap: () async {
        setState(() {
          _selectedIndex = index;
        });

        switch (index) {
          case 0:
            break;
          case 1:
            if (cameras != null && cameras.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SignLanguageTranslatorPage(cameras: cameras),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No cameras available")),
              );
            }
            break;
          case 2:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chat feature coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
            break;
          case 3:
            try {
              List<CameraDescription> camerasList = await availableCameras();
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(cameras: camerasList),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to access camera'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SignSync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

void main() {
  runApp(const MyApp());
}
