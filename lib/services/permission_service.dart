import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// PermissionService is the ONLY file that imports permission_handler.
//
// IMPORTANT: permission_handler is a MOBILE/DESKTOP plugin — on Flutter
// Web, browsers handle camera/photo/file access through their own
// native dialogs at the moment image_picker/file_picker/camera actually
// runs, not through a separate permission_handler request beforehand.
// Calling Permission.x.request() on web either silently fails or
// returns denied, which is exactly why the gallery/audio buttons looked
// like they did nothing — the permission step was blocking before the
// picker ever got a chance to open. Every method below short-circuits
// to `true` on web for that reason, letting the browser's own picker UI
// handle access entirely on its own.
class PermissionService {
  Future<bool> requestCameraAndMic(BuildContext context) async {
    if (kIsWeb) return true;

    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isGranted && micStatus.isGranted) {
      return true;
    }

    if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(
          context,
          'Camera & Microphone Access Needed',
          'Klay needs camera and microphone access to record video and take photos. '
              'Please enable them in Settings.',
        );
      }
      return false;
    }

    if (context.mounted) {
      _showSnackBar(context, 'Camera and microphone permission denied.');
    }
    return false;
  }

  Future<bool> requestGalleryAccess(BuildContext context) async {
    if (kIsWeb) return true;

    final status = await Permission.photos.request();

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(
          context,
          'Photo Library Access Needed',
          'Klay needs access to your photos to pick images and videos. '
              'Please enable it in Settings.',
        );
      }
      return false;
    }

    if (context.mounted) {
      _showSnackBar(context, 'Photo library permission denied.');
    }
    return false;
  }

  Future<bool> requestStorageAccess(BuildContext context) async {
    if (kIsWeb) return true;

    final status = await Permission.storage.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(
          context,
          'Storage Access Needed',
          'Klay needs storage access to pick audio files. '
              'Please enable it in Settings.',
        );
      }
      return false;
    }

    if (context.mounted) {
      _showSnackBar(context, 'Storage permission denied.');
    }
    return false;
  }

  Future<void> _showSettingsDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}