import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'home.dart';
import 'sl_translator.dart';
import 'faqs.dart';

class ProfilePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const ProfilePage({super.key, required this.cameras});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 3;
  late List<CameraDescription> cameras;
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  Map<String, dynamic> userData = {
    'name': 'Loading...',
    'email': 'Loading...',
    'isPro': false,
  };

  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    cameras = widget.cameras;
    _initializeCamera();
    _fetchUserData();
  }

  Future<void> _initializeCamera() async {
    try {
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras.first,
          ResolutionPreset.medium,
        );
        _initializeControllerFuture = _controller!.initialize();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Get the token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        // User is not logged in, set message
        if (mounted) {
          setState(() {
            userData = {
              'name': 'Please log in to view profile details',
              'email': 'Please log in to view profile details',
              'isPro': false,
            };
            isLoading = false;
          });
        }
        return;
      }

      // Decode the token to get user_id
      final decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['user_id'];

      // Make authenticated request to /api/profile
      final response = await http.get(
        Uri.parse('http://192.168.1.3:5000/api/profile?user_id=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        if (mounted) {
          setState(() {
            userData = data['data'];
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load profile';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Connection error: ${e.toString()}';
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFC0CB), Color(0xFFE6E6FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _buildBodyContent(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBodyContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6E6FA), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildInfoSection(),
          const SizedBox(height: 24.0),
          _buildProSection(),
          const SizedBox(height: 24.0),
          _buildAboutSection(),
          const SizedBox(height: 60.0),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INFO',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10.0),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildInfoRow(
                Icons.person_outline,
                'Name',
                userData['name'] ?? 'Not available',
              ),
              const Divider(height: 1),
              _buildInfoRow(
                Icons.email_outlined,
                'E-mail',
                userData['email'] ?? 'Not set',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 22.0),
          const SizedBox(width: 12.0),
          SizedBox(
            width: 60.0,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16.0, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.normal,
                color: Colors.black54,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRO',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10.0),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/signsync_logo.png',
                height: 24.0,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Try unlimited features with SignSync+',
                style: TextStyle(fontSize: 18.0, color: Colors.black54),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Upgrade feature coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22.0),
                  ),
                ),
                child: const Text(
                  'Upgrade',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ABOUT',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10.0),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            children: [
              _buildAboutItem(Icons.bug_report_outlined, 'Report a problem'),
              const SizedBox(height: 8.0),
              const Divider(height: 1),
              const SizedBox(height: 8.0),
              _buildAboutItem(Icons.description_outlined, 'Terms of Use'),
              const SizedBox(height: 8.0),
              const Divider(height: 1),
              const SizedBox(height: 8.0),
              _buildAboutItem(Icons.shield_outlined, 'Privacy Policy'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutItem(IconData icon, String text) {
    return InkWell(
      onTap: () {
        if (text == 'Report a problem') {
          _showReportDialog();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54, size: 22.0),
            const SizedBox(width: 12.0),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Problem'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Describe the issue you\'re facing',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report submitted successfully'),
                ),
              );
            },
            child: const Text('Submit'),
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
      onTap: () => _handleNavigation(index),
      child: Icon(
        icon,
        color: _selectedIndex == index ? Colors.blue : Colors.grey,
        size: 26,
      ),
    );
  }

  void _handleNavigation(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignLanguageTranslatorPage(cameras: cameras),
          ),
        );
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
        break;
    }
  }
}