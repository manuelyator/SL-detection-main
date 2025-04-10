import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'sl_translator.dart';
import 'profile.dart';

class FAQPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String question;

  const FAQPage({super.key, required this.cameras, required this.question});

  @override
  _FAQPageState createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
            child: const Icon(
              Icons.arrow_back,
              size: 24,
              color: Colors.black,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "FAQ's",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Divider(
            color: Colors.grey,
            height: 1.5,
            thickness: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.question,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            _buildFAQSection(
              title: 'I. What is the live sign camera translator?',
              content:
              'The live sign camera translator is a mobile application that uses your device\'s camera to detect and translate sign language gestures in real-time, helping users communicate with those who use sign language. The app can provide immediate translations, enhancing accessibility for individuals with hearing impairments.',
              backgroundColor: Colors.pink[50]!,
            ),
            _buildFAQSection(
              title: 'II. How do I use the camera translator?',
              content:
              'To use the camera translator, tap the camera icon in the bottom navigation bar to activate the camera. Once activated, position the sign language gesture in front of the camera, and the app will translate it into text on the screen. Ensure good lighting for better recognition accuracy.',
              backgroundColor: const Color(0xFFD6E3F8),
            ),
            _buildFAQSection(
              title: 'III. Which sign languages are supported?',
              content:
              'Currently, our app supports Kenyan Sign Language (KSL). We are working on adding support for additional sign languages in future updates. Please stay tuned for more languages as we expand our app\'s capabilities.',
              backgroundColor: Colors.pink[50]!,
            ),
            _buildFAQSection(
              title: 'IV. How accurate is the translation?',
              content:
              "Our translation accuracy typically ranges from 95-99% depending on lighting conditions, the clarity of the sign and other environmental factors. We continuously improve the app’s recognition algorithms to provide the best user experience possible.",
              backgroundColor: const Color(0xFFD6E3F8),
            ),
            _buildFAQSection(
              title: 'V. Can I translate from text to sign language?',
              content:
              'Not really! Our app currently focuses on translating sign language to text. However, we are planning to add a feature for converting text to sign language in future updates to further enhance communication between users.',
              backgroundColor: Colors.pink[50]!,
            ),
            _buildFAQSection(
              title: 'VI. What devices are compatible with this app?',
              content:
              'Our app is compatible with most Android devices running version 8.0 or higher. Ensure your device has a camera and the necessary processing power to run the app effectively.',
              backgroundColor: const Color(0xFFD6E3F8),
            ),
            _buildFAQSection(
              title: 'VII. Is an internet connection required?',
              content:
              'Yes, an internet connection is required for the app to function properly. The app uses cloud-based processing for certain translations and requires a stable connection for optimal performance.',
              backgroundColor: Colors.pink[50]!,
            ),
            _buildFAQSection(
              title: 'VIII. What are the optimal lighting conditions?',
              content:
              'The app works best in evenly lit environments with minimal shadows. Ensure the area around you is well-lit, and avoid bright or direct light shining directly into the camera to enhance recognition accuracy.',
              backgroundColor: const Color(0xFFD6E3F8),
            ),
            _buildFAQSection(
              title: 'IX. Which languages are supported for text output?',
              content:
              'Currently, our app can translate sign language into English text. We are exploring adding more language options in future releases to accommodate a wider range of users.',
              backgroundColor: Colors.pink[50]!,
            ),
            _buildFAQSection(
              title: "X. What happens if the app can't recognize a sign?",
              content:
              'If the app cannot recognize a sign, it will display a "Sign not recognized" message on the screen. You can try redoing the gesture, ensuring that your hand is within the camera’s view and that the lighting conditions are optimal.',
              backgroundColor: const Color(0xFFD6E3F8),
            ),
            _buildFAQSection(
              title: 'XI. How can I contribute to improving the app?',
              content:
              'We welcome community contributions! You can help by providing feedback on translations, suggesting improvements or reporting any issues you encounter. You can also participate in testing to help us improve future versions of the app.',
              backgroundColor: Colors.pink[50]!,
            ),
            _buildFAQSection(
              title: 'XII. Is my data private and secure?',
              content:
              'We take privacy seriously. By default, translations are processed on your device, and no personal data is collected unless explicitly shared with us for support purposes. We adhere to strict data protection standards to ensure your information remains secure.',
              backgroundColor: const Color(0xFFD6E3F8),
            ),
            _buildFAQSection(
              title: 'XIII. How do I contact support?',
              content:
              'Feel free to reach out to us if you have any questions, suggestions or encounter any issues with the app. You can contact us via email or use the contact to get in touch with our team.',
              backgroundColor: Colors.pink[50]!,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildFAQSection({
    required String title,
    required String content,
    required Color backgroundColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: const Border(
            top: BorderSide(
              color: Colors.black,
              width: 2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
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
            Navigator.pop(context); // Go back to home page
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SignLanguageTranslatorPage(cameras: widget.cameras),
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