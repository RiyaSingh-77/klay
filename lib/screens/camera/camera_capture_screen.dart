import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../services/camera_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_theme.dart';

// CapturedMedia is the plain result object this screen hands back via
// Navigator.pop() — compile-time-checked fields instead of a stringly-
// typed Map.
class CapturedMedia {
  final Uint8List bytes;
  final String fileName;
  final String mediaType; // 'image' | 'video'

  CapturedMedia({
    required this.bytes,
    required this.fileName,
    required this.mediaType,
  });
}

enum _ReviewState { capturing, reviewing }

// captureMode is 'photo' or 'video' — both share the same preview,
// switch-camera control, and post-capture review step; only the
// capture button's behavior differs (single shot vs start/stop toggle).
class CameraCaptureScreen extends StatefulWidget {
  final String captureMode;

  const CameraCaptureScreen({super.key, required this.captureMode});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  final CameraService _cameraService = CameraService();
  final PermissionService _permissionService = PermissionService();

  bool _isInitializing = true;
  bool _initError = false;
  bool _isRecording = false;

  _ReviewState _reviewState = _ReviewState.capturing;
  XFile? _capturedFile;
  Uint8List? _capturedBytes;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final granted = await _permissionService.requestCameraAndMic(context);
    if (!granted) {
      if (mounted) Navigator.pop(context);
      return;
    }
    try {
      await _cameraService.initialize();
      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = true;
        });
      }
    }
  }

  Future<void> _onCapturePressed() async {
    if (widget.captureMode == 'photo') {
      await _takePhoto();
    } else if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _takePhoto() async {
    try {
      final file = await _cameraService.takePhoto();
      final bytes = await file.readAsBytes();
      setState(() {
        _capturedFile = file;
        _capturedBytes = bytes;
        _reviewState = _ReviewState.reviewing;
      });
    } catch (e) {
      _showError('Could not take photo: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      await _cameraService.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      _showError('Could not start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final file = await _cameraService.stopVideoRecording();
      final bytes = await file.readAsBytes();
      setState(() {
        _isRecording = false;
        _capturedFile = file;
        _capturedBytes = bytes;
        _reviewState = _ReviewState.reviewing;
      });
    } catch (e) {
      _showError('Could not stop recording: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _cameraService.switchCamera();
      setState(() {});
    } catch (e) {
      _showError('Could not switch camera: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _retake() {
    setState(() {
      _capturedFile = null;
      _capturedBytes = null;
      _reviewState = _ReviewState.capturing;
    });
  }

  void _useMedia() {
    if (_capturedBytes == null || _capturedFile == null) return;
    Navigator.pop(
      context,
      CapturedMedia(
        bytes: _capturedBytes!,
        fileName: _capturedFile!.name,
        mediaType: widget.captureMode == 'photo' ? 'image' : 'video',
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_initError) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Could not access the camera on this device.',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_reviewState == _ReviewState.reviewing && _capturedBytes != null) {
      return _buildReviewScreen();
    }

    return _buildCaptureScreen();
  }

  Widget _buildCaptureScreen() {
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleIconButton(icon: Icons.close, onTap: () => Navigator.pop(context)),
                  _CircleIconButton(icon: Icons.cameraswitch, onTap: _switchCamera),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_isRecording)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Recording...', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                GestureDetector(
                  onTap: _onCapturePressed,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _isRecording ? AppTheme.error : Colors.transparent,
                    ),
                    child: (widget.captureMode == 'video' && _isRecording)
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Icon(Icons.stop, color: Colors.white),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewScreen() {
    final isVideo = widget.captureMode == 'video';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isVideo
                  // Inline playback of the just-recorded clip is
                  // deliberately skipped here — same simplification as
                  // the gallery-picked video preview in
                  // CreatePostScreen. This review step just confirms
                  // "captured successfully" before upload.
                  ? const Center(child: Icon(Icons.videocam, color: Colors.white, size: 64))
                  : Center(
                      child: _capturedBytes != null
                          ? Image.memory(_capturedBytes!, fit: BoxFit.contain)
                          : const SizedBox(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _retake,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                      child: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _useMedia,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Use This'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}