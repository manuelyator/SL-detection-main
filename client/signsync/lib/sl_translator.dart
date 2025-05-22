import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

// Class to hold a translated word and its associated timer for display management.
class TimedWord {
  final String word;
  final Timer timer;

  TimedWord({required this.word, required this.timer});
}

// StatefulWidget that provides sign language translation
// through a camera feed. It initializes the camera, processes image
// frames, sends them to a backend API for translation, and displays
// the translated words in a stream.
class SignLanguageTranslatorPage extends StatefulWidget {
  // The list of available cameras on the device.
  final List<CameraDescription> cameras;

  // Creates a SignLanguageTranslatorPage.
  const SignLanguageTranslatorPage({super.key, required this.cameras});

  @override
  State<SignLanguageTranslatorPage> createState() =>
      _SignLanguageTranslatorPageState();
}

// This class manages the camera lifecycle, image streaming,
// communication with the translation API, and UI updates.
class _SignLanguageTranslatorPageState extends State<SignLanguageTranslatorPage>
    with WidgetsBindingObserver {
  // Controller for managing the camera.
  late CameraController _cameraController;

  // The index of the currently active camera.
  int _currentCameraIndex = 0;

  // The message displayed to the user about the current status.
  String _currentStatusMessage = "Press record to start translating";

  // Flag indicating if the camera has been successfully initialized.
  bool _isCameraInitialized = false;

  // Flag indicating if the translation stream is paused.
  bool _isPaused = false;

  // Flag indicating if recording (image streaming) is active.
  bool _isRecording = false;

  // Flag indicating if the camera flash is on.
  bool _isFlashOn = false;

  // Timer used to clear temporary status messages.
  Timer? _clearStatusMessageTimer;

  // A list of [TimedWord] objects representing the live stream of translated words.
  List<TimedWord> _translatedWordStream = [];

  // The maximum number of words to display in the translated word stream.
  final int _maxStreamWords = 5;

  // The duration for which each translated word remains visible before fading.
  final Duration _wordDisplayDuration = const Duration(seconds: 20);

  // Flag to prevent multiple image processing operations from running concurrently.
  bool _isProcessingFrame = false;

  @override
  void initState() {
    super.initState();
    // Widget as an observer for app lifecycle changes.
    WidgetsBinding.instance.addObserver(this);
    // Initialize the camera with the first available camera.
    _initializeCamera(widget.cameras[_currentCameraIndex]);
  }

  // Initializes the camera with the given [cameraDescription].
  // Sets up the camera controller, configures resolution, disables audio,
  // and sets the image format. Handles potential camera access errors.
  Future<void> _initializeCamera(CameraDescription cameraDescription) async {
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } on CameraException catch (e) {
      if (e.code == 'CameraAccessDenied') {
        _showCameraPermissionDeniedDialog();
      } else {
        _showTemporaryMessage(
          'Camera error: ${e.description ?? 'Unknown error'}',
        );
        debugPrint('Camera initialization error: ${e.code} - ${e.description}');
      }
    } catch (e) {
      _showTemporaryMessage('Failed to initialize camera: $e');
      debugPrint('Unexpected camera initialization error: $e');
    }
  }

  // Displays an [AlertDialog] informing the user about camera permission denial.
  void _showCameraPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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

  // Toggles the camera's image stream on or off.
  // When `start` is true, the camera begins streaming images, which are then
  // processed and sent for translation.
  void _toggleImageStream(bool start) {
    if (start) {
      if (!_cameraController.value.isStreamingImages) {
        _cameraController.startImageStream((CameraImage image) async {
          if (!_isProcessingFrame && _isRecording && !_isPaused) {
            _isProcessingFrame = true;

            try {
              // Convert CameraImage to JPEG Base64 on a separate isolate to prevent UI freezes.
              final String? base64Image = await compute(
                _convertImageToJPEGBase64,
                image,
              );

              if (base64Image != null) {
                await _sendImageForTranslation(base64Image);
              }
            } catch (e) {
              debugPrint('Error converting or sending image: $e');
              _handleTranslationError(
                'Image processing error: ${e.toString()}',
              );
            } finally {
              _isProcessingFrame = false;
            }
          }
        });
        setState(() {
          _currentStatusMessage = "Recording started...";
        });
      }
    } else {
      if (_cameraController.value.isStreamingImages) {
        _cameraController.stopImageStream();
      }
    }
  }

  // Converts a [CameraImage] to a Base64 encoded JPEG string.
  // This function runs on a separate isolate using `compute` to avoid blocking the UI.
  static Future<String?> _convertImageToJPEGBase64(CameraImage image) async {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        final img.Image? convertedImage = _convertYUV420toImage(image);
        if (convertedImage != null) {
          final List<int> jpgBytes = img.encodeJpg(convertedImage);
          return base64Encode(Uint8List.fromList(jpgBytes));
        }
      } else {
        debugPrint('Unsupported image format: ${image.format.group}');
      }
      return null;
    } catch (e) {
      debugPrint('Error converting CameraImage to JPEG Base64: $e');
      return null;
    }
  }

  // Converts a YUV420 [CameraImage] to an [img.Image] (RGB format).
  // This is necessary for image processing libraries that don't directly
  // support YUV420, such as the `image` package used for JPEG encoding.
  static img.Image? _convertYUV420toImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final Uint8List yBuffer = cameraImage.planes[0].bytes;
    final Uint8List uBuffer = cameraImage.planes[1].bytes;
    final Uint8List vBuffer = cameraImage.planes[2].bytes;

    final int yRowStride = cameraImage.planes[0].bytesPerRow;
    final int uRowStride = cameraImage.planes[1].bytesPerRow;
    final int vRowStride = cameraImage.planes[2].bytesPerRow;

    final int uPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;
    final int vPixelStride = cameraImage.planes[2].bytesPerPixel ?? 1;

    final img.Image image = img.Image(width: width, height: height);

    // YUV to RGB conversion logic
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int Y = yBuffer[y * yRowStride + x];

        final int uvX = x ~/ 2;
        final int uvY = y ~/ 2;

        final int U = uBuffer[uvY * uRowStride + uvX * uPixelStride];
        final int V = vBuffer[uvY * vRowStride + uvX * vPixelStride];

        final int R = (Y + 1.402 * (V - 128)).round().clamp(0, 255);
        final int G = (Y - 0.344136 * (U - 128) - 0.714136 * (V - 128))
            .round()
            .clamp(0, 255);
        final int B = (Y + 1.772 * (U - 128)).round().clamp(0, 255);

        image.setPixelRgb(x, y, R, G, B);
      }
    }
    return image;
  }

  // Sends the Base64 encoded image to the translation API.
  // Updates the [_translatedWordStream] with new translations and manages
  // their display duration using [TimedWord] objects and timers.
  Future<void> _sendImageForTranslation(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.3:5000/api/translate'), // API endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final String newTranslation = data['translated_text'] ?? '';

        if (newTranslation.isNotEmpty) {
          setState(() {
            // Create a timer for the newly translated word to disappear after _wordDisplayDuration.
            final Timer timer = Timer(_wordDisplayDuration, () {
              if (mounted) {
                setState(() {
                  // Remove the word from the stream when its timer finishes.
                  _translatedWordStream.removeWhere(
                    (tw) => tw.word == newTranslation,
                  );
                });
              }
            });
            _translatedWordStream.add(
              TimedWord(word: newTranslation, timer: timer),
            );

            // If the stream exceeds the maximum number of words, remove the oldest one
            // and cancel its associated timer to prevent memory leaks.
            if (_translatedWordStream.length > _maxStreamWords) {
              final oldestWord = _translatedWordStream.removeAt(0);
              oldestWord.timer.cancel();
            }
          });
        }
        _clearStatusMessageTimer?.cancel();
        _currentStatusMessage =
            _isRecording ? "Translating..." : "Recording stopped.";
      } else {
        _handleTranslationError(data['message'] ?? 'Translation failed');
      }
    } catch (e) {
      _handleTranslationError(e.toString());
    }
  }

  // Handles and displays translation errors to the user.
  void _handleTranslationError(String error) {
    _showTemporaryMessage('Error: $error');
  }

  // Displays a temporary message in the status area for a given [duration].
  // The message will automatically revert to the previous status after the duration.
  void _showTemporaryMessage(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _clearStatusMessageTimer?.cancel();
    setState(() {
      _currentStatusMessage = message;
    });
    _clearStatusMessageTimer = Timer(duration, () {
      if (mounted) {
        if (_isRecording && !_isPaused) {
          setState(() {
            _currentStatusMessage = "Translating...";
          });
        } else if (!_isRecording) {
          setState(() {
            _currentStatusMessage = "Press record to start translating";
          });
        }
      }
    });
  }

  @override
  void dispose() {
    // Remove the lifecycle observer.
    WidgetsBinding.instance.removeObserver(this);
    // Cancel any active status message timer.
    _clearStatusMessageTimer?.cancel();
    // Stop the camera image stream.
    _toggleImageStream(false);
    // Dispose of the camera controller to release resources.
    _cameraController.dispose();

    // Cancel all active word timers to prevent memory leaks.
    for (var timedWord in _translatedWordStream) {
      timedWord.timer.cancel();
    }
    super.dispose();
  }

  // Toggles the recording state (start/stop image streaming for translation).
  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        // Clear any existing translated words and cancel their timers when starting a new recording session.
        for (var timedWord in _translatedWordStream) {
          timedWord.timer.cancel();
        }
        _translatedWordStream.clear();
        _currentStatusMessage = "Recording started...";
        _toggleImageStream(true);
      } else {
        _toggleImageStream(false);
        _currentStatusMessage =
            "Recording stopped. Press record to start again";
        _isPaused = false;
        _isFlashOn = false;
        // Ensure flash is off when recording stops.
        if (_cameraController.value.isInitialized) {
          _cameraController.setFlashMode(FlashMode.off).catchError((e) {
            debugPrint('Error turning off flash: $e');
          });
        }
      }
    });
  }

  // Toggles the pause state of the translation stream.
  void _togglePause() {
    if (!_isRecording) return; // Cannot pause if not recording.

    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _currentStatusMessage = "Paused. Stream frozen.";
        _toggleImageStream(false); // Stop image stream when paused.
      } else {
        _currentStatusMessage = "Resumed. Translating...";
        _toggleImageStream(true); // Resume image stream.
      }
    });
  }

  // Switches between available cameras (front/back).
  Future<void> _toggleCamera() async {
    _clearStatusMessageTimer?.cancel();
    _toggleImageStream(false); // Stop stream before switching cameras.

    if (_cameraController.value.isInitialized) {
      try {
        await _cameraController.dispose(); // Dispose current camera.
      } catch (e) {
        debugPrint("Error disposing camera: $e");
      }
    }

    setState(() {
      // Cycle through available cameras.
      _currentCameraIndex = (_currentCameraIndex + 1) % widget.cameras.length;
      _isFlashOn = false;
      _isRecording = false;
      _isPaused = false;
      _currentStatusMessage = "Press record to start translating";
      // Clear words and cancel their timers when switching cameras.
      for (var timedWord in _translatedWordStream) {
        timedWord.timer.cancel();
      }
      _translatedWordStream.clear();
    });

    await _initializeCamera(
      widget.cameras[_currentCameraIndex],
    ); // Initialize new camera.
  }

  // Toggles the camera flash (on/off).
  // Provides feedback if flash is not available (e.g., on front camera).
  Future<void> _toggleFlash() async {
    if (!_cameraController.value.isInitialized) {
      debugPrint("Camera not initialized, cannot toggle flash.");
      _showTemporaryMessage("Camera not ready for flash.");
      return;
    }

    if (_cameraController.description.lensDirection ==
        CameraLensDirection.front) {
      _showTemporaryMessage('Flash not available on front camera.');
      return;
    }

    try {
      // Determine target flash mode.
      FlashMode targetMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraController.setFlashMode(targetMode);

      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } on CameraException catch (e) {
      debugPrint('Flash error: ${e.code} - ${e.description}');
      _showTemporaryMessage('Flash error: ${e.description ?? 'Unknown error'}');
    } catch (e) {
      debugPrint('General flash error: $e');
      _showTemporaryMessage('An unexpected error occurred with flash: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Do not proceed if camera is not initialized.
    if (!_cameraController.value.isInitialized) return;

    // Handle app lifecycle events to manage camera resources.
    if (state == AppLifecycleState.inactive) {
      _toggleImageStream(false);
      _cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera(_cameraController.description);
      if (_isRecording && !_isPaused) {
        _toggleImageStream(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Display a loading indicator until the camera is initialized.
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
          // Displays the live camera feed.
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _cameraController.value.aspectRatio,
              child: CameraPreview(_cameraController),
            ),
          ),

          // Visual overlay to indicate the translation focus area.
          Center(
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2.5),
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),

          // Translated Word Stream Display Area
          // Displays the translated words and the current status message.
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Container for displaying the real-time translated word stream.
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade700.withOpacity(0.8),
                        Colors.deepPurple.shade900.withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        spreadRadius: 3,
                        blurRadius: 7,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    // Concatenates words from the stream for display.
                    _translatedWordStream.map((tw) => tw.word).join(' '),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 15),
                // Container for displaying the current status or error messages.
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _currentStatusMessage.startsWith('Error:')
                            ? Colors.red.shade700.withOpacity(0.8)
                            : Colors.blueGrey.shade700.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _currentStatusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // End Translation Text & History Display Area

          // Row of control buttons at the bottom of the screen.
          Positioned(
            left: 0,
            right: 0,
            bottom: 25,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Button for future text input functionality.
                _buildControlButton(
                  icon: const Text(
                    'Aa',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  onPressed: () {
                    // Implement input mode or other functionality.
                  },
                  backgroundColor: Colors.grey.shade800,
                ),
                // Pause/Play button for the translation stream.
                _buildControlButton(
                  icon: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: _togglePause,
                  backgroundColor:
                      _isPaused ? Colors.blue.shade700 : Colors.grey.shade800,
                ),
                // Central record/stop button.
                _buildControlButton(
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.fiber_manual_record,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: _toggleRecording,
                  backgroundColor:
                      _isRecording ? Colors.red.shade700 : Colors.grey.shade800,
                  isCentral: true,
                ),
                // Button to switch between front and back cameras.
                _buildControlButton(
                  icon: const Icon(
                    Icons.flip_camera_android,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: _toggleCamera,
                  backgroundColor: Colors.grey.shade800,
                ),
                // Button to toggle the camera flash.
                _buildControlButton(
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: _toggleFlash,
                  backgroundColor:
                      _isFlashOn
                          ? Colors.yellow.shade800
                          : Colors.grey.shade800,
                ),
              ],
            ),
          ),

          // Back button for navigation.
          Positioned(
            top: 45,
            left: 15,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),

          // Status indicator at the top center showing "READY", "RECORDING", or "PAUSED".
          Positioned(
            top: 45,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      _isPaused
                          ? Colors.orange.shade700
                          : _isRecording
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _isPaused
                      ? 'PAUSED'
                      : _isRecording
                      ? 'RECORDING'
                      : 'READY',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // A helper widget to build consistently styled control buttons.
  // [icon]: The widget to display inside the button (e.g., [Icon], [Text]).
  // [onPressed]: The callback function when the button is pressed.
  // [backgroundColor]: The background color of the button.
  // [isCentral]: If true, applies specific styling for the central (record) button.
  Widget _buildControlButton({
    required Widget icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    bool isCentral = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        minimumSize: isCentral ? const Size(64, 64) : const Size(56, 56),
        shape:
            isCentral
                ? const CircleBorder()
                : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
        padding:
            isCentral ? const EdgeInsets.all(15) : const EdgeInsets.all(12),
        elevation: 8,
      ),
      child: icon,
    );
  }
}
