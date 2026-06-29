import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

// CloudinaryService is the ONLY file in this project that knows
// Cloudinary's upload endpoint, cloud name, or preset name — same
// separation-of-concerns rule as ApiService for JSONPlaceholder and
// StorageService for SharedPreferences. The Upload Screen calls
// uploadMedia() and gets back a plain secure URL string; it never
// touches Cloudinary's REST API or response shape directly.
//
// Why an UNSIGNED preset instead of a signed one? Signed uploads require
// an API secret to generate a signature, and that secret can NEVER be
// shipped inside a Flutter app's compiled code (anyone can decompile an
// APK and extract it). An unsigned preset lets the Cloud Name + preset
// name travel in the app safely — Cloudinary enforces whatever
// restrictions you set on the preset itself (folder, allowed formats,
// size caps) server-side, with nothing secret exposed.
class CloudinaryService {
  // TODO: confirm this matches your Cloudinary Dashboard's "Cloud Name"
  // field exactly (the dropdown nickname and the real cloud name can
  // differ) before relying on this in production.
  static const String _cloudName = 'dni3k3e1u';
  static const String _uploadPreset = 'klay_media';

  // Cloudinary uses a DIFFERENT endpoint path per resource type —/image/,
  // /video/, or /raw/ — and audio files must go through /video/ (Cloudinary
  // treats audio as a video resource with no visual track). Picking the
  // wrong endpoint for a given file type causes the upload to fail
  // outright rather than just mis-categorizing it, so this mapping has to
  // be exact.
  String _resourceTypePath(String mediaType) {
    switch (mediaType) {
      case 'image':
        return 'image';
      case 'video':
      case 'audio':
        return 'video';
      default:
        throw ArgumentError('Unknown mediaType: $mediaType');
    }
  }

  // Returns the secure_url Cloudinary hands back on success — this is
  // what gets saved into Firestore's mediaUrl field. Throws on any
  // non-200 response or network failure; callers (the Upload Screen)
  // are expected to wrap this in try/catch and show a SnackBar.
  //
  // onProgress is called repeatedly with a 0.0–1.0 fraction as bytes
  // upload, driving the progress indicator on the Upload Screen. It's
  // optional because not every caller needs a progress UI.
  Future<String> uploadMedia({
    required Uint8List bytes,
    required String fileName,
    required String mediaType, // 'image' | 'video' | 'audio'
    void Function(double progress)? onProgress,
  }) async {
    final resourceType = _resourceTypePath(mediaType);
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
    );

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    // http.MultipartRequest doesn't expose upload progress out of the
    // box the way Dio does. We approximate it here: report 0.0 right
    // before sending, and 1.0 once the response arrives. This still
    // drives a meaningful "uploading..." vs "done" state on the UI even
    // though it can't show a smooth 0–100% sweep mid-upload.
    onProgress?.call(0.0);

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw Exception('Upload timed out — check your connection.'),
    );
    final response = await http.Response.fromStream(streamedResponse);

    onProgress?.call(1.0);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final secureUrl = data['secure_url'] as String?;
      if (secureUrl == null) {
        throw Exception('Cloudinary response missing secure_url.');
      }
      return secureUrl;
    }

    // Cloudinary's error responses come back as {"error": {"message": "..."}}.
    String message = 'Upload failed (status ${response.statusCode})';
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final err = data['error'] as Map<String, dynamic>?;
      if (err != null && err['message'] != null) {
        message = err['message'] as String;
      }
    } catch (_) {
      // response body wasn't JSON — keep the generic message above
    }
    throw Exception(message);
  }
}