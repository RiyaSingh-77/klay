import 'package:camera/camera.dart';

// CameraService is the ONLY file that owns a CameraController instance.
// camera_capture_screen.dart calls into this rather than managing
// CameraController directly, so the controller's lifecycle (init,
// switch lens, dispose) stays in one place instead of scattered through
// widget lifecycle methods.
class CameraService {
  CameraController? controller;
  List<CameraDescription> _cameras = [];
  int _selectedIndex = 0;

  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw Exception('No camera found on this device.');
    }
    await _initController(_cameras[_selectedIndex]);
  }

  Future<void> _initController(CameraDescription description) async {
    // enableAudio: true is required even for photo mode — without it,
    // switching to video mode later on the SAME controller instance
    // would record silent video. Initializing fresh per mode would be
    // an alternative, but sharing one controller keeps switching
    // between photo/video on the same screen instant rather than
    // re-triggering a camera permission/hardware handshake.
    controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: true,
    );
    await controller!.initialize();
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return; // nothing to switch to
    _selectedIndex = (_selectedIndex + 1) % _cameras.length;
    await controller?.dispose();
    await _initController(_cameras[_selectedIndex]);
  }

  Future<XFile> takePhoto() async {
    if (controller == null || !controller!.value.isInitialized) {
      throw Exception('Camera not initialized.');
    }
    return controller!.takePicture();
  }

  Future<void> startVideoRecording() async {
    if (controller == null || !controller!.value.isInitialized) {
      throw Exception('Camera not initialized.');
    }
    await controller!.startVideoRecording();
  }

  Future<XFile> stopVideoRecording() async {
    if (controller == null) {
      throw Exception('Camera not initialized.');
    }
    return controller!.stopVideoRecording();
  }

  void dispose() {
    controller?.dispose();
  }
}