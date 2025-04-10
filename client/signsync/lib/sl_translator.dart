import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class SignLanguageTranslatorPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SignLanguageTranslatorPage({super.key, required this.cameras});

  @override
  State<SignLanguageTranslatorPage> createState() =>
      _SignLanguageTranslatorPageState();
}

class _SignLanguageTranslatorPageState extends State<SignLanguageTranslatorPage>
    with WidgetsBindingObserver {
  late CameraController _cameraController;
  int _currentCameraIndex = 0; // For camera flipping
  String _translatedText = "Press record to start translating";
  bool _isCameraInitialized = false;
  bool _isPaused = false;
  bool _isRecording = false;
  bool _isFlashOn = false;
  Timer? _detectionTimer;
  XFile? _lastFrame; // To store the last captured frame when paused

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera(widget.cameras[_currentCameraIndex]);
  }

  Future<void> _initializeCamera(CameraDescription cameraDescription) async {
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (e is CameraException) {
        if (e.code == 'CameraAccessDenied') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Camera Permission'),
              content: const Text(
                'Camera access denied. Please enable camera permissions in app settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _startDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!mounted || !_isCameraInitialized || !_isRecording || _isPaused) {
        return;
      }

      try {
        // Capture a frame (simulating video by taking rapid pictures)
        final frame = await _cameraController.takePicture();
        final bytes = await frame.readAsBytes();

        // Store the last frame for pause
        _lastFrame = frame;

        // Send frame to API for translation
        final response = await http.post(
          Uri.parse('http://192.168.1.3:5000/api/translate_sign'),
          headers: {'Content-Type': 'multipart/form-data'},
          body: {
            'image': base64Encode(bytes),
          },
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['status'] == 'success') {
          setState(() {
            _translatedText = data['translated_text'] ?? 'No translation available';
          });
        } else {
          setState(() {
            _translatedText = 'Error: ${data['message'] ?? 'Translation failed'}';
          });
        }
      } catch (e) {
        setState(() {
          _translatedText = 'Error: $e';
        });
      }
    });
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _translatedText = "Recording started...";
        _startDetection(); // Start capturing and translating
      } else {
        _detectionTimer?.cancel();
        _translatedText = "Recording stopped. Press record to start again";
        _isPaused = false; // Reset pause state
        _lastFrame = null; // Clear last frame
      }
    });
  }

  void _togglePause() {
    if (!_isRecording) return; // Only pause if recording

    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _translatedText = "Paused: $_translatedText"; // Freeze current text
      } else {
        _translatedText = _translatedText.replaceFirst("Paused: ", ""); // Resume text
        _startDetection(); // Resume detection
      }
    });
  }

  void _toggleCamera() {
    setState(() {
      _currentCameraIndex = (_currentCameraIndex + 1) % widget.cameras.length;
      _isFlashOn = false;
      _isRecording = false;
      _isPaused = false;
      _translatedText = "Press record to start translating";
    });
    _detectionTimer?.cancel();
    _cameraController.dispose();
    _initializeCamera(widget.cameras[_currentCameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (!_cameraController.value.isInitialized) return;

    try {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      await _cameraController.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      setState(() {
        _translatedText = 'Flash error: $e';
        _isFlashOn = !_isFlashOn;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _detectionTimer?.cancel();
      _cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera(_cameraController.description);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectionTimer?.cancel();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          CameraPreview(_cameraController),

          // Alignment guide overlay
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Translated text overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.black.withOpacity(0.7),
              child: Text(
                _translatedText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Controls row
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Text mode button (placeholder)
                _buildControlButton(
                  icon: const Text('Aa', style: TextStyle(fontSize: 18)),
                  onPressed: () {},
                ),

                // Microphone button (placeholder)
                _buildControlButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () {},
                ),

                // Pause/Resume button
                _buildControlButton(
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  onPressed: _togglePause,
                  color: _isPaused ? Colors.blue : Colors.grey[800],
                ),

                // Record button
                _buildControlButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
                  onPressed: _toggleRecording,
                  color: _isRecording ? Colors.red : Colors.grey[800],
                ),

                // Flip camera button
                _buildControlButton(
                  icon: const Icon(Icons.flip_camera_android),
                  onPressed: _toggleCamera,
                ),

                // Flashlight button
                _buildControlButton(
                  icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
                  onPressed: _toggleFlash,
                  color: _isFlashOn ? Colors.yellow[700] : Colors.grey[800],
                ),
              ],
            ),
          ),

          // Back button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Status indicator
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isPaused
                      ? Colors.grey
                      : _isRecording
                      ? Colors.red
                      : Colors.green,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _isPaused
                      ? 'Paused'
                      : _isRecording
                      ? 'Recording'
                      : 'Ready',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required Widget icon,
    required VoidCallback onPressed,
    Color? color = Colors.grey,
  }) {
    return MaterialButton(
      onPressed: onPressed,
      color: color,
      minWidth: 48,
      height: 48,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: icon,
    );
  }
}